# Artifact for *Verifying Array Properties in Pure Data-Parallel Programs*

This artifact includes an implementation of PropProp in the Futhark compiler,
reproduces Fig. 14 from the paper (modulo hardware-dependent timing values) and
provides the Dafny programs discussed in Section 2.

> **Note:** The artifact scripts (`*.janet`), this README, and the Docker
> container (`docker.nix`) were developed with assistance from Anthropic's
> Claude.

## Requirements

### Software

- [Docker](https://docs.docker.com/get-docker/)
- The artifact image `propprop.tar.gz`

### Hardware

- A system capable of running an x86-64 Docker image
- For the verification table from Fig. 14: any machine (no GPU required)
- For the performance table from Fig. 14: an NVIDIA GPU (CUDA) or AMD GPU
  (OpenCL)
- Expected memory requirement: less than a few GB

> **Authors' hardware:**
>
> Verification table (left table of Fig. 14):
> macOS 26.3, Apple M4 CPU, 16 GB memory
>
> Performance table (right table of Fig. 14):
> Linux, 2× Intel Xeon 4410Y CPU, NVIDIA A100 GPU

---

## Getting Started Guide

The full evaluation completes in **under 10 minutes** on a modern NVIDIA GPU.

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
View the results with `bat results/fig14-<timestamp>.md`. See the
[Step-by-Step Instructions](#step-by-step-instructions) below for GPU variants,
running without a GPU, Dafny verification, and further details.

---

## Step-by-Step Instructions

All scripts accept `--help` for full options. The full evaluation runs
`futhark verify` on all 10 programs and (with a GPU) the performance benchmarks,
producing `results/fig14-<timestamp>.{md,tex,pdf}` (see [Output](#output)).

### OpenCL backend (AMD GPU, untested)

The artifact supports the `opencl` backend, which works with both AMD and NVIDIA
GPUs. For NVIDIA, CUDA is preferred and is what the paper's results were
obtained with; use OpenCL only if CUDA is unavailable. The artifact has not been
tested with AMD hardware. To use OpenCL with an AMD GPU, start the container
with AMD device passthrough:

```
$ docker run --rm --device=/dev/kfd --device=/dev/dri --group-add video --group-add render -it propprop:latest
```

Then inside the container:

```
$ janet bench.janet --backend opencl
```

### Verification only (no GPU, ~5 min)

To reproduce only the left table of Fig. 14 (verification results, no GPU required):

```
$ janet bench.janet --skip-perf
```

### Dafny programs (Section 2, ~5 min)

```
$ janet dafny.janet
```

See `dafny/README.md` for a description of the programs.

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
$ janet verify.janet --help   # verification timing only
$ janet perf.janet    --help  # GPU benchmarks only
$ janet table.janet   --help  # regenerate table from existing .jdn files
$ janet dafny.janet   --help  # Dafny verification only
```

---

## Running outside Docker

Requirements:

* [Janet](https://janet-lang.org/)
* `futhark` on `PATH` (the modified compiler from `futhark-PropProp/`)
* `latexmk` and a LaTeX distribution with `amssymb` (for PDF output)
* NVIDIA GPU + CUDA toolkit (for performance benchmarks)

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
