/// TODO: create a DTL to do this transformation getting data directly
Class PackageSample.CreateNoShowBundle Extends PackageSample.PopulateAbstract
{

Property AppointmentNoShowId As %Integer;

Method Create(pAppointmentNoShowId As %Integer) As %DynamicAbstractObject
{
    Set ..AppointmentNoShowId = pAppointmentNoShowId
    Set ..RecordsCount = 1
    Set rs = ..GetNoShowDataset()
    While rs.%Next() {
        Set ..CurrentRecord = ##class(PackageSample.Utils).SerializeRow(rs)
        Do ..ProcessRecord()
    }
    Return ..Transaction
}

Method GetNoShowDataset() As %SQL.IResultSet
{
    Set sql = ##class(gen.SQLBuilder).%New().Select(
        "*"
    ).From(
        "Data.AppointmentNoShow"
    ).Where(
        "Id = ?", ..AppointmentNoShowId
    ).Top(
        ..RecordsCount
    ).GetSQL()
    #Dim rs As %SQL.ISelectResult = ##class(%SQL.Statement).%ExecDirect(.stmt, sql)
    Return rs
}

Method OnProcessRecord()
{
    Do ..AddPatient(..FHIRTemplateBasePath_"/patient.json")
    Do ..AddSecheduledAppointmentHelper()
    
    If (..CurrentRecord.Hypertension) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-hypertension.json")
    }
    
    If (..CurrentRecord.Diabetes) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-diabetes.json")
    }
    
    If (..CurrentRecord.Alcoholism) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-alcolholims.json")
    }
    
    If (..CurrentRecord.Handicap) {
        Do ..AddCondition(..FHIRTemplateBasePath_"/condition-disability.json")
    }

    If (..CurrentRecord."SMS_received") {
        Do ..AddCommunication(..FHIRTemplateBasePath_"/communication.json")
    }
}

Method AddSecheduledAppointmentHelper()
{
    Set appointment = ..AddAppointment(..FHIRTemplateBasePath_"/appointment.json")

    Set slotResource = ..AddSlot(..FHIRTemplateBasePath_"/slot.json")
    Set slot = slotResource.resource
    Set appointment.slot = []
    Do appointment.slot.%Push({
        "reference": (slot.id)
    })

    Set scheduleResource = ..AddSchedule(..FHIRTemplateBasePath_"/schedule.json")
    Set schedule = scheduleResource.resource
    Set dateStart = $Piece(..CurrentRecord.ScheduledDay, " ", 1)_"T"_$Piece(..CurrentRecord.ScheduledDay, " ", 2)_"Z"
    Set schedule.planningHorizon = {
        "start": (dateStart),
        "end": (dateStart)
    }
    Set slot.schedule = {
        "reference": (schedule.id)
    }
}

Method AddPatient(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set patient = ..CreateResource(pFileTemplate)
    Do patient.%Get("identifier").%Get(0).%Set("value", patient.id)
    Do patient.%Get("identifier").%Get(1).%Set("value", patient.id)

    Set patient.gender = $Case($ZConvert(..CurrentRecord.Gender, "U"), "M":"male", "F":"female")
    Set patient.birthDate = $ZDate($Zdateh(..CurrentRecord.ScheduledDay, 3) - (..CurrentRecord.Age * 365), 3)
    Set patient.address.%Get(0).city = ..CurrentRecord.Neighborhood

    Set ..PatientEntry = ..AddToTransaction(patient)
    Return ..PatientEntry
}

Method AddAppointment(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set appointment = ..CreateResource(pFileTemplate)
    Do appointment.%Get("participant").%Get(0).%Get("actor").%Set("reference", ..PatientEntry.resource.id)

    Set appointment.created = $Piece(..CurrentRecord.AppointmentDay, " ", 1)
    Set appointment.start = $Piece(..CurrentRecord.AppointmentDay, " ", 1)_"T"_$Piece(..CurrentRecord.AppointmentDay, " ", 2)_"Z"
    Set appointment.end = appointment.start

    Do ..AddToTransaction(appointment)
    Return appointment
}

Method AddSlot(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set slot = ..CreateResource(pFileTemplate)
    Return ..AddToTransaction(slot)
}

Method AddSchedule(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set schedule = ..CreateResource(pFileTemplate)
    Return ..AddToTransaction(schedule)
}

Method AddCondition(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set condition = ..CreateResource(pFileTemplate)
    Do condition.%Get("subject").%Set("reference", ..PatientEntry.resource.id)
    Set conditionEntry = ..AddToTransaction(condition)
    Return conditionEntry
}

Method AddCommunication(pFileTemplate As %String) As %DynamicAbstractObject
{
    Set communication = ..CreateResource(pFileTemplate)
    Do communication.%Get("identifier").%Get(0).%Set("value", communication.id)
    Do communication.%Get("subject").%Set("reference", ..PatientEntry.resource.id)
    Do communication.%Get("recipient").%Get(0).%Set("reference", ..PatientEntry.resource.id)
    Set communicationEntry = ..AddToTransaction(communication)
    Return communicationEntry
}

}
