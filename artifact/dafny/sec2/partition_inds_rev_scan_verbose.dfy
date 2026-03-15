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

method prefixSumBools(cs: seq<int>) returns (indsT: array<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  |cs| == indsT.Length
  // All invariants below are necessary 
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
  //invariant forall i1 :: (1 <= i1 < i) ==> indsT[i1-1] <= indsT[i1]
  invariant forall i1 :: forall i2 :: (0 <= i1 < i2 < i) ==> indsT[i1] <= indsT[i2]
  invariant forall i1 :: (0 <= i1 < i) && (cs[i1] == 1) ==> indsT[i1] >= 1
  {
    if i == 0 { indsT[i] := cs[i];              }
    else      { indsT[i] := indsT[i-1] + cs[i]; }
    i := i+1;
  }
}

method negBoolArr(cs: seq<int>) returns (csN: array<int>)
//  reads cs
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  fresh(csN)
  ensures  |cs| == csN.Length
//  ensures  forall i :: 0 <= i < |cs|  ==>  cs[i] == old(cs[i])
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
    //if (cs[i] == 1) { csN[i] := 0; assert(csN[i] == 1 - cs[i]); } else { csN[i]:= 1; assert(csN[i] == 1 - cs[i]);}
    csN[i] := 1 - cs[i];
    i := i+1;
  }
}

method prefixSumRevBools(cs: seq<int>) returns (indsF: seq<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] >= 0 && cs[i] <= 1
  ensures  |cs| == |indsF|
  // All invariants below are necessary 
  ensures  forall i :: 0 <= i < |cs|  ==>  indsF[i] >= 0
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) ==> indsF[i1] <= indsF[i2]
  ensures  forall i :: (0 <= i < |cs|) ==> indsF[i] == i + 1 + sum(cs, i+1, |cs|-1)
  ensures  forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i2] == 0) ==> indsF[i1] < indsF[i2]
{
  var n := |cs|;
  var i: int := 0;
  
  var csR := seq(|cs|, i requires 0 <= i < |cs| => cs[n-1-i] );

  forall j1 | (0 <= j1 < n) 
    ensures csR[j1] == cs[n-1-j1] {}   

  var indsFa: array<int> := new int[n];
    
  while(i < n) // exclusive scan on cs
  invariant 0 <= i <= n
  invariant forall i1 :: (0 <= i1 < i) ==> indsFa[i1] >= 0
  invariant forall i1 :: forall i2 :: (0 <= i1 < i2 < i) ==> indsFa[i1] <= indsFa[i2]
  invariant forall i1 :: (0 <= i1 < i) ==> indsFa[i1] == sum(csR, 0, i1-1)
  //invariant forall i1 :: (0 <= i1 < i) ==> indsFa[i1] == sum(cs, n-i1, n-1)
  {
    if i == 0 { indsFa[i] := 0;                      }
    else      { indsFa[i] := indsFa[i-1] + csR[i-1]; }
    i := i + 1;
  }
  
  var indsFb : seq<int> := indsFa[..];
  
  forall j1 | (0 <= j1 < n) 
    ensures indsFb[j1] == sum(csR,  0, j1-1)
    ensures indsFb[j1] == sum(cs, n-j1, n-1)
    { sumLemma(cs, j1+1, n-1); sumLemma(cs, n-j1, n-1); }
  
  indsF := seq(|cs|, i requires 0 <= i < |cs| => i + 1 + indsFb[n-i-1] );

  forall j1 | (0 <= j1 < n) 
    ensures indsF[j1] == j1 + 1 + sum (cs, j1+1, n-1)
    { sumLemma(cs, j1+1, n-1); }
}


predicate inj<T(==)>(xs: seq<T>)
{
  // forall i :: 0 <= i < xs.Length ==> multiset(xs[..])[xs[i]] == 1
  forall i, j :: 0 <= i < j < |xs| ==> xs[i] != xs[j]
}

predicate rep<T(==)>(xs: seq<T>)
{
  forall i :: 0 <= i < |xs| ==> xs[0] == xs[i]
}

method partition_inds_rev_scan(cs: seq<int>) returns (indices: seq<int>)
  requires |cs| > 0
  requires forall i :: 0 <= i < |cs|  ==>  cs[i] == 0 || cs[i] == 1
  ensures  |cs| == |indices|
  ensures forall i :: (0 <= i < |cs|)  ==>  indices[i] >= 0
  ensures forall i :: (0 <= i < |cs|)  ==>  indices[i] < |cs|
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 1) && (cs[i2] == 1) ==> indices[i1] < indices[i2]
  ensures forall i1 :: forall i2 :: (0 <= i1 < i2 < |cs|) && (cs[i1] == 1) && (cs[i2] == 0) ==> indices[i1] < indices[i2]
{
  var n := |cs|;
  var i: int;

/* 
  // cannot verify at this position 
  forall j1 | (0 <= j1 < n) && (cs[j1] == 0)
    ensures sum(cs, 0, n-1) + j1 - sum (cs, 0, j1) >= 0
    ensures sum(cs, 0, n-1) + j1 - sum (cs, 0, j1) <  n 
    { sumLemma(cs, 0, j1); sumLemma(cs, 0, n-1); } 
*/
  var indsTa: array<int> := prefixSumBools(cs);
  var num_true: int := indsTa[n-1];
  var indsF := prefixSumRevBools(cs);

  var indsT: seq<int> := indsTa[..];

  forall ii, j | 0 <= j < ii < n && cs[ii] == 1 && cs[j] == 0
    ensures j + sum(cs, 0, n-1) - sum(cs, 0, j) - sum(cs, 0, ii-1) > 0
    ensures j + 1 + sum(cs, j+1, n-1) - sum(cs, 0, ii) > 0
    { sumLemma(cs, 0, ii); sumLemma(cs, 0, j); sumLemma(cs, 0, n-1); sumLemma(cs, j+1, n-1); }

  indices := seq(|cs|, i requires 0 <= i < |cs| => if cs[i] == 1 then indsT[i] - 1 else indsF[i] - 1 );

  // bounds for num_true
  assert(num_true == sum(cs, 0, n-1));
  assert(num_true >= 0 && num_true <= n);

  forall i | 0 <= i < num_true
    ensures cs[i] == 1  ==>  indices[i]  < num_true
    ensures cs[i] == 0  ==>  indices[i] >= num_true
    { sumLemma(cs, 0, i); }

  forall i | 0 <= i < n
    ensures indices[i] >= 0
    ensures indices[i]  < n {
    sumLemma(cs, 0, i);
  }
  
  forall i1, i2 | 0 <= i1 < i2 < n
    ensures (cs[i1] == 1) && (cs[i2] == 1) ==> indices[i1] < indices[i2]
    ensures (cs[i1] == 0) && (cs[i2] == 0) ==> indices[i1] < indices[i2]
    ensures (cs[i1] == 1) && (cs[i2] == 0) ==> indices[i1] < indices[i2]
    ensures (cs[i1] == 0) && (cs[i2] == 1) ==> indices[i2] < indices[i1] {
    sumLemma(cs, 0, i1); sumLemma(cs, 0, i2);
  }
}

// dafny verify --verification-time-limit 0 --error-limit 0 part2Inds-rev-scan-verbose-fails.dfy
