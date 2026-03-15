/*
 * Second-Order Array Combinators (SOACs) for data-parallel-style programming.
 *
 */
module SOACs {
  function fmap<T1,T2>(f: T1 -> T2, xs: seq<T1>): (ys: seq<T2>)
    ensures |xs| == |ys|
    ensures forall i :: 0 <= i < |xs| ==> ys[i] == f(xs[i])
  {
    seq(|xs|, i requires 0 <= i < |xs| => f(xs[i]))
  }

  function map2<T1,T2,T3>(f: (T1,T2) -> T3, xs: seq<T1>, ys: seq<T2>): (vs: seq<T3>)
    requires |xs| == |ys|
    ensures |xs| == |vs|
    ensures forall i :: 0 <= i < |xs| ==> vs[i] == f(xs[i], ys[i])
  {
    seq(|xs|, i requires 0 <= i < |xs| => f(xs[i], ys[i]))
  }

  function map3<T1,T2,T3,T4>(f: (T1,T2,T3) -> T4, xs: seq<T1>, ys: seq<T2>, zs: seq<T3>): (vs: seq<T4>)
    requires |xs| == |ys| == |zs|
    ensures |xs| == |vs|
    ensures forall i :: 0 <= i < |xs| ==> vs[i] == f(xs[i], ys[i], zs[i])
  {
    seq(|xs|, i requires 0 <= i < |xs| => f(xs[i], ys[i], zs[i]))
  }

  function zip<T1,T2>(xs: seq<T1>, ys: seq<T2>): (zs: seq<(T1,T2)>)
    requires |xs| == |ys|
    ensures |xs| == |zs|
    ensures forall i :: 0 <= i < |xs| ==> zs[i] == (xs[i], ys[i])
  {
    seq(|xs|, i requires 0 <= i < |xs| => (xs[i], ys[i]))
  }

  function unzip<T1,T2>(zs: seq<(T1,T2)>): (result: (seq<T1>, seq<T2>))
    ensures |zs| == |result.0| == |result.1|
    ensures forall i :: 0 <= i < |zs| ==> zs[i] == (result.0[i], result.1[i])
  {
    (seq(|zs|, i requires 0 <= i < |zs| => zs[i].0),
     seq(|zs|, i requires 0 <= i < |zs| => zs[i].1))
  }

  opaque function scan<T(!new)>(op: (T,T) -> T, ne: T, xs: seq<T>): (ys: seq<T>)
    requires monoid(op, ne)
    ensures |xs| == |ys|
    ensures |xs| == 0 ==> ys == []
    ensures forall i :: 0 <= i < |xs| ==>
      (i == 0 ==> ys[i] == op(ne, xs[0]))
      && (i > 0 ==> ys[i] == op(ys[i-1], xs[i]))
  {
    if |xs| == 0 then []
    else
      var prefix_scan := scan(op, ne, xs[..|xs|-1]);
      prefix_scan + [op(if |prefix_scan| == 0 then ne else prefix_scan[|prefix_scan|-1], xs[|xs|-1])]
  }

  method scatter<T>(ys: seq<T>, ids: seq<int>, vs: seq<T>) returns (zs: seq<T>)
    requires |ids| == |vs|
    requires injRCD_int(ids, 0, |ys|-1) || rep(vs)
    ensures |ys| == |zs|
    ensures forall k :: 0 <= k < |ids| && 0 <= ids[k] < |zs| ==> zs[ids[k]] == vs[k]
    ensures forall i :: 0 <= i < |zs| ==> ((exists k :: 0 <= k < |ids| && i == ids[k] && zs[i] == vs[k]) || zs[i] == ys[i])
  {
    var res := new T[|ys|](i requires 0 <= i < |ys| => ys[i]);
    var i := 0;
    while i < |ids|
      invariant 0 <= i <= |ids|
      invariant forall j :: 0 <= j < i && 0 <= ids[j] < res.Length ==> res[ids[j]] == vs[j]
      invariant forall j :: 0 <= j < res.Length ==> (exists k :: 0 <= k < i && j == ids[k] && res[j] == vs[k]) || res[j] == ys[j]
    {
      if 0 <= ids[i] < res.Length {
        res[ids[i]] := vs[i];
      }
      i := i + 1;
    }
    zs := res[..];
  }

  //
  // Utilities.
  //
  ghost predicate associative<T(!new)>(op: (T,T) -> T) {
    forall a, b, c :: op(a, op(b, c)) == op(op(a, b), c)
  }

  ghost predicate neutral_element<T(!new)>(op: (T,T) -> T, ne: T) {
    forall a :: op(a, ne) == op(ne, a) == a
  }

  ghost predicate monoid<T(!new)>(op: (T,T) -> T, ne: T) {
    associative(op) && neutral_element(op, ne)
  }

  predicate injRCD_int(xs: seq<int>, a: int, b: int)
  {
    forall i, j :: 0 <= i < j < |xs| && a <= xs[i] <= b && a <= xs[j] <= b ==> xs[i] != xs[j]
  }

  predicate inj<T(==)>(xs: seq<T>)
  {
    // forall i :: 0 <= i < xs.Length ==> multiset(xs[..])[xs[i]] == 1
    forall i, j :: 0 <= i < j < |xs| ==> xs[i] != xs[j]
  }

  predicate rep<T(==)>(xs: seq<T>)
  {
    forall i :: 0 <= i < |xs| ==> xs[0] == xs[i]
  }
}

