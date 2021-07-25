Class PackageSample.Service Extends %RegisteredObject
{

Property FHIRBundle As %Stream.Object;

Property Transformer As Ens.DataTransformDTL;

Property DAO As PackageSample.DAO;

Method %OnNew() As %Status
{
    Set ..DAO = ##class(PackageSample.DAO).%New()
    Return $$$OK
}

Method PredictNoShow() As %DynamicAbstractObject
{
    Set ..Transformer = ##class(PackageSample.NoShowDTL).%New()
    Set noShowRow = ..Transform()
    Set prediction = ..DAO.ExecuteNoShowPrediction(noShowRow)
    Return prediction
}

Method PredictHeartFailure() As %DynamicAbstractObject
{
    Set ..Transformer = ##class(PackageSample.HeartFailureDTL).%New()
    Set failureHeartRow = ..Transform()
    Set prediction = ..DAO.ExecuteHeartFailurePrediction(failureHeartRow)
    Return prediction
}

Method Transform() As %DynamicAbstractObject
{
    Set fhirServerResponse = ..DAO.SaveFHIRResource(..FHIRBundle)
    Try {
        Set patientKey = ..GetPatientKeyFromResponse(fhirServerResponse)
        Set patient = ##class(HSFHIR.X0001.S.Patient).KeyIdxOpen(patientKey)
        $$$TOE(sc, ..Transformer.Transform(patient, .record))
    } Catch(e) {
        Do ##class(HSFHIR.X0001.S.Patient).%DeleteId(patient.%Id())
        Throw e
    }
    $$$TOE(sc, ##class(HSFHIR.X0001.S.Patient).%DeleteId(patient.%Id()))
    Return record
}

Method GetPatientKeyFromResponse(pFHIRServerResponse As HS.FHIRServer.API.Data.Response)
{
    Set patientLocation = pFHIRServerResponse.Json.entry.%Get(0).response.location
    Set patientKey = $Extract(patientLocation, 2, *)
    Return patientKey
}

}
