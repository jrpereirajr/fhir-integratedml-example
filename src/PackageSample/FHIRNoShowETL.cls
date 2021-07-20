Class PackageSample.FHIRNoShowETL Extends %RegisteredObject
{

Property RecordsCount As %Integer [ InitialExpression = 10 ];

/// d ##class(PackageSample.FHIRNoShowETL).%New().Execute()
Method Execute(pRecordsCount As %Integer = "") As %Status
{
    Set sc = $$$OK

    #; Set source=##class(HSFHIR.X0001.S.Patient).%OpenId(1000)
    #; $$$TOE(sc, ##class(PackageSample.TestDTL).Transform(source, .target))
    #; zw target

    #; SELECT top 100 * FROM PackageSample.NoShowMLRow
    #; --SELECT count(*) FROM PackageSample.NoShowMLRow
    #; --truncate table PackageSample.NoShowMLRow
    #; --select * from Data.AppointmentNoShow where id in (select top 100 PackageSample.PopulateNoShow_Rand(2000, id) from Data.AppointmentNoShow)
    #; --select top 100 * from Data.AppointmentNoShow

    #; --CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTraining AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID < 1800
    #; --CREATE OR REPLACE VIEW PackageSample.NoShowMLRowTest AS SELECT * FROM PackageSample.NoShowMLRow WHERE ID >= 1800
    #; --select * from PackageSample.NoShowMLRowTest

    #; --DROP MODEL NoShowModel
    #; --CREATE MODEL NoShowModel PREDICTING (Noshow) FROM PackageSample.NoShowMLRowTraining USING {"seed": 6}
    #; --TRAIN MODEL NoShowModel
    #; --SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
    #; --SELECT top 10 PREDICT(NoShowModel) AS PredictedNoshow, Noshow AS ActualNoshow FROM PackageSample.NoShowMLRowTest
    #; --VALIDATE MODEL NoShowModel FROM PackageSample.NoShowMLRowTest
    #; --SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS

    #; --select count(*) from HSFHIR_X0001_S.Patient
    #; --truncate table HSFHIR_X0001_S.Patient
    
    Set ..RecordsCount = pRecordsCount
    Set rs = ..GetNoShowDataset()
    While rs.%Next() {
        Set source = ##class(HSFHIR.X0001.S.Patient).%OpenId(rs.%Get("ID1"))
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
