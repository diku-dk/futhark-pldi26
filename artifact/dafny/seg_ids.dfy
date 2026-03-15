include "make_flags.dfy"
include "seg_sum.dfy"

// Conclusion for segment_ids
//
// The result cannot be verified---probably because we could not verify
// a description of make_flags' result (hence it's opaque to Dafny).
//
method segment_ids(shape: seq<int>) returns (ii: seq<int>)
  requires forall i :: 0 <= i < |shape| ==> shape[i] >= 0
  ensures |ii| == sum(shape)
  ensures
    var offsets := scan((x,y) => x + y, 0, shape);
    forall k :: 0 <= k < |shape| ==>
      forall i :: 0 <= i < shape[k] ==>
        ii[i + offsets[k] - shape[k]] == k
{
  var m := |shape|;
  var iota := seq(m, i requires 0 <= i < m => i);
  var flags1 := fmap(i => i + 1, iota);
  var flags := make_flags(shape, flags1);
  var flags_seg_id := fmap(f => if f == 0 then 0 else f-1, flags);
  var flags_bool := fmap(f => f > 0, flags);
  ii := segment_sum(flags_bool, flags_seg_id);
}
