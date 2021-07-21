Class PackageSample.PopulateNoShow Extends %RegisteredObject
{

Property FHIRTemplateBasePath As %String [ InitialExpression = "/opt/irisapp/fhirdata/template" ];

Property RecordsCount As %Integer [ InitialExpression = 10 ];

Property CurrentNowShow As %DynamicAbstractObject [ Private ];

Property Transaction As %DynamicAbstractObject [ Private ];

Property PatientEntry As %DynamicAbstractObject [ Private ];

Property DataLoader As HS.FHIRServer.Tools.DataLoader [ Private ];

/// https://www.hl7.org/fhir/patient-example.json
/// https://www.hl7.org/fhir/appointment-example.json
/// https://www.hl7.org/FHIR/communication-example.json
/// http://hl7.org/fhir/us/mcode/2021May/Condition-us-core-condition-hypertension-jenny-m.json
/// https://github.com/smart-on-fhir/custom-sample-data/blob/master/fhir-resources/diabetes.json
/// iconv -f UTF-8 -t ISO_8859-1 -o /tmp/appointment-noshows2.csv /tmp/appointment-noshows.csv
Method Populate(pRecordsCount As %Integer = "") As %Status
{
    Set sc = $$$OK
    Try {
        Lock +^PopulateNoShow:1
        Throw:('$Test) ##class(%Exception.General).%New("There is another execution, can't continue...")
        
        Try {
            Set:(pRecordsCount '= "") ..RecordsCount = pRecordsCount
            Set rs = ..GetNoShowDataset()
            While rs.%Next() {
                Set ..CurrentNowShow = ##class(PackageSample.Utils).SerializeRow(rs)
                Do ..ProcessNoShow()
            }
        } Catch(e) {
            Set sc = e.AsStatus()
        }
        
        Lock -^PopulateNoShow
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
        "Data.AppointmentNoShow"
    ).Top(
        ..RecordsCount
    ).GetSQL()
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    Return rs
}

ClassMethod Rand(pMax, pVar) As %Integer [ SqlProc ]
{
    Return $Random(pMax) + (pVar*0) + 1
}

Method ProcessNoShow()
{
    Set ..Transaction = {
        "resourceType": "Bundle",
        "id": "bundle-transaction",
        "type": "transaction",
        "entry": []
    }
    
    Do ..AddPatient(..FHIRTemplateBasePath_"/patient.json")
    Do ..AddAppointment(..FHIRTemplateBasePath_"/appointment.json")
    
    If (..CurrentNowShow.Hypertension) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-hypertension.json")
    }
    
    If (..CurrentNowShow.Diabetes) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-diabetes.json")
    }
    
    If (..CurrentNowShow.Alcoholism) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-alcolholims.json")
    }
    
    If (..CurrentNowShow.Handicap) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-disability.json")
    }

    If (..CurrentNowShow."SMS_received") {
        Do ..AddCommunication(..FHIRTemplateBasePath_"/communication.json")
    }

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

Property ResourceTemplate As array Of %DynamicAbstractObject;

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

    Set patient.gender = $Case($ZConvert(..CurrentNowShow.Gender, "U"), "M":"male", "F":"female")
    Set patient.birthDate = $ZDate($Zdateh(..CurrentNowShow.ScheduledDay, 3) - (..CurrentNowShow.Age * 365), 3)
    Set patient.address.%Get(0).city = ..CurrentNowShow.Neighborhood

    Set ..PatientEntry = ..AddToTransaction(patient)
}

Method AddAppointment(pFile As %String)
{
    Set appointment = ..GetJSONFromFile(pFile)
    Set appointment.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do appointment.%Get("participant").%Get(0).%Get("actor").%Set("reference", ..PatientEntry.fullUrl)

    Set appointment.created = $Piece(..CurrentNowShow.AppointmentDay, " ", 1)
    Set appointment.start = $Piece(..CurrentNowShow.ScheduledDay, " ", 1)_"T"_$Piece(..CurrentNowShow.ScheduledDay, " ", 2)_"Z"
    Set appointment.end = appointment.start
    Set:(..CurrentNowShow.Noshow) appointment.status = "noshow"

    Do ..AddToTransaction(appointment)
}

Method AddCondition(pFile As %String)
{
    Set condition = ..GetJSONFromFile(pFile)
    Set condition.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do condition.%Get("subject").%Set("reference", ..PatientEntry.fullUrl)
    Set conditionEntry = ..AddToTransaction(condition)
}

Method AddCommunication(pFile As %String)
{
    Set communication = ..GetJSONFromFile(pFile)
    Set communication.id = $ZConvert($System.Util.CreateGUID(), "L")
    Do communication.%Get("identifier").%Get(0).%Set("value", communication.id)
    Do communication.%Get("subject").%Set("reference", ..PatientEntry.fullUrl)
    Do communication.%Get("recipient").%Get(0).%Set("reference", ..PatientEntry.fullUrl)
    Set communicationEntry = ..AddToTransaction(communication)
}

}
