// Program discussed in Section 3.2.
include "../soacs.dfy"

import opened SOACs

function sum (s: seq<int>, ub: int) : int
  requires |s| > ub
{
  if ub < 0 then 0
  else s[ub] + sum(s, ub-1)
}

lemma {:induction false} sumLemma(s: seq<int>, ub: int)
   requires |s| > ub
   ensures  (ub  < 0) ==> sum(s,ub) == 0
   ensures  (ub >= 0) ==> sum(s, ub) == s[ub] + sum(s, ub-1)
{
  if ub < 0 {
    assert(sum(s, ub) == 0);
  } else {
    assert (sum(s, ub) == s[ub] + sum(s, ub-1));
    sumLemma(s, ub-1);
  }
}

// this implementation of prefix sum based on scan fails
method prefixSumFails(inp: seq<int>) returns (res: seq<int>)
  ensures  |inp| == |res|
  ensures  forall i :: 0 <= i < |inp| ==> res[i] == sum(inp, i)
{
  res := scan((x,y) => x + y, 0, inp);
  
  assert( |inp| > 0 ==> res[0] == sum(inp, 0) );
  
  forall i | 1 <= i < |inp|
    ensures res[i] == res[i-1] + inp[i]
    ensures res[i] == sum(inp, i)
    { sumLemma(inp, i-1); sumLemma(inp, i); }
}

// this lower-level loop-based implementation of prefix sum succeeds
method prefixSum(inp: seq<int>) returns (res: seq<int>)
  ensures  |inp| == |res|
  ensures  forall i :: 0 <= i < |inp|  ==>  res[i] == sum(inp, i)
{
  var n := |inp|;
  var arr := new int[n];

  var i: int := 0;
  while(i < n) // inclusive scan on cs
  invariant 0 <= i <= n
  invariant forall i1 :: (0 <= i1 < i) ==> arr[i1] == sum(inp, i1)
  {
    if i == 0 { arr[i] := inp[i];            }
    else      { arr[i] := arr[i-1] + inp[i]; }
    i := i+1;
  }
  res := arr[..];
}

lemma {:induction false} excScanLemma1(s: seq<int>, r : seq<int>)
  requires |s| == |r|
  requires |s| > 0
  requires r[0] == 0
  requires forall i :: 1 <= i < |s|  ==> r[i] == s[i-1]
  ensures  sum(s, |s|-1) == sum(r, |s|-1) + s[ |s|-1 ]
{
  if |s| == 1 {
    assert ( sum(s, |s|-1) == s[0] );
    assert ( sum(r, |s|-1) == 0 );
    assert ( sum(s, |s|-1) == sum(r, |s|-1) + s[0] );
  }
  else if |s| == 2 {
    assert( sum(r,0) == 0 );
    assert( sum(r,1) == r[1] == s[0]);
    assert( sum(s,0) == sum(r, 1) );
    assert( sum(s, |s|-1) == sum(r, |s|-1) + s[|s|-1] ); 
  }
  else {
    assert( s[ |s|-2 ] == r[ |s|-1 ] );
    assert( sum(r, |s|-1) == r[|s|-1] + sum(r, |s|-2) );
    assert( sum(s, |s|-1) == s[|s|-1] + sum(s, |s|-2) );
    sumLemma(s, |s|-1);
    sumLemma(s, |s|-2);
    sumLemma(s, |s|-3);
    sumLemma(r, |s|-1);
    sumLemma(r, |s|-2);
    excScanLemma(s[..|s|-1], r[..|s|-1]);
    assert( sum(s, |s|-2) == s[ |s|-2 ] + sum(r, |s|-2) );
    assert( (s[ |s|-1 ] + sum(s, |s|-2)) == (s[ |s|-2 ] + sum(r, |s|-2) + s[|s|-1]) );
    assert( (s[ |s|-1 ] + sum(s, |s|-2)) == (r[ |s|-1 ] + sum(r, |s|-2) + s[|s|-1]) );
  }
}

lemma {:induction false} excScanLemma(s: seq<int>, r : seq<int>)
  requires |s| == |r|
  requires |s| > 1
  requires |s| > 0 ==> r[0] == 0
  requires forall i :: 1 <= i < |s|  ==> r[i] == s[i-1]
  ensures  |s| >= 2  ==>  sum(r, |s|-1) == sum(s, |s|-2)
{
  if |s| == 2 {
    assert( sum(r,0) == 0 );
    assert( sum(r,1) == r[1] == s[0]);
    assert( sum(s, 0) == sum(r, 1) ); 
  }
  else {
    assert( s[|s|-2] == r[|s|-1] );
    assert( sum(r, |s|-1) == r[|s|-1] + sum(r, |s|-2) );
    assert( sum(s, |s|-2) == s[|s|-2] + sum(s, |s|-3) );
    sumLemma(s, |s|-2);
    sumLemma(s, |s|-3);
    sumLemma(r, |s|-1);
    sumLemma(r, |s|-2);
    assert( sum(r, |s|-2) == sum(s, |s|-3) ==> sum(r, |s|-1) == sum(s, |s|-2) );
    excScanLemma(s[..|s|-1], r[..|s|-1]);
  }
}  


method excScanInv(inp: seq<int>) returns (s: int)
  requires forall i :: 0 <= i < |inp| ==> inp[i] >= 0  // for simplicity positive elems
  ensures |inp| > 0 ==> s == sum(inp, |inp|-1)
{
  var m := |inp|;
  var iota := seq(m, i requires 0 <= i < m => i);
  var inp_rot := fmap(i => if 1 <= i < m then inp[i-1] else 0, iota);
  var inp_exc_scan := prefixSum(inp_rot);  // exclusive scan of input

  // Succeeds: inp_rot[i] == inp[i-1]
  forall i | 0 <= i < m
    ensures inp_rot[0] == 0
    ensures i > 0 ==> inp_rot[i] == inp[i-1] { }

  // Succeeds
  assert(|inp_exc_scan| == |inp|);

  // Succeeds: inp_exc_scan[i] = sum(inp_rot, i)
  forall i | 0 <= i < m
    ensures inp_exc_scan[0] == sum(inp_rot, 0) == 0
    ensures inp_exc_scan[i] == sum(inp_rot, i)
    {}

  sumLemma(inp_rot, m-1);
  sumLemma(inp, m-1);
  sumLemma(inp, m-2);

  // Fails: inp_exc_scan[i] == sum(inp, i-1)
  forall i | 0 <= i < m
    ensures inp_exc_scan[0] == 0
    ensures ((m > 0) && (i > 0)) ==> inp_exc_scan[i] == sum(inp, i-1)
    {  
      sumLemma(inp_rot, i);
      sumLemma(inp_rot, i-1);
      sumLemma(inp_rot, i-2);
      sumLemma(inp, i);
      sumLemma(inp, i-1);
      sumLemma(inp, i-2);
    }

  s := if m > 0 then inp_exc_scan[m-1] + inp[m-1] else 0;
}
