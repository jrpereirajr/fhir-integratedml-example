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
    Set prediction = ""

    Set subQuery = ##class(gen.SQLBuilder).%New(
        ).Select("*").From("PackageSample.NoShowMLRow").Where("Id = ?")
    Set sql = ##class(gen.SQLBuilder).%New().Select($LTS($LB(
        "PREDICT(NoShowModel) AS predictedClass",
        "PROBABILITY(NoShowModel FOR 0) AS probForClass0",
        "PROBABILITY(NoShowModel FOR 1) AS ProbForClass1"
    ))).From(
        "("_subQuery.GetSQL()_")"
    )

    $$$TOE(sc, pNoShowRow.%Save())
    Set pNoShowRowId = pNoShowRow.%Id()
    Set rs = ##class(%SQL.Statement).%ExecDirect(, sql.GetSQL(), pNoShowRowId)
    If (rs.%Next()) {
        Set prediction = ##class(PackageSample.Utils).SerializeRow(rs)
    }
    $$$TOE(sc, pNoShowRow.%DeleteId(pNoShowRowId))
    
    Return prediction
}

}
