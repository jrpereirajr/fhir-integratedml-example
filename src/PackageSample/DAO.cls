Class PackageSample.DAO Extends %RegisteredObject
{

Property DataLoader As PackageSample.DataLoader;

Property FHIRServiceType As %String [ InitialExpression = "FHIRSERVER" ];

Property FHIRServiceName As %String [ InitialExpression = "/fhir/r4" ];

Method %OnNew() As %Status
{
    Do ..CreateDataLoader()
    Return $$$OK
}

Method CreateDataLoader()
{
    Set ..DataLoader = ##class(PackageSample.DataLoader).%New(..FHIRServiceType, ..FHIRServiceName)
}

Method SaveFHIRResource(pResource As %Stream.Object) As HS.FHIRServer.API.Data.Response
{
    $$$TOE(sc, ..DataLoader.MySubmitResourceStream(pResource, "JSON", .fhirServerResponse))
    Return fhirServerResponse
}

Method ExecuteNoShowPrediction(pNoShowRow As PackageSample.NoShowMLRow) As %DynamicAbstractObject
{

    Set subQuery = ##class(gen.SQLBuilder).%New(
        ).Select("*").From("PackageSample.NoShowMLRow").Where("Id = ?")
    Set sql = ##class(gen.SQLBuilder).%New().Select($LTS($LB(
        "PREDICT(NoShowModel) AS predictedClass",
        "PROBABILITY(NoShowModel FOR 0) AS probForClass0",
        "PROBABILITY(NoShowModel FOR 1) AS ProbForClass1"
    ))).From(
        "("_subQuery.GetSQL()_")"
    )
    
    Return ..ExecutePredictionQuery(pNoShowRow, sql)
}

Method ExecuteHeartFailurePrediction(pHeartFailureRow As PackageSample.HeartFailureMLRow) As %DynamicAbstractObject
{

    Set subQuery = ##class(gen.SQLBuilder).%New(
        ).Select("*").From("PackageSample.HeartFailureMLRow").Where("Id = ?")
    Set sql = ##class(gen.SQLBuilder).%New().Select($LTS($LB(
        "PREDICT(HeartFailureModel) AS predictedClass",
        "PROBABILITY(HeartFailureModel FOR 0) AS probForClass0",
        "PROBABILITY(HeartFailureModel FOR 1) AS ProbForClass1"
    ))).From(
        "("_subQuery.GetSQL()_")"
    )
    
    Return ..ExecutePredictionQuery(pHeartFailureRow, sql)
}

Method ExecutePredictionQuery(pRecord As %Persistent, pSQLBuilder As gen.SQLBuilder)
{
    Set prediction = ""
    $$$TOE(sc, pRecord.%Save())
    Set pRecordId = pRecord.%Id()
    Set rs = ##class(%SQL.Statement).%ExecDirect(, pSQLBuilder.GetSQL(), pRecordId)
    If ((rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100)) {
        Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
    }
    If (rs.%Next()) {
        Set prediction = ##class(PackageSample.Utils).SerializeRow(rs)
    }
    $$$TOE(sc, pRecord.%DeleteId(pRecordId))
    Return prediction
}

}
