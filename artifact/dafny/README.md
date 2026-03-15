# Verifying data-parallel programming in Dafny

This directory contains a small framework of Second-Order Array Combinators
and example data-parallel-style programs in Dafny.

- `soacs.dfy`: Defines/specifies Second-Order Array Combinators (SOACs).
- `sec1/`: Programs discussed in subsection 1. Programs that Dafny can successfully verify via manual proofs.
- `sec2/`: Programs discussed in subsection 2. Alternative definitions of programs and additional programs that we were unable to verify in Dafny---even with substantial manual guidance/lemmas.
- `sec3/`: Programs discussed in subsection 3. Highlights the difficulty of verifying scatter and the core reason for this.
- `unverified_minimal_examples.dfy`: Minimal examples, essential to data-parallel programming, that Dafny can't automatically verify.

To verify the Dafny files, run:

```bash
dafny verify soacs.dfy
dafny verify sec1/partition_inds.dfy
...
dafny verify unverified_minimal_examples.dfy
```

The verification time limit can be increased with the `--verification-time-limit` flag.

## Expected Results

- `soacs.dfy` and programs in `sec1/` should verify successfully.
- Programs in `sec2/`, `sec3/` and `unverified_minimal_examples.dfy` should fail to verify.

## Experimental Setup

We used Dafny version 4.10.0.
