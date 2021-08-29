Class PackageSample.PopulateAbstract Extends %RegisteredObject [ Abstract ]
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
                Set stream = ..ProcessRecord()
                Do ..LoadAndSaveResource(stream)
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

Method GetNoShowDataset() As %SQL.IResultSet [ Abstract ]
{
}

Method ProcessRecord() As %Stream.GlobalCharacter
{
    Set ..Transaction = {
        "resourceType": "Bundle",
        "id": "bundle-transaction",
        "type": "transaction",
        "entry": []
    }

    Do ..OnProcessRecord()

    Set stream = ##class(%Stream.GlobalCharacter).%New()
    $$$TOE(sc, stream.Write(..Transaction.%ToJSON()))

    Return stream
}

Method LoadAndSaveResource(stream As %Stream.GlobalCharacter)
{
    Set:('$IsObject(..DataLoader)) ..DataLoader = ##class(PackageSample.DataLoader).%New("FHIRSERVER","/fhir/r4")
    $$$TOE(sc, ..DataLoader.MySubmitResourceStream(stream, "JSON"))
}

Method OnProcessRecord() [ Abstract ]
{
}

Method GetJSONFromFile(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set fileStream = ##class(%FileCharacterStream).%New()
    Set fileStream.Filename = pFileTemplate
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

Method CreateResource(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set resource = ..GetJSONFromFile(pFileTemplate)
    Set resource.id = $ZConvert($System.Util.CreateGUID(), "L")
    Return resource
}

}
