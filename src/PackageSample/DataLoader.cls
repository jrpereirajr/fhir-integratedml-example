Class PackageSample.DataLoader Extends HS.FHIRServer.Tools.DataLoader
{

Property Response As HS.FHIRServer.API.Data.Response;

Method MySubmitResourceStream(pResourceStream As %Stream.Object, pFormatCode As %String = "", Output pResponse) As %Status
{
	Set tSC = ..SubmitResourceStream(pResourceStream, pFormatCode)
    Set pResponse = ..Response
    Return tSC
}

Method BuildAndSubmitToFHIRService(pResourceType As %String, pResourceId As %String, pFormatCode As %String, pQuickStream As HS.SDA3.QuickStream, pDynObj As %Library.DynamicObject, pDynObjElapsed As %Decimal, ByRef pElapsed As %Decimal) [ Internal ]
{
	Set tRequest = ##class(HS.FHIRServer.API.Data.Request).%New()
	Set tResponse = ##class(HS.FHIRServer.API.Data.Response).%New()
	
	If pResourceType="Bundle" {
		// transaction
		Set tRequest.RequestPath = ""
		Set tRequest.RequestMethod = "POST"
	} ElseIf pResourceId="" {
		// create
		Set tRequest.RequestPath = "/"_pResourceType
		Set tRequest.RequestMethod = "POST"
	} Else {
		// update
		Set tRequest.RequestPath = "/"_pResourceType_"/"_pResourceId
		Set tRequest.RequestMethod = "PUT"
	}
	
	Set tRequest.RequestFormatCode = pFormatCode
	Set tRequest.ResponseFormatCode = tRequest.RequestFormatCode

	Set tStart = $ZH
	
	If $IsObject(pDynObj) {
		Set tRequest.Json = pDynObj
	} Else {
		Set tRequest.Json = ..FHIRService.StreamToJSON(pQuickStream, tRequest.RequestFormatCode)
	}
	
	Do ..PreFHIRService(tRequest)
	
	Do ..FHIRService.DispatchRequest(tRequest, .tResponse)
    Set ..Response = tResponse
	
	Set tEnd = $ZH
	
	// Include time spent converting JSON stream to %DynamicObject, to more
	// closely match the FHIRService time spent when called over HTTP.
	Set pElapsed = ((tEnd-tStart) + pDynObjElapsed)
	
	If '((+tResponse.Status=200)||(+tResponse.Status=201)) {
		If $IsObject(tResponse.Json) {
			Set tText = tResponse.Json.%ToJSON()
			Set tText = " ("_tText_")"
		} Else {
			Set tText = ""
		}
		$$$ThrowStatus($$$ERROR($$$HSFHIRErrFHIRRequestFailed, tResponse.Status, tText))
	}
	
	Do pQuickStream.Clear()
	
	Quit
}

}
