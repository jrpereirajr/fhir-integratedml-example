Class PackageSample.FHIRNoShowETL Extends %RegisteredObject
{

Property RecordsCount As %Integer [ InitialExpression = 10 ];

Method Execute(pRecordsCount As %Integer = "") As %Status
{
    Set sc = $$$OK
    
    Set ..RecordsCount = pRecordsCount
    Set rs = ..GetNoShowDataset()
    While rs.%Next() {
        Set patientId = rs.%Get("ID1")
        Set source = ##class(HSFHIR.X0001.S.Patient).%OpenId(patientId)
        $$$TOE(sc, ##class(PackageSample.NoShowDTL).Transform(source, .target))
        $$$TOE(sc, target.%Save())
    }
    
    Return sc
}

Method GetNoShowDataset() As %SQL.IResultSet
{
    Set builder = ##class(gen.SQLBuilder).%New().Select(
        "ID1"
    ).From(
        "HSFHIR_X0001_S.Patient"
    )
    If (..RecordsCount '= "") {
        Do builder.Top(
            ..RecordsCount
        )
    }
    Set sql = builder.GetSQL()
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    Return rs
}

}
