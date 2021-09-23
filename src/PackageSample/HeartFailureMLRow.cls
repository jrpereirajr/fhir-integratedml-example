Class PackageSample.HeartFailureMLRow Extends %Persistent
{

Property age As %Library.Integer;

Property anaemia As %Library.Integer;

Property creatininephosphokinase As %Library.Integer;

Property diabetes As %Library.Integer;

Property ejectionfraction As %Library.Integer;

Property highbloodpressure As %Library.Integer;

Property platelets As %Library.Double;

Property serumcreatinine As %Library.Double;

Property serumsodium As %Library.Integer;

Property sex As %Library.Integer;

Property smoking As %Library.Integer;

Property followuptime As %Library.Integer;

Property DEATHEVENT As %Library.Integer;

Storage Default
{
<Data name="HeartFailureMLRowDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>age</Value>
</Value>
<Value name="3">
<Value>anaemia</Value>
</Value>
<Value name="4">
<Value>creatininephosphokinase</Value>
</Value>
<Value name="5">
<Value>diabetes</Value>
</Value>
<Value name="6">
<Value>ejectionfraction</Value>
</Value>
<Value name="7">
<Value>highbloodpressure</Value>
</Value>
<Value name="8">
<Value>platelets</Value>
</Value>
<Value name="9">
<Value>serumcreatinine</Value>
</Value>
<Value name="10">
<Value>serumsodium</Value>
</Value>
<Value name="11">
<Value>sex</Value>
</Value>
<Value name="12">
<Value>smoking</Value>
</Value>
<Value name="13">
<Value>time</Value>
</Value>
<Value name="14">
<Value>DEATHEVENT</Value>
</Value>
<Value name="15">
<Value>followuptime</Value>
</Value>
</Data>
<DataLocation>^PackageSample.HeartFailurAA88D</DataLocation>
<DefaultData>HeartFailureMLRowDefaultData</DefaultData>
<IdLocation>^PackageSample.HeartFailurAA88D</IdLocation>
<IndexLocation>^PackageSample.HeartFailurAA88I</IndexLocation>
<StreamLocation>^PackageSample.HeartFailurAA88S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
