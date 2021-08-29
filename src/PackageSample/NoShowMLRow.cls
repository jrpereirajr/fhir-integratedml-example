Class PackageSample.NoShowMLRow Extends %Persistent
{

Property Gender As %Library.String;

Property ScheduledWeekDay As %Integer;

Property ScheduledWeek As %Integer;

Property WaitingDays As %Integer;

Property Age As %Library.Integer;

Property Hypertension As %Library.Boolean;

Property Diabetes As %Library.Boolean;

Property Alcoholism As %Library.Boolean;

Property Handicap As %Library.Boolean;

Property SMSreceived As %Library.Boolean;

Property Noshow As %Library.Boolean;

Storage Default
{
<Data name="NoShowMLRowDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Gender</Value>
</Value>
<Value name="3">
<Value>ScheduledDay</Value>
</Value>
<Value name="4">
<Value>Age</Value>
</Value>
<Value name="5">
<Value>Neighborhood</Value>
</Value>
<Value name="6">
<Value>Hypertension</Value>
</Value>
<Value name="7">
<Value>Diabetes</Value>
</Value>
<Value name="8">
<Value>Alcoholism</Value>
</Value>
<Value name="9">
<Value>Handicap</Value>
</Value>
<Value name="10">
<Value>SMSreceived</Value>
</Value>
<Value name="11">
<Value>Noshow</Value>
</Value>
<Value name="12">
<Value>ScheduledWeekDay</Value>
</Value>
<Value name="13">
<Value>ScheduledWeek</Value>
</Value>
<Value name="14">
<Value>WaitingDays</Value>
</Value>
</Data>
<DataLocation>^PackageSample.NoShowMLRowD</DataLocation>
<DefaultData>NoShowMLRowDefaultData</DefaultData>
<IdLocation>^PackageSample.NoShowMLRowD</IdLocation>
<IndexLocation>^PackageSample.NoShowMLRowI</IndexLocation>
<StreamLocation>^PackageSample.NoShowMLRowS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
