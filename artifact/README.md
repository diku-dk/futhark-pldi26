# Artifact for the paper *Verifying Array Properties in Pure Data-Parallel Programs*

## Introduction

This artifact includes the Dafny programs discussed in Section 2.1
and reproduces Fig. 14 from Section 5 of the paper.

See the `./dafny` folder for further instructions on Section 2.1. The rest of
this readme pertains to the evaluation section.

## Hardware dependencies

**Fig. 14 left table (verification):** No GPU required. Any x86-64 machine is
sufficient. The check times will vary from the paper (measured on Apple M4) but
all other values are fixed properties of the programs.

**Fig. 14 right table (performance):** An NVIDIA GPU is required to reproduce
the performance numbers. Pass it through to the container with
`--device nvidia.com/gpu=all`. If no GPU is available, use `--skip-perf`
to produce only the left table.

For kmeans, the sparse datasets (movielens, nytimes, scrna) must be present in
`perf-tests/kmeans-sparse/data/`. They are **not
bundled** in the Docker image due to file size (~650 MB total). If missing,
`bench.janet` will automatically skip kmeans benchmarks with a notification.

To add the datasets, copy `movielens.in.gz`, `nytimes.in.gz`, and `scrna.in.gz`
(Futhark binary format, from
[diku-dk/futhark-ad](https://github.com/diku-dk/futhark-ad/tree/master/kmeans/kmeans-sparse/data))
into `perf-tests/kmeans-sparse/data/` and re-run.

## Getting started

The artifact takes the form of a Docker image `propprop.tar.gz`. Load it with:

```
$ docker load -i propprop.tar.gz
```

Run it (CPU only):

```
$ docker run --rm -it propprop:latest
```

With GPU passthrough:

```
$ docker run --rm --device nvidia.com/gpu=all -it propprop:latest
```

## Step-by-step instructions

Inside the container, run:

```
$ janet bench.janet
```

This produces Fig. 14 in `results/fig14-<timestamp>.{md,tex}`. With `--pdf` it
also compiles to PDF (requires latexmk in the image).

**Verification table only** (no GPU, ~5–10 min depending on machine):

```
$ janet bench.janet --skip-perf
```

**Full evaluation with GPU** (~5–10 min verification + GPU benchmark time):

```
$ janet bench.janet --pdf
```

**Multiple runs** (for more stable timing averages):

```
$ janet bench.janet --runs 3
```

### Retrieving results from the container

```
$ docker ps   # get container ID
$ docker cp <container-id>:/artifact/results/fig14-<timestamp>.pdf .
```

## Output

Running `bench.janet` creates two directories:

* `data/`: raw benchmark data as `.jdn` files (Janet Data Notation)
  * `verify-<timestamp>-n<n>.jdn`: per-program verification and compile times
  * `perf-<timestamp>.jdn`: GPU performance runtimes in microseconds
* `results/`: generated tables
  * `fig14-<timestamp>.md`: Markdown (human-readable)
  * `fig14-<timestamp>.tex`: LaTeX (for inclusion in the paper)
  * `fig14-<timestamp>.pdf`: rendered PDF (with `--pdf`)

## Interpretation

**Left table (verification):** Check times will differ from the paper (measured
on Apple M4) but should be in the same order of magnitude. The `% Compile`
column reflects the fraction of total compile time spent on property analysis;
this is machine-independent to a first approximation. All programs are verified
safe (✓).

**Right table (performance):** Speedup factors are hardware-dependent but should
be qualitatively consistent with the paper's results.

## Running individual scripts

Each Janet script can be run independently:

```
$ janet verify.janet --help   # verification timing only
$ janet perf.janet    --help  # GPU benchmarks only
$ janet table.janet   --help  # regenerate table from existing .jdn files
```

## Running outside Docker

Requirements:

* [Janet](https://janet-lang.org/) (the scripting language)
* `futhark` on `PATH` (the modified compiler from `futhark-PropProp/`)
* Python 3 (for JSON parsing in `perf.janet`)
* `latexmk` (optional, for PDF output)
* NVIDIA GPU + CUDA toolkit (optional, for performance benchmarks)

## Manifest

* `bench.janet`: Main orchestration script.
* `verify.janet`: Benchmarks verification check time for each program.
* `perf.janet`: Runs GPU performance benchmarks for kmeans and partition2.
* `table.janet`: Generates Fig. 14 as Markdown, LaTeX, and PDF.
* `util.janet`: Shared utility functions.
* `futhark-PropProp/`: The modified Futhark compiler (Haskell/Cabal project).
* `dafny/`: Dafny programs for Section 2.1.
