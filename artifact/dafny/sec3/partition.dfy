// Program discussed in Section 3.3.
include "../soacs.dfy"
include "../sec3.1/partition_inds.dfy"
import opened SOACs


method partition(p: int -> bool, xs: seq<int>) returns (split: int, ys: seq<int>)
{
    var inds;
    split, inds := partition_inds(p, xs);
    var dest := seq(|xs|, i requires 0 <= i < |xs| => 0);
    ys := scatter(dest, inds, xs);
    
    assert (forall i :: 0 <= i < split ==> p(ys[i]));
    assert (forall i :: split <= i < |xs| ==> !p(ys[i]));
}

