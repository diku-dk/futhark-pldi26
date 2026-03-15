include "soacs.dfy"
include "sec3.1/partition_inds.dfy"
import opened SOACs

ghost predicate Filt(xs: seq<int>, p: int -> bool, ys: seq<int>)
{
  // ys is a permutation of xs via inds
  exists inds : seq<int>, size: int ::
    0 <= size <= |xs|
    && |ys| == size
    && InvPart(xs, p, inds, size)
    && (forall i :: 0 <= i < |xs| && !p(xs[i]) ==> inds[i] < 0 || |ys| <= inds[i])
    && (forall i :: 0 <= i < |xs| && p(xs[i]) ==> ys[inds[i]] == xs[i])
}

method filter(p: int -> bool, xs: seq<int>) returns (size: int, inds: seq<int>, ys: seq<int>)
  ensures Filt(xs, p, ys)
{
  size, inds := partition_inds(p, xs);
  assert size >= 0;
  var dest := seq(size, i => 0);
  ys := scatter(dest, inds, xs);
}
