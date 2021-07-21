Class PackageSample.Dispatch Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<Route Url="/predict-noshow" Method="POST" Call="PredictNoShow" Cors="true"/>
</Routes>
}

ClassMethod PredictNoShow() As %Status
{
    Set sc = $$$OK

    Set service = ##class(PackageSample.Service).%New()
    Set service.FHIRBundle = %request.Content
    Set prediction = service.PredictNoShow()
    Write prediction.%ToJSON()

    Return sc
}

}
