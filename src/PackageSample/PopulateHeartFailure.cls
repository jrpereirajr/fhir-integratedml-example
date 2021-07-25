Class PackageSample.PopulateHeartFailure Extends %RegisteredObject
{

Property FHIRTemplateBasePath As %String [ InitialExpression = "/opt/irisapp/fhirdata/template" ];

Property RecordsCount As %Integer;

Property CurrentRecord As %DynamicAbstractObject [ Private ];

Property Transaction As %DynamicAbstractObject [ Private ];

Property PatientEntry As %DynamicAbstractObject [ Private ];

Property DataLoader As HS.FHIRServer.Tools.DataLoader [ Private ];

Property ResourceTemplate As array Of %DynamicAbstractObject [ Private ];

Method Populate(pRecordsCount As %Integer = "") As %Status
{
    Set sc = $$$OK
    Try {
        Set lockName = "^"_..%ClassName(1)
        Lock +@lockName:1
        Throw:('$Test) ##class(%Exception.General).%New("There is another execution, can't continue...")
        
        Try {
            Set:(pRecordsCount '= "") ..RecordsCount = pRecordsCount
            Set rs = ..GetNoShowDataset()
            While rs.%Next() {
                Set ..CurrentRecord = ##class(PackageSample.Utils).SerializeRow(rs)
                Do ..ProcessRecord()
            }
        } Catch(e) {
            Set sc = e.AsStatus()
        }
        
        Lock -@lockName
    } Catch(e) {
        Set sc = e.AsStatus()
    }
    Return sc
}

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
    Return rs
}

Method ProcessRecord()
{
    Set ..Transaction = {
        "resourceType": "Bundle",
        "id": "bundle-transaction",
        "type": "transaction",
        "entry": []
    }
    
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

    Set stream = ##class(%Stream.GlobalCharacter).%New()
    $$$TOE(sc, stream.Write(..Transaction.%ToJSON()))

    Set:('$IsObject(..DataLoader)) ..DataLoader = ##class(PackageSample.DataLoader).%New("FHIRSERVER","/fhir/r4")
    $$$TOE(sc, ..DataLoader.MySubmitResourceStream(stream, "JSON"))
}

Method GetJSONFromFile(pFile As %String) As %DynamicAbstractObject
{
    Set fileStream = ##class(%FileCharacterStream).%New()
    Set fileStream.Filename = pFile
    Set json = ""
    While 'fileStream.AtEnd {
        Set json = json_fileStream.ReadLine()
    }
    Return ##class(%DynamicAbstractObject).%FromJSON(json)
}

Method AddToTransaction(pResource As %DynamicAbstractObject) As %DynamicAbstractObject
{
    Set resourceFullUrl = "urn:uuid:"_pResource.id
    Set resourceEntry = {
        "fullUrl": (resourceFullUrl),
        "resource": (pResource),
        "request": {
            "method": "POST",
            "url": (pResource.resourceType)
        }
    }
    Do ..Transaction.%Get("entry").%Push(resourceEntry)
    Return resourceEntry
}

Method GetResourceTemplate(pFile As %String) As %DynamicAbstractObject
{
    If ('$IsObject(..ResourceTemplate.GetAt(pFile))) {
        Do ..ResourceTemplate.SetAt(..GetJSONFromFile(pFile), pFile)
    }
    Return ..ResourceTemplate.GetAt(pFile)
}

Method AddPatient(pFile As %String)
{
    Set patient = ..GetJSONFromFile(pFile)
    Set patient.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do patient.%Get("identifier").%Get(0).%Set("value", patient.id)
    Do patient.%Get("identifier").%Get(1).%Set("value", patient.id)

    Set patient.gender = $Case($ZConvert(..CurrentRecord.sex, "U"), 0:"male", 1:"female")
    Set patient.birthDate = $ZDate(##class(Data.HeartFailure).#BASEDATE - (..CurrentRecord.age * 365), 3)
    If (..CurrentRecord."DEATH_EVENT") {
        Set timestamp = $LFS($ZDT($ZTS,3), " ")
        Set patient.deceasedDateTime = $$$FormatText("%1T%2Z", $LG(timestamp, 1), $LG(timestamp, 2))
    }

    Set ..PatientEntry = ..AddToTransaction(patient)
}

Method AddCondition(pFile As %String) As %DynamicAbstractObject
{
    Set condition = ..GetJSONFromFile(pFile)
    Set condition.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do condition.%Get("subject").%Set("reference", ..PatientEntry.fullUrl)
    Set conditionEntry = ..AddToTransaction(condition)
    Return conditionEntry
}

Method AddObservation(pFile As %String, valueObject As %DynamicObject = "") As %DynamicAbstractObject
{
    Set observation = ..GetJSONFromFile(pFile)
    Set observation.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do observation.%Get("subject").%Set("reference", ..PatientEntry.fullUrl)
    If ($IsObject(valueObject) && valueObject.%IsDefined("valueQuantity")) {
        Do observation.%Get("valueQuantity").%Set("value", valueObject.%Get("valueQuantity"))
    }
    Set observationEntry = ..AddToTransaction(observation)
    Return observationEntry
}

Method AddEncounter(pFile As %String) As %DynamicAbstractObject
{
    Set encounter = ..GetJSONFromFile(pFile)
    Set encounter.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do encounter.%Get("subject").%Set("reference", ..PatientEntry.fullUrl)
    Set encounterEntry = ..AddToTransaction(encounter)
    Return encounterEntry
}

}
