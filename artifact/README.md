# Artifact for *Verifying Array Properties in Pure Data-Parallel Programs*

This artifact includes an implementation of PropProp in the Futhark compiler,
reproduces Fig. 14 from the paper (modulo hardware-dependent timing values) and
provides the Dafny programs discussed in Section 2.

> **NOTE:** Since submission we have added additional verified programs
> (quickhull, bfs, lavaMD and srad); we include them in this version of the
> artifact.

## Requirements

- A system capable of running an x86-64 [Docker](https://docs.docker.com/get-docker/) image
- The artifact image `propprop.tar.gz`
- 6GB of RAM

Fig. 14 has two parts with different GPU requirements:

| Part                      | GPU                        | Notes                                                                             |
|---------------------------|----------------------------|---------------------------------------------------------------------------------- |
| Verification table (left) | None required              |                                                                                   |
| Performance table (right) | NVIDIA (CUDA, recommended) | Host driver supporting CUDA ≥ 13.0, NVIDIA container toolkit ≥ 1.18, ~8 GB VRAM  |

Note that even if CUDA and docker are installed, [NVIDIA container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/1.18.1/install-guide.html) might not be.

> Without any GPU, you can still reproduce the verification table by passing
> `--skip-perf` to `bench.janet`; see [Step-by-Step Instructions](#step-by-step-instructions).

**Authors' hardware:**

|     | Verification table        | Performance table             |
|-----|---------------------------|-------------------------------|
| OS  | macOS 26.3                | Linux                         |
| CPU | Apple M4                  | AMD EPYC 7352 24-Core         |
| RAM | 16 GB                     | 192 GB                        |
| GPU | None                      | NVIDIA A100                   |

---

## Getting Started Guide (Requires an NVIDIA GPU)

> The full evaluation completes in under 10 minutes on a modern consumer CPU and
> NVIDIA GPU.

Load and start the container:

```
$ docker load -i propprop.tar.gz
$ docker run --rm --device nvidia.com/gpu=all -it propprop:latest
```

Inside the container, run the full evaluation:

```
$ janet bench.janet
```

This produces `results/fig14-<timestamp>.{md,tex,pdf}` reproducing Fig. 14.
Follow [Retrieving results from the container](#retrieving-results-from-the-container)
or view the results immediately with `bat results/fig14-<timestamp>.md`. See the [Step-by-Step
Instructions](#step-by-step-instructions) below for no GPU
benchmarking, Dafny verification, and further details.

---

## Step-by-Step Instructions

All scripts accept `--help` for full options. The full evaluation runs
`futhark verify` on all 10 programs and (with a GPU) the performance benchmarks,
producing `results/fig14-<timestamp>.{md,tex,pdf}` (see [Output](#output)).

### Starting the container

Start the container with the appropriate flags for your GPU:

| GPU                  | `docker run` command                                                                                                     |
|----------------------|--------------------------------------------------------------------------------------------------------------------------|
| NVIDIA (recommended) | `docker run --rm --device nvidia.com/gpu=all -it propprop:latest`                                                        |
| None                 | `docker run --rm -it propprop:latest`                                                                                    |

### Running the evaluation

Inside the container, run `bench.janet` with the appropriate options:

| GPU    | Command                              | Produces                                   |
|--------|--------------------------------------|--------------------------------------------|
| NVIDIA | `janet bench.janet`                  | Both tables of Fig. 14                     |
| None   | `janet bench.janet --skip-perf`      | Verification table only (left of Fig. 14) |

### Dafny programs (Section 2, ~10 min)

Section 2 compares PropProp against Dafny. The `dafny/` directory contains the
programs: `soacs.dfy` and `sec1/` should verify; `sec2/`, `sec3/`, and
`unverified_minimal_examples.dfy` should fail.

```
$ janet dafny.janet
```

Each program has a 120-second per-condition time limit (override with
`--timeout <seconds>`). `failed` is the correct outcome for programs expected
to fail. See `dafny/README.md` for details.

---

## Output

`bench.janet` produces two directories:

* `data/`: raw benchmark data
  * `verify-<timestamp>.jdn`: per-program verification and compile times
  * `perf-<timestamp>.jdn`: GPU runtimes in microseconds
* `results/`: generated tables
  * `fig14-<timestamp>.{md,tex,pdf}`: Fig. 14 in Markdown, LaTeX, and PDF formats

> **Note:** Values for the columns "Properties & Annotations", "#S" and "#A" in
> Fig. 14 are hardware independent and are not collected automatically. Instead
> they are manually read off the source programs and are hardcoded in the
> table-generating script. Automating this would require an outsized amount of
> work and/or be brittle.

### Retrieving results from the container

Requirement: The container must be running.

```
$ docker ps   # get container ID
$ docker cp <container-id>:/artifact/results/<file> <destination>
```

For example, to copy the PDF rendering of Fig. 14 to the current directory:

```
$ docker cp <container-id>:/artifact/results/fig14-20260317-123456.pdf .
```

---

## Running individual scripts

Each script can also be run independently:

```
$ janet verify.janet  --help  # verification timing only
$ janet perf.janet    --help  # GPU benchmarks only
$ janet table.janet   --help  # regenerate table from existing .jdn files
$ janet dafny.janet   --help  # Dafny verification only
```

---

## Running outside Docker

Requirements:

* [Janet](https://janet-lang.org/)
* `futhark` on `PATH` (the modified compiler from `futhark-PropProp/`)
* `latexmk` (for PDF output)
* NVIDIA GPU + CUDA toolkit (for performance benchmarks)
* [Dafny 4.10.0](https://github.com/dafny-lang/dafny/releases) (for `dafny.janet`)

---

## Reusability Guide

### Running PropProp on new Futhark programs

The modified compiler accepts any Futhark program. To verify a new program, add
property annotations and run:

```
$ futhark verify myprogram.fut
```

The programs in `futhark-PropProp/tests/indexfn/` serve as examples of annotated
programs.

### Property annotation language

Properties are written as annotations on function parameter types and return
values using curly-brace syntax:

```futhark
def f
  (n: {i64 | \x -> Range x (0,inf)})
  (offsets: {[n+1]i64 | \x -> Range x (0,inf) && Monotonic (<=) x})
  : { [n]i64 | \ys -> For ys (\i -> Range ys (0,offsets[i+1])) }
  = ...
```

The expression after `|` is a predicate `\v -> P v` where `P` is a conjunction of the predefined properties listed below using `&&`.
For example,  `(offsets: {[n+1]i64 | \x -> Range x (0,inf) && Monotonic (<=) x})` says that offsets has both a range and a monotonicity property.

| Property                             | Meaning                                                                                              |
|--------------------------------------|------------------------------------------------------------------------------------------------------|
| `Range x (lo, hi)`                   | Every element of `x` lies in `[lo, hi)`. Use `inf` for an unbounded upper bound.                     |
| `Monotonic r x`                      | `x` is ordered by relation `r` (e.g. `(<=)` or `(<)`).                                               |
| `Equiv x y`                          | `x` and `y` have equal length and identical elements.                                                |
| `Injective x`                        | All elements of `x` are distinct (no codomain restriction).                                          |
| `InjectiveRCD x (lo, hi)`            | Elements of `x` falling in `[lo, hi)` are distinct; RCD = Restricted CoDomain (paper: `Inj x Y`).    |
| `BijectiveRCD x (lo, hi) (lo', hi')` | Elements of `x` falling in `[lo, hi)` biject onto `[lo', hi')` (paper: `Bij x Y Z`).                 |
| `FiltPart X Y pf pp`                 | `X` equals `Y` filtered by `pf` and 2-way partitioned by `pp`.                                       |
| `FiltPart2 X Y pf pp1 pp2`           | `X` equals `Y` filtered by `pf` and 3-way partitioned by `pp1`, `pp2`.                               |
| `FiltPartInv X pf pp`                | Index array `X` permutes its filtered domain with a 2-way partition (for scatter).                   |
| `FiltPartInv2 X pf pp1 pp2`          | Same as `FiltPartInv` but with a 3-way partition.                                                    |

See Fig. 7 in the paper for the formal proof obligations of the properties.

For information on Futhark itself, please see the [Futhark
website](https://futhark-lang.org), which includes extensive
[documentation](https://futhark-lang.org/docs.html) including a [user guide](https://futhark.readthedocs.io/en/stable/) and a [book](https://futhark-book.readthedocs.io/en/latest/) on parallel programming
in Futhark.

---

## Manifest

* `bench.janet`: Main orchestration script.
* `verify.janet`: Benchmarks `futhark verify` check time for each program.
* `perf.janet`: Runs GPU performance benchmarks for `kmeans_ker` and `partition2`.
* `table.janet`: Generates Fig. 14 as Markdown, LaTeX, and PDF.
* `dafny.janet`: Runs Dafny verification for Section 2 programs.
* `util.janet`: Shared utility functions.
* `futhark-PropProp/`: The modified Futhark compiler (Haskell/Cabal project). See folders `futhark-PropProp/src/Futhark/SoP` and `futhark-PropProp/src/Futhark/Analysis/Properties`.
* `perf-tests/`: Futhark benchmark programs for performance evaluation.
* `dafny/`: Dafny programs for Section 2.

> **Note:** The artifact scripts (`*.janet`), this README, and the Docker
> container (`docker.nix`) were developed with AI assistance.
