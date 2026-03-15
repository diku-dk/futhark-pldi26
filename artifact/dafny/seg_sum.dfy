include "soacs.dfy"
import opened SOACs

function segment_scan(op: (int,int) -> int, ne: int, flags: seq<bool>, xs: seq<int>): (ys: seq<int>)
  requires monoid(op, ne)
  requires |flags| == |xs|
  ensures |xs| == |ys|
  ensures 0 < |xs| ==> ys[0] == xs[0]
  ensures forall i :: 1 <= i < |xs| ==> (flags[i] ==> ys[i] == xs[i]) && (!flags[i] ==> ys[i] == op(ys[i-1], xs[i]))
{
   // Our scan implementation requires the operator arguments to be (input, acc).
   var opL := (acc: (bool, int), x: (bool, int)) => (acc.0 || x.0, if x.0 then x.1 else op(acc.1, x.1));
   var neL := (false, ne);
   assume {:axiom} monoid(op, ne) ==> monoid(opL, neL);

   var zipped := zip(flags, xs);
   var res := scan(opL, neL, zipped);

   // Tell Dafny to unpack zipped.
   assert forall i :: 1 <= i < |res| ==> opL(res[i-1], zipped[i]) == opL(res[i-1], (flags[i], xs[i]));

   var unzipped := unzip(res);
   unzipped.1
}

function segment_sum(flags: seq<bool>, xs: seq<int>): (ys: seq<int>)
  requires |flags| == |xs|
  ensures |xs| == |ys|
  ensures 0 < |xs| ==> ys[0] == xs[0]
  ensures forall i :: 1 <= i < |xs| ==> (flags[i] ==> ys[i] == xs[i]) && (!flags[i] ==> ys[i] == ys[i-1] + xs[i])
{
  segment_scan((x,y) => x + y, 0, flags, xs)
}
