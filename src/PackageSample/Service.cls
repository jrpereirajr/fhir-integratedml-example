Class PackageSample.Service Extends %RegisteredObject
{

Property FHIRBundle As %Stream.Object;

Property DAO As PackageSample.DAO;

Method %OnNew() As %Status
{
    Set ..DAO = ##class(PackageSample.DAO).%New()
    Return $$$OK
}

Method PredictNoShow() As %DynamicAbstractObject
{
    Set fhirServerResponse = ..DAO.SaveFHIRResource(..FHIRBundle)
    Set patientKey = ..GetPatientKeyFromResponse(fhirServerResponse)
    Set patient = ##class(HSFHIR.X0001.S.Patient).KeyIdxOpen(patientKey)
    $$$TOE(sc, ##class(PackageSample.NoShowDTL).Transform(patient, .noShowRow))
    $$$TOE(sc, ##class(HSFHIR.X0001.S.Patient).%DeleteId(patient.%Id()))

    Set prediction = ..DAO.ExecuteNoShowPrediction(noShowRow)
    Return prediction
}

Method GetPatientKeyFromResponse(pFHIRServerResponse As HS.FHIRServer.API.Data.Response)
{
    Set patientLocation = pFHIRServerResponse.Json.entry.%Get(0).response.location
    Set patientKey = $Extract(patientLocation, 2, *)
    Return patientKey
}

}
