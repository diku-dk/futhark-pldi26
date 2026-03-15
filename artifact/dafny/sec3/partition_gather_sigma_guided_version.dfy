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

    assert (forall i :: 0 <= i < |xs| ==> 0 <= sigma[i] && sigma[i] < |xs|);

    assert (forall i :: 0 <= i < |xs| ==> sigma[inds[i]] == i);

    assert (forall i :: 0 <= i < |xs| ==> iota[i] >= 0 && iota[i] < |xs|);

    assert (forall i :: 0 <= i < |xs| ==> inds[sigma[i]] == i);

    ys := seq(|xs|, i requires 0 <= i < |xs| => xs[sigma[i]]);
    
    assert (forall i :: 0 <= i < split ==> p(ys[i]));
    assert (forall i :: split <= i < |xs| ==> !p(ys[i]));
}

