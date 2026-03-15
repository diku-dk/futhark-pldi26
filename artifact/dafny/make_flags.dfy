include "soacs.dfy"
include "lemmas.dfy"
import opened SOACs

function sum(xs: seq<int>): (y: int)
{
  var ys := scan((x,y) => x + y, 0, xs);
  if |ys| > 0 then ys[|ys|-1] else 0
}


// Conclusion for mk_flag_array
//
// Through a lemma+assertion, we're able to prove that the scattered indices
// are injective and hence the scatter may be applied. Trying to assert anything
// about the resulting array, however, causes time outs.
//
method make_flags(shape: seq<int>, xs: seq<int>) returns (ys: seq<int>)
  requires |shape| == |xs|
  requires forall i :: 0 <= i < |shape| ==> shape[i] >= 0
  // This causes time-out:
  ensures |xs| > 0 ==> |ys| == sum(shape)
  // This causes time-out:
  ensures
    var segment_ends := scan((x,y) => x + y, 0, shape);
    forall k :: 0 <= k < |shape| && segment_ends[k] <= |ys| ==>
      forall i :: 0 <= i < shape[k] && 0 <= i + segment_ends[k] - shape[k] < |ys| ==>
        (i == 0 ==> ys[i + segment_ends[k] - shape[k]] == xs[k])
        && (i > 0 ==> ys[i] == 0)
{
  var m := |xs|;
  var iota := seq(m, i requires 0 <= i < m => i);
  var shape_rot := fmap(i => if 1 <= i < m then shape[i-1] else 0, iota);
  var shape_scn := scan((x,y) => x + y, 0, shape_rot);
  var shape_ind := map2((shape, ind) => if shape <= 0 then -1 else ind, shape, shape_scn);

  // Needed to prove that n is positive.
  SumOverNonNegativesIsMonotonicLemma(shape_rot, shape_scn);
  // Needed to prove that shape_inds are unique.
  assert forall i :: 0 <= i < m - 1 && shape[i] > 0 ==> shape_rot[i+1] > 0;

  var n := if m > 0 then shape_scn[m-1] + shape[m-1] else 0;
  var zeros := seq(n, i => 0);
  ys := scatter(zeros, shape_ind, xs);
}
