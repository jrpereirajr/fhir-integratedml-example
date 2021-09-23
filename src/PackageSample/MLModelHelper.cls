Class PackageName.MLModelHelper Extends %RegisteredObject
{

Property DatasetLength As %Integer;

Property ModelName As %Integer;

Property TargetColumn As %Integer;

Property FoldsLength As %Integer [ InitialExpression = 5 ];

Method TrainWithCrossValidation() As %Status
{
    Set sc = $$$OK

    Set datasetLen = ..DatasetLength
    Set modelName = ..ModelName
    Set predictingCol = ..TargetColumn
    Set foldsLen = ..FoldsLength

    // split dataset into train, validation and test datasets
    // @see https://en.wikipedia.org/wiki/Training,_validation,_and_test_sets
    Set cvLen = $Number(datasetLen * .9, 0)
    Set testLen = datasetLen - cvLen
    Set trainLen = $Number(cvLen * .75, 0)
    Set validationLen = cvLen - trainLen
    
    Kill sql
    Set sql($I(sql)) = "DROP TABLE PackageSample."_modelName_"MLRowCrossValidation"
    Set sql($I(sql)) = "DROP TABLE PackageSample."_modelName_"MLRowTest"
    Set sql($I(sql)) = 
        "CREATE TABLE PackageSample."_modelName_"MLRowCrossValidation AS "_
        "SELECT * FROM PackageSample."_modelName_"MLRow WHERE Id IN ("_
            "SELECT TOP "_cvLen_" idx "_
            "FROM community.randrange(1, "_(datasetLen + 1)_") "_
            "ORDER BY randValue"_
        ")"
    Set sql($I(sql)) = 
        "CREATE TABLE PackageSample."_modelName_"MLRowTest AS "_
        "SELECT TOP "_testLen_" * FROM PackageSample."_modelName_"MLRow WHERE Id NOT IN ("_
            "SELECT Id FROM PackageSample."_modelName_"MLRowCrossValidation"_
        ")"
    Do ##class(PackageSample.Utils).TryExecuteSQLArray(.sql)
    
    Write "-----------------------------", !
    Write "Cross validation for model: ", modelName, !

    For k = 1:1:foldsLen {
        Write "-----------------------------", !
        Write "Step ", k, !
        Write "-----------------------------", !

        Kill sql

        // create train/test datasets randomly
        Set sql($I(sql)) = "DROP TABLE PackageSample."_modelName_"MLRowTraining"
        Set sql($I(sql)) = "DROP TABLE PackageSample."_modelName_"MLRowValidation"
        Set sql($I(sql)) = 
            "CREATE TABLE PackageSample."_modelName_"MLRowTraining AS "_
            "SELECT * FROM PackageSample."_modelName_"MLRowCrossValidation WHERE Id IN ("_
                "SELECT TOP "_trainLen_" idx "_
                "FROM community.randrange(1, "_(datasetLen + 1)_") "_
                "ORDER BY randValue"_
            ")"
        Set sql($I(sql)) = 
            "CREATE TABLE PackageSample."_modelName_"MLRowValidation AS "_
            "SELECT TOP "_validationLen_" * "_
            "FROM PackageSample."_modelName_"MLRowCrossValidation "_
            "WHERE Id NOT IN ("_
                "SELECT Id FROM PackageSample."_modelName_"MLRowTraining"_
            ")"
        
        Set currentModelName = modelName_"Model_"_k
        
        // create the k-th model
        Set sql($I(sql)) = "DROP MODEL "_currentModelName
        Set sql($I(sql)) = 
            "CREATE MODEL "_currentModelName_" PREDICTING ("_predictingCol_") "_
            #; "WITH (followuptime double, ejectionfraction double, serumcreatinine double) "_ //, age double, serumsodium double) "_
            "FROM PackageSample."_modelName_"MLRowTraining"
        
        // train the k-th model
        Set sql($I(sql)) = 
            "TRAIN MODEL "_currentModelName //_" USING {""seed"": 1}"
        
        // validate the k-th model
        Set sql($I(sql)) = 
            "VALIDATE MODEL "_currentModelName_" FROM PackageSample."_modelName_"MLRowValidation"

        Do ##class(PackageSample.Utils).TryExecuteSQLArray(.sql)
    }

    Kill sql

    // model trainings ordered by score
    Write "Model performance:", !
    Set sql = ..GetSQLBestModel(modelName)
    Do ##class(PackageSample.Utils).ExecuteSQL(sql)
    Write "-------------------", !

    // perfomance averages
    Write "Perfomance average:", !
    Set sql = ..GetSQLPerformanceAverageModel(modelName)
    Do ##class(PackageSample.Utils).ExecuteSQL(sql)
    Write "---------------------------", !

    // check model performance on test dataset
    Write "Perfomance on test dataset:", !
    Set bestModel = ..GetBestModel(modelName)
    Kill sql
    Set sql($I(sql)) = 
        "VALIDATE MODEL "_bestModel_" FROM PackageSample."_modelName_"MLRowTest"
    Set sql($I(sql)) = ..GetSQLPerformanceLastExection(modelName)
    Do ##class(PackageSample.Utils).TryExecuteSQLArray(.sql)
    Write "---------------------------", !

    #; // check model performance on test dataset
    #; Write "Perfomance on test dataset:", !
    #; Set bestModel = ..GetBestModel(modelName_"Norm")
    #; Kill sql
    #; Set sql($I(sql)) = 
    #;     "VALIDATE MODEL "_bestModel_" FROM PackageSample."_modelName_"Norm"_"MLRowTest"
    #; Set sql($I(sql)) = ..GetSQLPerformanceLastExection(modelName_"Norm")
    #; Do ##class(PackageSample.Utils).TryExecuteSQLArray(.sql)
    #; Write "---------------------------", !

    Return sc
}

Method GetSQLBestModel(pModelName As %String) As %String
{
    Set sql = 
        "SELECT "_
            "MODEL_NAME, "_
            "VALIDATION_RUN_NAME, "_
            "SUM(METRIC_VALUE) / 4 score "_
        "FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS "_
        "WHERE MODEL_NAME LIKE '"_pModelName_"Model%' "_
        "GROUP BY VALIDATION_RUN_NAME "_
        "ORDER BY score DESC"
    Return sql
}

Method GetSQLPerformanceAverageModel(pModelName As %String) As %String
{
    Set sql = 
        "SELECT "_
            "MODEL_NAME, "_
            "METRIC_NAME, "_
            "AVG(METRIC_VALUE) avg_score, "_
            "MIN(METRIC_VALUE) min_score, "_
            "MAX(METRIC_VALUE) max_score "_
        "FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS "_
        "WHERE MODEL_NAME LIKE '"_pModelName_"Model%' "_
        "GROUP BY METRIC_NAME"
    Return sql
}

Method GetSQLPerformanceLastExection(pModelName As %String) As %String
{
    Set sql = 
        "SELECT "_
            "MODEL_NAME, "_
            "METRIC_NAME, "_
            "METRIC_VALUE "_
        "FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS "_
        "WHERE MODEL_NAME LIKE '"_pModelName_"Model%' "_
        "GROUP BY METRIC_NAME "_
        "HAVING Id = MAX(Id)"
    Return sql
}

Method GetBestModel(pModelName As %String) As %String
{
    Set sql = ..GetSQLBestModel(pModelName)
    Set rs = ##class(%SQL.Statement).%ExecDirect(, sql)
    If (rs.%Next()) {
        Return rs."MODEL_NAME"
    }
    Return ""
}

}
