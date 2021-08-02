Class PackageSample.Utils
{

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

ClassMethod ExecuteSQLArray(ByRef pSQLArray)
{
    Set idx = $O(pSQLArray(""))
    While idx '= "" {
        Kill %objlasterror
        Set start = $ZHorolog

        Write "SQL> "_pSQLArray(idx), !
        Set rs = ##class(%SQL.Statement).%ExecDirect(, pSQLArray(idx))
        Do rs.%Display()
        
        If (rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100) {
            If (rs.%SQLCODE '= -181) { // ignores Model or Trained Model not found error
                Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
            }
        }
        If ($Get(%objlasterror)) {
            Throw ##class(%Exception.StatusException).CreateFromStatus(%objlasterror)
        }

        Write !,"Time elapsed: "_($ZHorolog - start)_" sec",!
        Write "--------",!

        Set idx = $O(pSQLArray(idx))
    }
}

ClassMethod TryExecuteSQLArray(ByRef pSQLArray, pMaxAttempts As %Integer = 10)
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
    Set sql = ""
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTrainingIDs AS SELECT Id FROM PackageSample.NoShowMLRow WHERE ID IN (SELECT TOP 1500 idx FROM community.randrange(1, 2001) ORDER BY randValue)"
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTraining AS SELECT * FROM PackageSample.NoShowMLRow WHERE Id IN (SELECT Id FROM PackageSample.NoShowMLRowTrainingIDs)"
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTest AS SELECT * FROM PackageSample.NoShowMLRow WHERE Id NOT IN (SELECT Id FROM PackageSample.NoShowMLRowTrainingIDs)"
    Set sql($I(sql)) = "DROP MODEL NoShowModel"
    Set sql($I(sql)) = "CREATE MODEL NoShowModel PREDICTING (Noshow) FROM PackageSample.NoShowMLRowTraining USING {""seed"": 6}"
    Set sql($I(sql)) = "TRAIN MODEL NoShowModel"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS"
    Set sql($I(sql)) = "SELECT TOP 10 PREDICT(NoShowModel) AS PredictedNoshow, Noshow AS ActualNoshow FROM PackageSample.NoShowMLRowTest"
    Set sql($I(sql)) = "VALIDATE MODEL NoShowModel FROM PackageSample.NoShowMLRowTest"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS"
    Do ..TryExecuteSQLArray(.sql)
}

ClassMethod TrainHeartFailureModel()
{
    Set sql = ""
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.HeartFailureMLRowTrainingIDs AS SELECT Id FROM PackageSample.HeartFailureMLRow WHERE ID IN (SELECT TOP 240 idx FROM community.randrange(1, 300) ORDER BY randValue)"
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.HeartFailureMLRowTraining AS SELECT * FROM PackageSample.HeartFailureMLRow WHERE Id IN (SELECT Id FROM PackageSample.HeartFailureMLRowTrainingIDs)"
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.HeartFailureMLRowTest AS SELECT * FROM PackageSample.HeartFailureMLRow WHERE Id NOT IN (SELECT Id FROM PackageSample.HeartFailureMLRowTrainingIDs)"
    Set sql($I(sql)) = "DROP MODEL HeartFailureModel"
    Set sql($I(sql)) = "CREATE MODEL HeartFailureModel PREDICTING (DEATHEVENT) FROM PackageSample.HeartFailureMLRowTraining USING {""seed"": 6}"
    Set sql($I(sql)) = "TRAIN MODEL HeartFailureModel"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS"
    Set sql($I(sql)) = "SELECT TOP 10 PREDICT(HeartFailureModel) AS PredictedHeartFailure, DEATHEVENT AS ActualHeartFailure FROM (SELECT * FROM PackageSample.HeartFailureMLRowTest) WHERE %VID IN (SELECT TOP 10 idx FROM community.randrange(1, 60) ORDER BY randValue)"
    Set sql($I(sql)) = "VALIDATE MODEL HeartFailureModel FROM PackageSample.HeartFailureMLRowTest"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS"
    Do ..TryExecuteSQLArray(.sql)
}

}
