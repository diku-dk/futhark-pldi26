#!/usr/bin/env janet

# Main artifact evaluation script.
# Reproduces Fig 14 from "Verifying Array Properties in Pure Data-Parallel Programs".
#
# Usage inside Docker container:
#   janet bench.janet            # full evaluation
#   janet bench.janet --skip-perf  # verification table only (no GPU needed)

(import ./util)

(def usage
  ``
  Usage: janet bench.janet [options]

    --futhark-dir <path>: Path to futhark-PropProp directory (default: futhark-PropProp)
    --perf-dir <path>:    Path to perf-tests directory
                          (default: perf-tests)
    --data <path>:        Directory to save raw benchmark data (default: data)
    --results <path>:     Directory to save generated tables (default: results)
    --runs <n>:           Number of timed runs for verification benchmarks (default: 1)
    --backend <b>:        Futhark backend for compile-time baseline (default: cuda)
    --skip-verify:        Skip verification timing benchmarks
    --skip-perf:          Skip GPU performance benchmarks (use if no GPU available)
    --skip-kmeans:        Skip kmeans GPU benchmarks (e.g. if datasets unavailable)
    --skip-partition:     Skip partition2 GPU benchmarks
    --pdf:                Compile generated .tex to PDF (requires latexmk)
    --help:               Print this usage information.
  ``)

(defn main [& args]
  (def rest (slice args 1))
  (when (find-index |(= $ "--help") rest)
    (print usage)
    (os/exit 0))

  (util/check-unknown-args rest
    ["--futhark-dir" "--perf-dir" "--data" "--results" "--runs" "--backend"
     "--skip-verify" "--skip-perf" "--skip-kmeans" "--skip-partition" "--pdf" "--help"])

  (def futhark-dir   (or (util/get-arg "--futhark-dir" rest false) "futhark-PropProp"))
  (def perf-dir      (or (util/get-arg "--perf-dir" rest false) "perf-tests"))
  (def data-path     (or (util/get-arg "--data"    rest false) "data"))
  (def results-path  (or (util/get-arg "--results" rest false) "results"))
  (def runs          (or (util/get-arg "--runs"    rest false) "1"))
  (def backend
    (or (util/get-arg "--backend" rest false)
        (let [has-cuda (= 0 (os/execute ["sh" "-c" "which nvcc > /dev/null 2>&1"] :p))]
          (if has-cuda "cuda"
            (do (eprint "Note: nvcc not found; using 'c' backend for compile-time baseline (% Compile will differ from paper).")
                "c")))))
  (def skip-verify?  (find-index |(= $ "--skip-verify")    rest))
  (def skip-perf?    (find-index |(= $ "--skip-perf")      rest))
  (var skip-kmeans?  (find-index |(= $ "--skip-kmeans")    rest))
  (def skip-part?    (find-index |(= $ "--skip-partition") rest))
  (def pdf?          (find-index |(= $ "--pdf")            rest))

  (util/mkdirp data-path)
  (util/mkdirp results-path)

  (unless skip-verify?
    (util/run ["janet" "verify.janet"
               "--futhark-dir" futhark-dir
               "--output"      data-path
               "--runs"        runs
               "--backend"     backend]))

  (unless skip-perf?
    (def kmeans-data-dir (string perf-dir "/kmeans-sparse/data"))
    (def kmeans-probe    (string kmeans-data-dir "/movielens.in.gz"))
    (def has-kmeans-data? (os/stat kmeans-probe))
    (when (and (not skip-kmeans?) (not has-kmeans-data?))
      (eprint "Note: kmeans datasets not found in " kmeans-data-dir ".")
      (eprint "      Skipping kmeans benchmarks. See artifact/README.md for how to add them.")
      (set skip-kmeans? true))
    (def perf-cmd
      @["janet" "perf.janet"
        "--perf-dir" perf-dir
        "--output"   data-path])
    (when skip-kmeans?    (array/push perf-cmd "--skip-kmeans"))
    (when skip-part?      (array/push perf-cmd "--skip-partition"))
    (util/run perf-cmd))

  (def table-cmd
    @["janet" "table.janet"
      "--verify" data-path
      "--perf"   data-path
      "--output" results-path])
  (when pdf? (array/push table-cmd "--pdf"))
  (util/run table-cmd))
