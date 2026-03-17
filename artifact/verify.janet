#!/usr/bin/env janet

# Benchmarks verification time for the programs in Fig 14 (left table).
# Runs `futhark verify` (type check + property analysis) and subtracts
# `futhark check` (type check only) to isolate property-analysis time.
# Also runs `futhark cuda` on unannotated programs for compile-time baseline.

(import ./util)

(def usage
  ``
  Usage: janet verify.janet [--futhark-dir <path>] [--output <path>] [--backend <b>] [--help]

    --futhark-dir: Path to the futhark-PropProp directory (default: futhark-PropProp)
    --output:      Directory to save results (default: current directory)
    --backend:     Futhark backend for compile-time baseline (default: cuda)
    --help:        Print this usage information.
  ``)

# Programs in Fig 14 order: [key, annotated-path, unannotated-path]
(def programs
  [[:max-match    "tests/indexfn/maxMatch_2d.fut"    "tests/indexfn/maxMatch_2d_unannotated.fut"]
   [:mis          "tests/indexfn/mis.fut"             "tests/indexfn/mis_unannotated.fut"]
   [:fft          "tests/indexfn/fft.fut"             "tests/indexfn/fft_unannotated.fut"]
   [:primes       "tests/indexfn/primes.fut"          "tests/indexfn/primes_unannotated.fut"]
   [:kmeans-ker   "tests/indexfn/kmeans_kernel.fut"   "tests/indexfn/kmeans_kernel_unannotated.fut"]
   [:partition    "tests/indexfn/partition.fut"       "tests/indexfn/partition_unannotated.fut"]
   [:partition3   "tests/indexfn/partition3.fut"      "tests/indexfn/partition3_unannotated.fut"]
   [:seg-part     "tests/indexfn/seg_partition.fut"   "tests/indexfn/seg_partition_unannotated.fut"]
   [:filter       "tests/indexfn/filter.fut"          "tests/indexfn/filter_unannotated.fut"]
   [:filter-irreg "tests/indexfn/filter_irreg.fut"    "tests/indexfn/filter_irreg_unannotated.fut"]])

(defn mean [xs]
  (/ (reduce + 0 xs) (length xs)))

(defn run-benchmarks [futhark-dir backend]
  (def results @{})
  (each [key ann unann] programs
    (printf "Benchmarking %s ...\n" (string key))
    (def [vt ok] (util/time-run* ["futhark" "verify"  ann]   futhark-dir))
    (def check-time  (util/time-run ["futhark" "check"  unann] futhark-dir))
    (def cuda-time   (util/time-run ["futhark" backend  unann] futhark-dir))
    # Property-analysis time = verify - typecheck
    (def prop-time  (max 0 (- vt check-time)))
    (def total-time (+ prop-time cuda-time))
    (def pct        (if (> total-time 0) (* 100 (/ prop-time total-time)) 0))
    (put results key
      @{:safe        ok
        :verify-avg  vt
        :check-avg   check-time
        :cuda-avg    cuda-time
        :prop-time   prop-time
        :cuda-time   cuda-time
        :pct         pct}))
  results)

(defn save-results [results output-path]
  (util/mkdirp output-path)
  (def filename (string output-path "/verify-" (util/mk-timestamp) ".jdn"))
  (spit filename (string/format "%j" results))
  (printf "Results saved to %s\n" filename))

(defn main [& args]
  (def rest (slice args 1))
  (when (find-index |(= $ "--help") rest)
    (print usage)
    (os/exit 0))
  (util/check-unknown-args rest ["--futhark-dir" "--output" "--backend" "--help"])

  (def futhark-dir (or (util/get-arg "--futhark-dir" rest false) "futhark-PropProp"))
  (def output-path (or (util/get-arg "--output"      rest false) "."))
  (def backend     (or (util/get-arg "--backend"     rest false) "cuda"))
  (def results (run-benchmarks (os/realpath futhark-dir) backend))
  (save-results results output-path))
