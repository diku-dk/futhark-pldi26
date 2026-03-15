// Program discussed in Section 3.1.
include "../soacs.dfy"

import opened SOACs

ghost predicate InvPart(xs: seq<int>, p: int -> bool, inds: seq<int>, split: int)
{
    // inds are a permutation of [0, |xs|)
    |xs| == |inds|
    && inj(inds)
    && (forall i :: 0 <= i < |xs| ==> 0 <= inds[i] < |xs|)

    // inds is partitioned at index split
    && 0 <= split <= |inds|
    && (forall i :: 0 <= i < |xs| ==> (p(xs[i]) <==> inds[i] < split))

    // inds is a stable partition
    && (forall i, j :: 0 <= i < j < |xs| ==>
          ( p(xs[i]) &&  p(xs[j]) ==> inds[i] < inds[j])
          && ( p(xs[i]) && !p(xs[j]) ==> inds[i] < inds[j])
          && (!p(xs[i]) &&  p(xs[j]) ==> inds[i] > inds[j]) // Note `>` not `<`.
          && (!p(xs[i]) && !p(xs[j]) ==> inds[i] < inds[j]))
}


method partition_inds(p: int -> bool, xs: seq<int>) returns (split: int, inds: seq<int>)
    ensures InvPart(xs, p, inds, split)
{
    var n := |xs|;
    var conds := fmap(x => p(x), xs);
    var tflgs := fmap(c => if c then 1 else 0, conds);
    var fflgs := fmap(b => 1 - b, tflgs);

    var indsT := scan((x,y) => x + y, 0, tflgs);
    var tmp := scan((x,y) => x + y, 0, fflgs);

    split := if n > 0 then indsT[n-1] else 0;
    var indsF := fmap(t => t + split, tmp);
    inds := map3((c, indT, indF) => if c then indT - 1 else indF - 1, conds, indsT, indsF);

    // Lemmas needed to show postconditions.
    SumOverNonNegativesIsMonotonicLemma(tflgs, indsT);
    SumOverNonNegativesIsMonotonicLemma(fflgs, tmp);
    ComplementarySumsLemma(tflgs, indsT, fflgs, tmp);
}

lemma ComplementarySumsLemma(xs: seq<int>, sum_xs: seq<int>, ys: seq<int>, sum_ys: seq<int>)
    // sum_xs is a sum over xs.
    requires |xs| == |sum_xs|
    requires 0 < |xs| ==> sum_xs[0] == xs[0]
    requires forall i :: 1 <= i < |xs| ==> sum_xs[i] == sum_xs[i-1] + xs[i]

    // sum_ys is a sum over ys.
    requires |ys| == |sum_ys|
    requires 0 < |ys| ==> sum_ys[0] == ys[0]
    requires forall i :: 1 <= i < |ys| ==> sum_ys[i] == sum_ys[i-1] + ys[i]

    // xs and ys are complementary booleans.
    requires |xs| == |ys|
    requires forall i :: 0 <= i < |xs| ==> 0 <= xs[i] <= 1
    requires forall i :: 0 <= i < |ys| ==> ys[i] == 1 - xs[i]

    ensures forall i :: 0 <= i < |xs| ==> sum_xs[i] + sum_ys[i] == i+1
{
    if xs == [] {
      assert ys == [];
    } else if |xs| == 1 {
      assert sum_xs[0] + sum_ys[0] == 1;
    } else {
      ComplementarySumsLemma(xs[..|xs|-1], sum_xs[..|xs|-1], ys[..|xs|-1], sum_ys[..|xs|-1]);
      assert sum_xs[|xs|-1] + sum_ys[|xs|-1] == 1 + sum_xs[|xs|-2] + sum_ys[|xs|-2];
    }
}

lemma SumOverNonNegativesIsMonotonicLemma(xs: seq<int>, ys: seq<int>)
    requires |xs| == |ys|
    requires 0 < |xs| ==> ys[0] == xs[0]
    requires forall i :: 1 <= i < |xs| ==> ys[i] == ys[i-1] + xs[i]
    requires forall i :: 0 <= i < |xs| ==> 0 <= xs[i]
    ensures forall i, j :: 0 <= i < j < |xs| ==> ys[i] <= ys[j]
    ensures forall i, j :: 0 <= i < j < |xs| && 0 < xs[j] ==> ys[i] < ys[j]
{
    if xs == [] {
      assert ys == [];
    } else if |xs| == 1 {
      assert ys == xs;
    } else {
      assert ys[|xs|-1] == xs[|xs|-1] + ys[|xs|-2];
      SumOverNonNegativesIsMonotonicLemma(xs[..|xs|-1], ys[..|xs|-1]);
    }
}

