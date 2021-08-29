Class PackageSample.FHIRHeartFailureETL Extends %RegisteredObject
{

Property RecordsCount As %Integer [ InitialExpression = 10 ];

Method Execute(pRecordsCount As %Integer = "") As %Status
{
    Set sc = $$$OK
    
    Set ..RecordsCount = pRecordsCount
    Set rs = ..GetHeartFailureDataset()
    While rs.%Next() {
        Set patientId = rs.%Get("ID1")
        Set source = ##class(HSFHIR.X0001.S.Patient).%OpenId(patientId)
        $$$TOE(sc, ##class(PackageSample.HeartFailureDTL).Transform(source, .target))
        $$$TOE(sc, target.%Save())
    }
    
    Return sc
}

Method GetHeartFailureDataset() As %SQL.IResultSet
{
    Set sql = "SELECT count(*) + 1 startId FROM PackageSample.NoShowMLRow"
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    If ((rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100)) {
        Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
    }
    Do rs.%Next()
    Set startId = rs.startId
    
    Set builder = ##class(gen.SQLBuilder).%New().Select(
        "ID1"
    ).From(
        "HSFHIR_X0001_S.Patient"
    ).Where(
        "Id1 >= ?", startId
    )
    If (..RecordsCount '= "") {
        Do builder.Top(
            ..RecordsCount
        )
    }
    Set sql = builder.GetSQL()
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    If ((rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100)) {
        Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
    }
    Return rs
}

}
