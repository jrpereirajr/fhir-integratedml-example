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

ClassMethod TrainNoShowModel()
{
    Set sql = ""
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTraining AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID < 1800"
    Set sql($I(sql)) = "CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTest AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID >= 1800"
    Set sql($I(sql)) = "DROP MODEL NoShowModel"
    Set sql($I(sql)) = "CREATE MODEL NoShowModel PREDICTING (Noshow) FROM PackageSample.NoShowMLRowTraining USING {""seed"": 6}"
    Set sql($I(sql)) = "TRAIN MODEL NoShowModel"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS"
    Set sql($I(sql)) = "SELECT top 10 PREDICT(NoShowModel) AS PredictedNoshow, Noshow AS ActualNoshow FROM PackageSample.NoShowMLRowTest"
    Set sql($I(sql)) = "VALIDATE MODEL NoShowModel FROM PackageSample.NoShowMLRowTest"
    Set sql($I(sql)) = "SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS"
    Set idx = $O(sql(""))
    While idx '= "" {
        Try {
            Do ##class(%SQL.Statement).%ExecDirect(,sql(idx)).%Display()
            Write !
        } Catch(e) {
            zw e
        }
        Set idx = $O(sql(idx))
    }
}

}
