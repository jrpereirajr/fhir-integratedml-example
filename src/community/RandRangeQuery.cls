Class community.RandRangeQuery
{

/*
--SELECT * FROM PackageSample.HeartFailureMLRow WHERE ID in (select top 200 idx from community.randrange(1, 300) order by randValue) order by 1

--select * from (select top 200 idx from community.randrange(1, 300) order by randValue) order by 1 

--select top 200 * from community.randrange(1, 300)
*/
Query RandRange(pStart As %Integer, pStop As %Integer, pStep As %Integer = 1) As %Query(ROWSPEC = "idx:%Integer,randValue:%Integer") [ SqlName = randrange, SqlProc ]
{
}

ClassMethod RandRangeExecute(ByRef qHandle As %Binary, pStart As %Integer, pStop As %Integer, pStep As %Integer = 1) As %Status
{
  Set qHandle("iterator") = pStart
  Set qHandle("start") = pStart
  Set qHandle("stop") = pStop - 1
  Set qHandle("step") = pStep
  // As $Random() always gives us a number in [0, stop) interval, 
  // calculates a proportion coefficient to map into [start, stop) interval
  Set qHandle("coef") = (pStop - pStart) / pStop
  Return $$$OK
}

ClassMethod RandRangeFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = RandRangeExecute ]
{
  Set start = qHandle("start")
  Set stop = qHandle("stop")
  Set step = qHandle("step")
  Set coef = qHandle("coef")

  Set n = $Random(stop)
  Set randValue = $Number((n * coef) + start, 0)
  Set idx = qHandle("iterator")
  Set Row = $LB(idx, randValue)

  Set qHandle("iterator") = idx + step
  Set AtEnd = qHandle("iterator") >= stop

  Return $$$OK
}

ClassMethod RandRangeClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = RandRangeExecute ]
{
  Return $$$OK
}

}
