// Program discussed in Section 3.2.
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

/**
 * Conclusion for partition_inds_rev_scan
 *
 * partition_inds_rev_scan is like partition_inds, but the false indices are
 * computed by a scan over the reverse tflgs. (Same number of maps/scans so
 * valid way to write this for a user.)
 *
 * Crucially, this way of writing the function does not let us apply the
 * ComplementarySumsLemma (as was done in partition_inds). Nor is it clear what
 * an alternative lemma would be here; I've attempted (variations) of
 *   trues_at_and_before[i] + trues_at_and_after[i] - 1 < n.
 * but was unable to verify this.
 */
method partition_inds_rev_scan(p: int -> bool, xs: seq<int>) returns (split: int, inds: seq<int>)
    ensures InvPart(xs, p, inds, split)
{
    var n := |xs|;
    var conds := fmap(x => p(x), xs);
    var tflgs := fmap(c => if c then 1 else 0, conds);
    var tflgs_rev := seq(|tflgs|, i requires 0 <= i < |tflgs| => tflgs[n-1-i]);

    var trues_at_and_before := scan((x,y) => x + y, 0, tflgs);
    var trues_at_and_after := scan((x,y) => x + y, 0, tflgs_rev);

    split := if n > 0 then trues_at_and_before[n-1] else 0;

    // Lemmas needed to show postconditions.
    SumOverNonNegativesIsMonotonicLemma(tflgs, trues_at_and_before);
    SumOverNonNegativesIsMonotonicLemma(tflgs_rev, trues_at_and_after);
    SumBoolLemma(tflgs, trues_at_and_before);
    SumBoolLemma(tflgs_rev, trues_at_and_after);

    assert forall i :: 0 <= i < |xs| ==> trues_at_and_before[i] <= i+1;
    assert forall i :: 0 <= i < |xs| ==> trues_at_and_after[i] <= i+1;

    assert forall i :: 1 <= i < |xs| ==> tflgs_rev[i] == tflgs[n-1-i];
    assert forall i :: 1 <= i < |xs| ==> trues_at_and_after[i] == tflgs_rev[i] + trues_at_and_after[i-1];
    assert forall i :: 1 <= i < |xs| ==> trues_at_and_after[i] == tflgs[n-1-i] + trues_at_and_after[i-1];

    var indsT := fmap(i => i - 1, trues_at_and_before);
    assert forall i, j :: 0 <= i < j < |xs| ==> indsT[i] <= indsT[j];
    assert forall i :: 0 <= i < |xs| ==> -1 <= indsT[i] <= i;

    // We know the ith pos would be false here, so trues_at_and_after counts trues _after_.
    var indsF := map2((i,t) => i + t, seq(|xs|, i => i), trues_at_and_after);

    inds := map3((c, t, f) => if c then t else f, conds, indsT, indsF);
}

lemma SumBoolLemma(xs: seq<int>, sum_xs: seq<int>)
    // xs is boolean
    requires forall i :: 0 <= i < |xs| ==> 0 <= xs[i] <= 1
    // sum_xs is a sum over xs.
    requires |xs| == |sum_xs|
    requires 0 < |xs| ==> sum_xs[0] == xs[0]
    requires forall i :: 1 <= i < |xs| ==> sum_xs[i] == xs[i] + sum_xs[i-1]

    ensures forall i :: 0 <= i < |xs| ==> sum_xs[i] <= i+1
{
    assume {:axiom} false;
}

function sum(xs: seq<int>): (y: int)
{
    var ys := scan((x,y) => x + y, 0, xs);
    if |ys| > 0 then ys[|ys|-1] else 0
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
      assert sum_xs[|xs|-1] + sum_ys[|xs|-1] == 1 + sum_xs[|xs|-2] + sum_ys[|xs|-2];
      ComplementarySumsLemma(xs[..|xs|-1], sum_xs[..|xs|-1], ys[..|xs|-1], sum_ys[..|xs|-1]);
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
