# Verifying data-parallel programming in Dafny

This directory contains a small framework of Second-Order Array Combinators
and example data-parallel-style programs in Dafny.

- `soacs.dfy`: Defines/specifies Second-Order Array Combinators (SOACs).
- `sec1/`: Programs that Dafny can successfully verify via manual proofs.
- `sec2/`: Programs that Dafny cannot verify, even with substantial manual guidance and lemmas.
- `sec3/`: Programs highlighting the difficulty of verifying scatter.
- `unverified_minimal_examples.dfy`: Minimal examples essential to data-parallel programming that Dafny cannot automatically verify.

## Expected Results

- `soacs.dfy` and programs in `sec1/` should verify successfully.
- Programs in `sec2/`, `sec3/`, and `unverified_minimal_examples.dfy` should fail to verify.

`failed` is the correct outcome for programs expected to fail.

## Running

Use `dafny.janet` from the artifact root (recommended); run with `--help` to
see all options including a custom per-condition timeout:

```
$ janet dafny.janet
```

Or run individual files manually with `dafny verify`; use
`--verification-time-limit` to set a per-condition timeout.

## Experimental Setup

Dafny version 4.10.0.
