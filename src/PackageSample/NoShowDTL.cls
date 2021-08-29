Class PackageSample.NoShowDTL Extends Ens.DataTransformDTL [ DependsOn = (HSFHIR.X0001.S.Patient, PackageSample.NoShowMLRow) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='HSFHIR.X0001.S.Patient' targetClass='PackageSample.NoShowMLRow' create='new' language='objectscript' >
<sql>
<annotation>Patient appointment</annotation>
<![CDATA[Select Top 1
  (Select dateStart 
  From HSFHIR_X0001_S.Schedule 
  Where Key = (
    Select schedule 
    From HSFHIR_X0001_S.Slot
    Where Key %INLIST(apt.slot)
  )),
  "date", 
  Case status When 'noshow' Then 1 Else 0 End 
INTO :AppointmentTimestamp, :ScheduledTimestamp, :AppointmentNoShow 
From HSFHIR_X0001_S.Appointment apt
Where FOR SOME %ELEMENT(patient) (%VALUE = :source.Key)]]></sql>
<sql>
<annotation>Patient hypertension condition check</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionHypertension 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '77970009')]]></sql>
<sql>
<annotation>Patient diabetes condition check</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionDiabetes 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '46635009')]]></sql>
<sql>
<annotation>Patient alcoholism condition check</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionAlcoholism 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '66590003')]]></sql>
<sql>
<annotation>Patient disability condition check</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ConditionDisability 
From HSFHIR_X0001_S.Condition 
Where 
  patient = :source.Key 
  And For Some %ELEMENT(code) (%VALUE = '21134002')]]></sql>
<sql>
<annotation>SMS reminder receiving check</annotation>
<![CDATA[Select Case Count(*) When 0 Then 0 Else 1 End Into :ReminderReceived 
From HSFHIR_X0001_S.Communication
Where 
  patient = :source.Key 
  And For Some %ELEMENT(category) (%VALUE = 'reminder')]]></sql>
<code>
<![CDATA[ Set AppointmentDate = $Replace($Replace($G(AppointmentTimestamp, ""), "T", " "), "Z", "")]]></code>
<code>
<![CDATA[ Set ScheduleDate = $Replace($Replace($G(ScheduledTimestamp, ""), "T", " "), "Z", "")]]></code>
<assign value='$Case(source.gender, "male":"M", "female":"F")' property='target.Gender' action='set' />
<assign value='$Case(AppointmentTimestamp, "":"", :$ZDateH(AppointmentTimestamp, 3) - $ZDateH(source.birthdate, 3)) \ 365' property='target.Age' action='set' />
<assign value='$G(ConditionHypertension, "")' property='target.Hypertension' action='set' />
<assign value='$G(ConditionDiabetes, "")' property='target.Diabetes' action='set' />
<assign value='$G(ConditionAlcoholism, "")' property='target.Alcoholism' action='set' />
<assign value='$G(ConditionDisability, "")' property='target.Handicap' action='set' />
<assign value='$ZDate($ZDateh(ScheduleDate, 3), 10)' property='target.ScheduledWeekDay' action='set' />
<assign value='$ZDate($ZDateh(ScheduleDate, 3), 14)  \ 4' property='target.ScheduledWeek' action='set' />
<assign value='$ZDateh(ScheduleDate, 3) - $ZDateh(AppointmentDate, 3)' property='target.WaitingDays' action='set' />
<assign value='$G(AppointmentNoShow, "")' property='target.Noshow' action='set' />
<assign value='$G(ReminderReceived, "")' property='target.SMSreceived' action='set' />
</transform>
}

}
