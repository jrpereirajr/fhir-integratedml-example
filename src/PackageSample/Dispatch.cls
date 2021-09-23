Class PackageSample.Dispatch Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<Route Url="/_spec" Method="GET" Call="SwaggerSpec" />
<Route Url="/get-sample-noshow" Method="GET" Call="GetSampleNoShow" Cors="true"/>
<Route Url="/predict-noshow" Method="POST" Call="PredictNoShow" Cors="true"/>
<Route Url="/predict-heart-failure" Method="POST" Call="PredictHeartFailure" Cors="true"/>
</Routes>
}

ClassMethod SwaggerSpec() As %Status
{
    Set tSC = ##class(%REST.API).GetWebRESTApplication($NAMESPACE, %request.Application, .swagger)
    Do swagger.info.%Remove("x-ISC_Namespace")
    Set swagger.basePath = "/fhir-ml/api"
    Set swagger.info.title = "IntegratedML on FHIR examples API"
    Set swagger.info.version = "0.1"
    Set swagger.host = "localhost:32783"
    Write swagger.%ToJSON()
    Return $$$OK
}

ClassMethod GetSampleNoShow() As %Status
{
    Set sc = $$$OK

    // todo: get a sample from test dataset
    Set id = 2001
    Set bundle = ##class(PackageSample.CreateNoShowBundle).%New().Create(id)
    Write bundle.%ToJSON()

    Return sc
}

ClassMethod PredictNoShow() As %Status
{
    Set sc = $$$OK

    Set service = ##class(PackageSample.Service).%New()
    Set service.FHIRBundle = %request.Content
    Set prediction = service.PredictNoShow()
    Throw:('$IsObject(prediction)) ##class(%Exception.General).%New("Model execution fail")
    Write prediction.%ToJSON()

    Return sc
}

ClassMethod PredictHeartFailure() As %Status
{
    Set sc = $$$OK

    Set service = ##class(PackageSample.Service).%New()
    Set service.FHIRBundle = %request.Content
    Set prediction = service.PredictHeartFailure()
    Throw:('$IsObject(prediction)) ##class(%Exception.General).%New("Model execution fail")
    Write prediction.%ToJSON()

    Return sc
}

}
