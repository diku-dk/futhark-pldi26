#!/usr/bin/env janet

# Benchmarks verification time for the programs in Fig 14 (left table).
# Runs `futhark verify` (type check + property analysis) and subtracts
# `futhark check` (type check only) to isolate property-analysis time.
# Also runs `futhark cuda` on unannotated programs for compile-time baseline.

(import ./util)

(def usage
  ``
  Usage: janet verify.janet [--futhark-dir <path>] [--output <path>] [--runs <n>] [--backend <b>] [--help]

    --futhark-dir: Path to the futhark-PropProp directory (default: futhark-PropProp)
    --output:      Directory to save results (default: current directory)
    --runs:        Number of timed runs per program (default: 1)
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

(defn run-benchmarks [futhark-dir n backend]
  (def results @{})
  (each [key ann unann] programs
    (printf "Benchmarking %s ...\n" (string key))
    (def verify-times @[])
    (def check-times  @[])
    (def cuda-times   @[])
    (var safe true)
    (repeat n
      (def [vt ok] (util/time-run* ["futhark" "verify"  ann]   futhark-dir))
      (array/push verify-times vt)
      (unless ok (set safe false))
      (array/push check-times  (util/time-run ["futhark" "check"  unann] futhark-dir))
      (array/push cuda-times   (util/time-run ["futhark" backend  unann] futhark-dir)))
    (def verify-avg (mean verify-times))
    (def check-avg  (mean check-times))
    (def cuda-avg   (mean cuda-times))
    # Property-analysis time = verify - typecheck
    (def prop-time  (max 0 (- verify-avg check-avg)))
    (def total-time (+ prop-time cuda-avg))
    (def pct        (if (> total-time 0) (* 100 (/ prop-time total-time)) 0))
    (put results key
      @{:safe        safe
        :verify-avg  verify-avg
        :check-avg   check-avg
        :cuda-avg    cuda-avg
        :prop-time   prop-time
        :cuda-time   cuda-avg
        :pct         pct
        :runs        n}))
  results)

(defn save-results [results output-path n]
  (util/mkdirp output-path)
  (def filename (string output-path "/verify-" (util/mk-timestamp) "-n" n ".jdn"))
  (spit filename (string/format "%j" results))
  (printf "Results saved to %s\n" filename))

(defn main [& args]
  (def rest (slice args 1))
  (when (find-index |(= $ "--help") rest)
    (print usage)
    (os/exit 0))
  (util/check-unknown-args rest ["--futhark-dir" "--output" "--runs" "--backend" "--help"])

  (def futhark-dir (or (util/get-arg "--futhark-dir" rest false) "futhark-PropProp"))
  (def output-path (or (util/get-arg "--output"      rest false) "."))
  (def n           (scan-number (or (util/get-arg "--runs"    rest false) "1")))
  (def backend     (or (util/get-arg "--backend"     rest false) "cuda"))
  (def results (run-benchmarks (os/realpath futhark-dir) n backend))
  (save-results results output-path n))
