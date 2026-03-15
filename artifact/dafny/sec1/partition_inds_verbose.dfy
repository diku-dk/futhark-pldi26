function sum (s: seq<int>, lb: int, ub: int) : int
  requires lb >= 0 && |s| > ub
  requires forall i :: 0 <= i < |s| ==> s[i] == 0 || s[i] == 1
{
  if ub < lb then 0
  else s[ub] + sum(s, lb, ub-1)
}

lemma {:induction false} sumLemma(s: seq<int>, lb: int, ub: int)
   requires lb >= 0  && |s| > ub
   requires forall i :: 0 <= i < |s| ==> s[i] == 0 || s[i] == 1
   ensures  (ub >= lb >= 0)  ==>  sum(s, lb, ub) == s[ub] + sum(s, lb, ub-1)
   ensures  (ub >= lb >= 0)  ==>  sum(s, lb, ub) == s[lb] + sum(s, lb+1, ub)
   ensures  (ub >= lb >= 0)  ==>  sum(s, lb, ub) >= 0
   ensures  forall i :: lb <= i <= ub  ==>  sum(s, lb, i) <= sum(s, lb, ub)
   ensures  forall i :: lb <= i <= ub  ==>  sum(s, i, ub) <= sum(s, lb, ub)
   ensures  (ub >= lb >= 0) && s[ub] > 0 ==>  sum(s, lb, ub) > 0
   ensures  (ub >= lb >= 0) && s[lb] > 0 ==>  sum(s, lb, ub) > 0 
   ensures  forall i :: (lb <= i < ub) && s[ub] > 0  ==>  sum(s, lb, i) < sum(s, lb, ub)
   ensures  forall i :: (lb < i <= ub) && s[lb] > 0  ==>  sum(s, i, ub) < sum(s, lb, ub)
   ensures  (ub >= lb >= 0) && (s[ub] > 0) ==> sum(s, lb, ub) == 1 + sum(s, lb, ub-1)
   //ensures  (ub >= lb >= 0)  ==> sum(s, lb, ub) <= 1 + sum(s, lb, ub-1) // not needed
   //ensures  (ub >= lb >= 0)  ==> sum(s, lb, ub) < ub - lb + 1           // fails
   //ensures sum(s,0,|s|-1) < |s|                                         // fails
   //ensures (ub >= lb >= 0) ==> sum(s, lb, ub) < |s|                     // fails
{
  if ub < lb { }
  else {
    sumLemma(s, lb, ub-1);
  }
}

method prefixSum1(cs: seq<int>) returns (indsT: array<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  |cs| == indsT.Length
  // All (helper) invariants below are necessary 
  ensures  forall i :: 0 <= i < |cs|  ==>  indsT[i] >= 0
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) ==> indsT[i1] <= indsT[i2]
  ensures  forall i :: (0 <= i < |cs|) ==> indsT[i] == sum (cs, 0, i)
  ensures  forall i :: (0 <= i < |cs|) && cs[i] == 1 ==> indsT[i] >= 1
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i2] == 1) ==> indsT[i1] < indsT[i2]
{
  var n := |cs|;
  var i: int := 0;

  indsT := new int[n];

  while(i < n) // inclusive scan on cs
  invariant 0 <= i <= n
  invariant forall i1 :: (0 <= i1 < i) ==> indsT[i1] >= 0
  invariant forall i1 :: (0 <= i1 < i) ==> indsT[i1] == sum(cs, 0, i1)
  invariant forall i1 :: forall i2 :: (0 <= i1 < i2 < i) ==> indsT[i1] <= indsT[i2]
  invariant forall i1 :: (0 <= i1 < i) && (cs[i1] == 1) ==> indsT[i1] >= 1
  {
    if i == 0 { indsT[i] := cs[i];              }
    else      { indsT[i] := indsT[i-1] + cs[i]; }
    i := i+1;
  }
}

method negBoolArr(cs: seq<int>) returns (csN: array<int>)
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  fresh(csN)
  ensures  |cs| == csN.Length
  ensures  forall i :: 0 <= i < |cs|  ==>  csN[i] >= 0 && csN[i] <= 1
  ensures  forall i :: 0 <= i < |cs|  ==>  csN[i] == 1 - cs[i]
{
  var i: int;
  var n: int := |cs|;
  
  csN := new int[n];
  
  i := 0;
  while(i < n) // csN[i] := 1 - cs[i]
  invariant 0 <= i <= n
  invariant forall i1 :: (0 <= i1 < i) ==> csN[i1] >= 0 && csN[i1] <= 1
  invariant forall i1 :: (0 <= i1 < i) ==> csN[i1] == 1 - cs[i1]
  {
    csN[i] := 1 - cs[i];
    i := i+1;
  }
}

method prefixSum2(cs: seq<int>) returns (indsF: array<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  |cs| == indsF.Length
  // All (helper) invariants below are necessary 
  ensures  forall i :: 0 <= i < |cs|  ==>  indsF[i] >= 0
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) ==> indsF[i1] <= indsF[i2]
  ensures  forall i :: (0 <= i < |cs|) ==> indsF[i] == i + 1 - sum (cs, 0, i)
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i2] == 0) ==> indsF[i1] < indsF[i2]
{
  var n := |cs|;
  var i: int := 0;
  
  var csN := negBoolArr(cs);
  var csF := csN[..];

  indsF := new int[n];

  while(i < n) // inclusive scan on cs
  invariant 0 <= i <= n
  invariant forall i1 :: (0 <= i1 < i) ==> indsF[i1] >= 0
  invariant forall i1 :: forall i2 :: (0 <= i1 < i2 < i) ==> indsF[i1] <= indsF[i2]
  invariant forall i1 :: (0 <= i1 < i) ==> indsF[i1] == sum(csF, 0, i1)
  invariant forall i1 :: (0 <= i1 < i) ==> csF[i1] == 1 - cs[i1]
  invariant forall i1 :: (0 <= i1 < i) ==> indsF[i1] == i1 + 1 - sum(cs, 0, i1)
  {
    if i == 0 { indsF[i] := csF[i];              }
    else      { indsF[i] := indsF[i-1] + csF[i]; }
    i := i+1;
  }
}

method partition_inds(cs: seq<int>) returns (num_true: int, indices: seq<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] == 0 || cs[i] == 1
  ensures  |cs| == |indices|
  ensures  num_true >= 0 && num_true <= |cs|
  ensures forall i :: (0 <= i < |cs|)  ==>  indices[i] >= 0
  ensures forall i :: (0 <= i < |cs|)  ==>  indices[i] < |cs|
  ensures forall i :: (0 <= i < |cs|) && (cs[i] == 1) ==> indices[i]  < num_true
  ensures forall i :: (0 <= i < |cs|) && (cs[i] == 0) ==> indices[i] >= num_true
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 1) && (cs[i2] == 1) ==> indices[i1] < indices[i2]
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 1) && (cs[i2] == 0) ==> indices[i1] < indices[i2]
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 0) && (cs[i2] == 1) ==> indices[i1] > indices[i2]
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 0) && (cs[i2] == 0) ==> indices[i1] < indices[i2]
{
  var n := |cs|;
  var i: int;

/*
  forall j1 | (0 <= j1 < n) && (cs[j1] == 0)
    ensures sum(cs, 0, n-1) + j1 - sum (cs, 0, j1) >= 0
    ensures sum(cs, 0, n-1) + j1 - sum (cs, 0, j1) <  n // !! this fails in this position but succeeds later on !!
    { sumLemma(cs, 0, j1); sumLemma(cs, 0, n-1); } 
*/

  var indsTa: array<int> := prefixSum1(cs);
  num_true := indsTa[n-1];

  //assert(num_true >= 0 && num_true <= n); // cannot verify this at this position, but succeeds later on
  
  var indsFa := prefixSum2(cs);

  var indsT: seq<int> := indsTa[..];
  var indsF: seq<int> := indsFa[..];

  indices := seq(|cs|, i requires 0 <= i < |cs| => if cs[i] == 1 then indsT[i] - 1 else indsF[i] + num_true - 1 );

  forall i | 0 <= i < n
    ensures cs[i] == 1  ==>  indices[i]  < num_true
    ensures cs[i] == 0  ==>  indices[i] >= num_true
    { sumLemma(cs, 0, i); }   // !! sumLemma necessary here !!

/*
  var iota := seq(n, i requires 0 <= i < n => i);
  assert( multiset(iota[..]) == multiset(indices[..]) ); // !! this fails !!
*/
}

// dafny verify --verification-time-limit 0 --error-limit 0 part2Inds-verbose-success.dfy
