include "../soacs.dfy"
include "../sec3.1/partition_inds.dfy"
import opened SOACs


method partition(p: int -> bool, xs: seq<int>) returns (split: int, ys: seq<int>)
{
    var inds;
    split, inds := partition_inds(p, xs);
    var dest := seq(|xs|, i requires 0 <= i < |xs| => 0);
    
    var iota := seq(|xs|, i requires 0 <= i < |xs| => i);
    var sigma:= scatter (dest, inds, iota);


    ys := seq(|xs|, i requires 0 <= i < |xs| => xs[sigma[i]]);

    assert (forall i, j :: 0 <= i < j < |xs| ==> sigma[inds[i]] != sigma[inds[j]]);
    // Assertion fails. Have to assume:
    assert (forall i, j :: 0 <= i < j < |xs| ==> sigma[i] != sigma[j]);
    
    assert (forall i :: 0 <= i < split ==> p(ys[i]));
    assert (forall i :: split <= i < |xs| ==> !p(ys[i]));
}

