Class PackageSample.ObjectScript
{

ClassMethod SerializeRow(pInput As %SQL.IResultSet) As %DynamicObject
{
    Set jsonObj = {}
    Set rsmd = pInput.%GetMetadata()
    Set columns = rsmd.columns
    Set colCount = columns.Count()
    For i=1:1:colCount {
        Set column = columns.GetAt(i)
        Set colName = column.colName
        Set colValue = pInput.%Get(colName)
        Do jsonObj.%Set(colName, colValue)
    }
    Return jsonObj
}

}
