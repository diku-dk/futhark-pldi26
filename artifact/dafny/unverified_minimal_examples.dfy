/*
 * Data-parallel programming idioms that don't verify.
 *
 */
include "soacs.dfy"

module MinimalExample {
  import opened SOACs

  // Minimal example: Dafny cannot relate inclusive and exclusive scans.
  // This is necessary in, for example, mk_flag_array where an exclusive scan is
  // used in the body, but the size of the output array is the inclusive sum.
  method scan_rotation_equivalence(xs: seq<int>) returns (result: bool)
    requires |xs| > 0
    requires forall i :: 0 <= i < |xs| ==> xs[i] >= 0
    ensures result
  {
    var n := |xs|;
    var iota := seq(n, i => i);
    var xs_rotated := fmap(i => if 1 <= i < n then xs[i-1] else 0, iota);

    var scan_inc := scan((x,y) => x + y, 0, xs);
    var scan_exc := scan((x,y) => x + y, 0, xs_rotated);

    // Help Dafny see the relation between xs_rotated and xs (these verify).
    assert xs_rotated[0] == 0;
    assert forall i :: 1 <= i < n ==> xs_rotated[i] == xs[i-1];
    assert forall i :: 1 <= i < n ==> scan_exc[i] == xs[i-1] + scan_exc[i-1];
    assert forall i :: 1 <= i < n ==> scan_inc[i] == xs[i] + scan_inc[i-1];

    // None of these verify:
    assert scan_inc[n-1] == scan_exc[n-1] + xs[n-1];
    assert forall i :: 1 <= i < n ==> scan_exc[i] == scan_inc[i-1];

    result := scan_inc[n-1] == scan_exc[n-1] + xs[n-1];
  }

  // This reasoning is required in each segment of segment_ids.
  method replicate_by_scan(n: int) returns (ys: seq<int>)
    requires n > 0
  {
    var xs := [1] + seq(n-1, _ => 0);
    ys := scan((x,y) => x + y, 0, xs);

    // Help Dafny (these verify).
    assert ys[0] == 1;
    assert forall i :: 1 <= i < n ==> ys[i] == 0 + ys[i-1];

    // Dafny can't verify:
    assert forall i :: 0 <= i < n ==> ys[i] == 1;
  }
}
