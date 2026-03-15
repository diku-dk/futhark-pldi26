include "filter.dfy"

method filter_mono(p: int -> bool, xs: seq<int>) returns (size: int, ys: seq<int>)
  requires forall i, j :: 0 <= i < j < |xs| ==> xs[i] <= xs[j]
  ensures forall i, j :: 0 <= i < j < |ys| ==> ys[i] <= ys[j]
{
  var inds;
  size, inds, ys := filter(p, xs);
}
