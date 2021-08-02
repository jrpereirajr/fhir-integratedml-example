Class community.RangeQuery
{

/**
select 'range', *, 'N/A' from community.range(0, 10000, 1000)
union
select 'randrange', * from community.randrange(0, 10000, 1000)
**/
Query Range(pStart As %Integer, pStop As %Integer, pStep As %Integer = 1) As %Query(ROWSPEC = "idx:%Integer") [ SqlName = range, SqlProc ]
{
}

ClassMethod RangeExecute(ByRef qHandle As %Binary, pStart As %Integer, pStop As %Integer, pStep As %Integer = 1) As %Status
{
  Set qHandle("idx") = pStart
  Set qHandle("stop") = pStop
  Set qHandle("step") = pStep
  Return $$$OK
}

ClassMethod RangeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = RangeExecute ]
{
  Set Row = $LB(qHandle("idx"))
  Set newValue = qHandle("idx") + qHandle("step")
  Set AtEnd = newValue >= qHandle("stop")
  Set:('AtEnd) qHandle("idx") = newValue
  Return $$$OK
}

ClassMethod RangeClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = RangeExecute ]
{
  Return $$$OK
}

}
