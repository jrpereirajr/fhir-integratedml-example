Class PackageSample.PopulateHeartFailure Extends PackageSample.PopulateAbstract
{

Method GetNoShowDataset() As %SQL.IResultSet
{
    Set sql = ##class(gen.SQLBuilder).%New().Select(
        "*"
    ).From(
        "Data.HeartFailure"
    ).Top(
        ..RecordsCount
    ).GetSQL()
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    If ((rs.%SQLCODE '= 0) && (rs.%SQLCODE '= 100)) {
        Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
    }
    Return rs
}

Method OnProcessRecord()
{
    Do ..AddPatient(..FHIRTemplateBasePath_"/patient.json")

    Do ..AddObservation(
        ..FHIRTemplateBasePath_"/observation-creatine-phosphokinase.json", 
        {"valueQuantity": (..CurrentRecord."creatinine_phosphokinase")})

    Do ..AddObservation(
        ..FHIRTemplateBasePath_"/observation-ejection-fraction.json", 
        {"valueQuantity": (..CurrentRecord."ejection_fraction")})

    Do ..AddObservation(
        ..FHIRTemplateBasePath_"/observation-platelets.json", 
        {"valueQuantity": (..CurrentRecord."platelets")})

    Do ..AddObservation(
        ..FHIRTemplateBasePath_"/observation-serum-creatine.json", 
        {"valueQuantity": (..CurrentRecord."serum_creatinine")})

    Do ..AddObservation(
        ..FHIRTemplateBasePath_"/observation-serum-sodium.json", 
        {"valueQuantity": (..CurrentRecord."serum_sodium")})

    If (..CurrentRecord."high_blood_pressure") {
        Do ..AddObservation(..FHIRTemplateBasePath_"/observation-high-blood-pressure.json")
    }
    
    If (..CurrentRecord.anaemia) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-anaemia.json")
    }
    
    If (..CurrentRecord.diabetes) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-diabetes.json")
    }
    
    If (..CurrentRecord.smoking) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-smoker.json")
    }

    Set encounterEntry = ..AddEncounter(..FHIRTemplateBasePath_"/encounter.json")
    Set encounterEntry.resource.period.start = $ZDate(##class(Data.HeartFailure).#BASEDATE - ..CurrentRecord."follow_up_time", 3)
    Set encounterEntry.resource.period.end = encounterEntry.resource.period.start
}

Method AddPatient(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set patient = ..CreateResource(pFileTemplate)
    Do patient.%Get("identifier").%Get(0).%Set("value", patient.id)
    Do patient.%Get("identifier").%Get(1).%Set("value", patient.id)

    Set patient.gender = $Case($ZConvert(..CurrentRecord.sex, "U"), 0:"male", 1:"female")
    Set patient.birthDate = $ZDate(##class(Data.HeartFailure).#BASEDATE - (..CurrentRecord.age * 365), 3)
    If (..CurrentRecord."DEATH_EVENT") {
        Set timestamp = $LFS($ZDT($ZTS,3), " ")
        Set patient.deceasedDateTime = $$$FormatText("%1T%2Z", $LG(timestamp, 1), $LG(timestamp, 2))
    }

    Set ..PatientEntry = ..AddToTransaction(patient)
    Return ..PatientEntry
}

Method AddCondition(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set condition = ..CreateResource(pFileTemplate)
    Do condition.%Get("subject").%Set("reference", ..PatientEntry.resource.id)
    Set conditionEntry = ..AddToTransaction(condition)
    Return conditionEntry
}

Method AddObservation(pFileTemplate As %String, valueObject As %DynamicObject = "") As %DynamicAbstractObject
{
    Set observation = ..CreateResource(pFileTemplate)
    Do observation.%Get("subject").%Set("reference", ..PatientEntry.resource.id)
    If ($IsObject(valueObject) && valueObject.%IsDefined("valueQuantity")) {
        Do observation.%Get("valueQuantity").%Set("value", valueObject.%Get("valueQuantity"))
    }
    Set observationEntry = ..AddToTransaction(observation)
    Return observationEntry
}

Method AddEncounter(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set encounter = ..CreateResource(pFileTemplate)
    Do encounter.%Get("subject").%Set("reference", ..PatientEntry.resource.id)
    Set encounterEntry = ..AddToTransaction(encounter)
    Return encounterEntry
}

}
