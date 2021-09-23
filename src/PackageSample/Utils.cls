Class PackageSample.Utils
{

Parameter NoShowDatasetLen = 2000;

Parameter HeartFailureDatasetLen = 299;

ClassMethod SerializeRow(pInput As %SQL.IResultSet) As %DynamicObject
{
    Set jsonObj = {}
    Set rsmd = pInput.%GetMetadata()
    Set columns = rsmd.columns
    Set colCount = columns.Count()
    For i=1:1:colCount {
        Set column = columns.GetAt(i)
        Set colName = column.colName
        Set colValue = pInput.%Get(colName)
        Do jsonObj.%Set(colName, colValue)
    }
    Return jsonObj
}

ClassMethod ExecuteSQL(ByRef pSQL As %String)
{
    Kill %objlasterror
    Set start = $ZHorolog

    Write "SQL> "_pSQL, !
    Set rs = ##class(%SQL.Statement).%ExecDirect(, pSQL)
    Do rs.%Display()
    
    Set ignoreSQLCODEList = $LB(
        0, // no error
        100, // no error
        -181, // ignores Model or Trained Model not found error
        -30, // ignores Table or view not found error
        -201 // ignores Table or view name not unique error
    )
    If ('$LF(ignoreSQLCODEList, rs.%SQLCODE)) {
        Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
    }
    If ($Get(%objlasterror)) {
        Throw ##class(%Exception.StatusException).CreateFromStatus(%objlasterror)
    }

    Write !,"Time elapsed: "_($ZHorolog - start)_" sec",!
    Write "--------",!
}

ClassMethod ExecuteSQLArray(ByRef pSQLArray)
{
    Set idx = $O(pSQLArray(""))
    While idx '= "" {
        Do ..ExecuteSQL(pSQLArray(idx))
        Set idx = $O(pSQLArray(idx))
    }
}

ClassMethod TryExecuteSQLArray(ByRef pSQLArray, pMaxAttempts As %Integer = 3)
{
    Set attempts = 0
    While (attempts < pMaxAttempts) {
        Set isQuit = 0
        Try {
            Do ..ExecuteSQLArray(.pSQLArray)
            Set isQuit = 1
        } Catch(e) {
            Write e.AsStatus(), !
        }

        Quit:(isQuit)

        Set attempts = attempts + 1
        Write "Attemptive "_attempts_"/"_pMaxAttempts_" failed...",!
        Write "-------------",!
    }
    If (attempts = pMaxAttempts) {
        Write "Unable to execute SQL statements",!
    }
}

ClassMethod TrainNoShowModel()
{
    Set o = ##class(PackageName.MLModelHelper).%New()
    Set o.DatasetLength = ..#NoShowDatasetLen
    Set o.ModelName = "NoShow"
    Set o.TargetColumn = "Noshow"
    Do o.TrainWithCrossValidation()
}

ClassMethod TrainHeartFailureModel()
{
    Set o = ##class(PackageName.MLModelHelper).%New()
    Set o.DatasetLength = ..#HeartFailureDatasetLen
    #; Set o.ModelName = "HeartFailure"
    Set o.ModelName = "HeartFailureNorm"
    Set o.TargetColumn = "DEATHEVENT"
    Do o.TrainWithCrossValidation()
}

ClassMethod Install() As %Status
{
    Set sc = $$$OK

    Write "Importing training datasets...",!
    Do ##class(community.csvgen).Generate("/opt/irisapp/traindata/appointment-noshows.csv", ",", "Data.AppointmentNoShow","Gender VARCHAR(250),ScheduledDay TIMESTAMP,AppointmentDay TIMESTAMP,Age INTEGER,Neighborhood VARCHAR(250),Scholarship BIT,Hypertension BIT,Diabetes BIT,Alcoholism BIT,Handicap BIT,SMS_received BIT,Noshow BIT")
    Do ##class(community.csvgen).Generate("/opt/irisapp/traindata/heart_failure_clinical_records_dataset.csv", ",", "Data.HeartFailure", "age INTEGER,anaemia INTEGER,creatinine_phosphokinase INTEGER,diabetes INTEGER,ejection_fraction INTEGER,high_blood_pressure INTEGER,platelets DOUBLE,serum_creatinine DOUBLE,serum_sodium INTEGER,sex INTEGER,smoking INTEGER,follow_up_time INTEGER,DEATH_EVENT INTEGER")
    #; Do ##class(community.csvgen).Generate("/irisdev/app/jupyter-samples/heart-failure-norm.csv", ",", "PackageSample.HeartFailureNormMLRow")
    
    Set param = ##class(%ParameterDefinition).%New("Data.HeartFailure:BASEDATE")
    Set param.Default = +$Now()
    Set param.Deprecated = 0
    Set param.Final = 0
    Set param.Internal = 0
    Set param.Type = "%Date"
    Set sc = param.%Save()
    Throw:(sc '= 1) ##class(%Exception.StatusException).CreateFromStatus(sc)

    Do $System.OBJ.Compile("Data.HeartFailure", "ck")
    
    Write "Generating FHIR data based on training datasets...",!
    ZWrite ##class(PackageSample.PopulateNoShow).%New().Populate(..#NoShowDatasetLen)
    ZWrite ##class(PackageSample.PopulateHeartFailure).%New().Populate(..#NoShowDatasetLen)
    
    Write "Apllying DTL transformation on FHIR data to ML datasets generation..."
    ZWrite ##class(PackageSample.FHIRNoShowETL).%New().Execute(..#NoShowDatasetLen)
    ZWrite ##class(PackageSample.FHIRHeartFailureETL).%New().Execute(..#NoShowDatasetLen)
    
    Write "Training models...", !
    Do ##class(PackageSample.Utils).TrainNoShowModel()
    Do ##class(PackageSample.Utils).TrainHeartFailureModel()

    Write "Models: ",!
    Do ..ExecuteSQL("SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS")

    Return sc
}

ClassMethod Reinstall() As %Status
{
    Set sc = $$$OK
    Set sql = ""
    Set sql($I(sql)) = "TRUNCATE TABLE Data.AppointmentNoShow"
    Set sql($I(sql)) = "TRUNCATE TABLE Data.HeartFailure"
    Set sql($I(sql)) = "TRUNCATE TABLE PackageSample.NoShowMLRow"
    Set sql($I(sql)) = "TRUNCATE TABLE PackageSample.HeartFailureMLRow"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Patient"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Appointment"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Slot"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Schedule"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Condition"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Observation"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Communication"
    Set sql($I(sql)) = "TRUNCATE TABLE HSFHIR_X0001_S.Encounter"
    Do ..ExecuteSQLArray(.sql)
    $$$TOE(sc, ..Install())
    Return sc
}

}
