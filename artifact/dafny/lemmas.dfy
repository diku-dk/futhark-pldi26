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
    SumOverNonNegativesIsMonotonicLemma(xs[..|xs|-1], ys[..|xs|-1]);
    assert ys[|xs|-1] == xs[|xs|-1] + ys[|xs|-2];
  }
}
