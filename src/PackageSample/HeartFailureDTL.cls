Class PackageSample.HeartFailureDTL Extends Ens.DataTransformDTL [ DependsOn = (HSFHIR.X0001.S.Patient, PackageSample.HeartFailureMLRow) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HSFHIR.X0001.S.Patient' targetClass='PackageSample.HeartFailureMLRow' create='new' language='objectscript' >
<code>
<annotation>Base date for heart failure dataset.</annotation>
<![CDATA[ Set BASEDATE = $Parameter("Data.HeartFailure", "BASEDATE")]]></code>
<sql>
<annotation>Get if patient has some anaemia condition recorded</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionAnaemia 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '271737000')]]></sql>
<sql>
<annotation>Get if patient has some diabetes condition recorded</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionDiabetes 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '46635009')]]></sql>
<sql>
<annotation>Get the key for last patient high blood pressure observation</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ObservationHBP
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '85354-9') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient high blood pressure observation</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ObservationSmoker
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '77176002') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient creatine phosphokinase observation</annotation>
<![CDATA[Select Top 1 Key Into :ObservationKeyCPK
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '2157-6') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient ejection fraction observation</annotation>
<![CDATA[Select Top 1 Key Into :ObservationKeyEF
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = 'LP35012-1') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient platelets observation</annotation>
<![CDATA[Select Top 1 Key Into :ObservationKeyPlatelets
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '10412-5') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient serum creatinine observation</annotation>
<![CDATA[Select Top 1 Key Into :ObservationKeySerumCreatinine
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '20005') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the key for last patient serum sodium observation</annotation>
<![CDATA[Select Top 1 Key Into :ObservationKeySerumSodium
From HSFHIR_X0001_S.Observation 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '104934005') 
Order By ID1 Desc]]></sql>
<sql>
<annotation>Get the date for last patient encounter</annotation>
<![CDATA[Select Top 1 dateStart Into :LastEncounterDate
From HSFHIR_X0001_S.Encounter 
Where 
  patient = :source.Key 
Order By ID1 Desc]]></sql>
<assign value='$Case(source.gender, "male":0, "female":1)' property='target.sex' action='set' />
<assign value='(BASEDATE -  $ZDateh(source.birthdate, 3)) \ 365' property='target.age' action='set' />
<assign value='$G(ConditionAnaemia, "")' property='target.anaemia' action='set' />
<assign value='$G(ConditionDiabetes, "")' property='target.diabetes' action='set' />
<assign value='##class(HSFHIR.X0001.R.Rsrc).KeyIdxOpen(ObservationKeyCPK).ResourceObject.valueQuantity.value' property='target.creatininephosphokinase' action='set' >
<annotation>Get the valueQuantity value for creatine phosphokinase observation</annotation>
</assign>
<assign value='##class(HSFHIR.X0001.R.Rsrc).KeyIdxOpen(ObservationKeyEF).ResourceObject.valueQuantity.value' property='target.ejectionfraction' action='set' >
<annotation>Get the valueQuantity value for ejection fraction observation</annotation>
</assign>
<assign value='$G(ObservationHBP, "")' property='target.highbloodpressure' action='set' >
<annotation>Get the valueQuantity value for ejection fraction observation</annotation>
</assign>
<assign value='##class(HSFHIR.X0001.R.Rsrc).KeyIdxOpen(ObservationKeyPlatelets).ResourceObject.valueQuantity.value' property='target.platelets' action='set' >
<annotation>Get the valueQuantity value for ejection fraction observation</annotation>
</assign>
<assign value='##class(HSFHIR.X0001.R.Rsrc).KeyIdxOpen(ObservationKeySerumCreatinine).ResourceObject.valueQuantity.value' property='target.serumcreatinine' action='set' >
<annotation>Get the valueQuantity value for ejection fraction observation</annotation>
</assign>
<assign value='##class(HSFHIR.X0001.R.Rsrc).KeyIdxOpen(ObservationKeySerumSodium).ResourceObject.valueQuantity.value' property='target.serumsodium' action='set' >
<annotation>Get the valueQuantity value for ejection fraction observation</annotation>
</assign>
<assign value='$G(ObservationSmoker, "")' property='target.smoking' action='set' />
<assign value='BASEDATE - $ZDateh($G(LastEncounterDate, ""), 3)' property='target.followuptime' action='set' />
<assign value='$Case(source.deceased, 1:1, :0)' property='target.DEATHEVENT' action='set' />
</transform>
}

}
