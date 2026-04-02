#!/usr/bin/env janet

# Runs GPU performance benchmarks for Fig 14 (right table).
# Requires futhark with a GPU backend and appropriate datasets.
# For kmeans, datasets must be present in perf-dir/kmeans-sparse/data/.
# See perf-tests/README for details.

(import ./util)

(def usage
  ``
  Usage: janet perf.janet [--perf-dir <path>] [--output <path>] [--backend <b>] [--skip-kmeans] [--skip-partition] [--help]

    --perf-dir:       Path to the perf-tests directory
                      (default: perf-tests)
    --output:         Directory to save results (default: current directory)
    --backend:        Futhark GPU backend to use: cuda or c (default: cuda)
    --skip-kmeans:    Skip kmeans benchmarks (e.g. if datasets are unavailable)
    --skip-partition: Skip partition2 benchmarks
    --help:           Print this usage information.
  ``)

(defn parse-bench-output [fut-name output]
  # Parse futhark bench text output. Returns @{"entrypoint\tdataset" mean-us}
  # futhark bench prints lines like:
  #   progname.fut:entrypoint:        <- entry point header
  #   progname.fut (using x.tuning):  <- single-entry header
  #   dataset:     12345μs (95% CI: [...])  <- result line
  (def result @{})
  (var cur-entry fut-name)
  (each line (string/split "\n" output)
    (def trimmed (string/trim line))
    (cond
      (empty? trimmed) nil

      # Entry point / program header: ends with ":", contains ".fut", no μs
      (and (string/has-suffix? ":" trimmed)
           (string/find ".fut" trimmed)
           (not (string/find "μs" trimmed)))
      (let [base (if (string/find " (" trimmed)
                   (string/slice trimmed 0 (string/find " (" trimmed))
                   (string/slice trimmed 0 -2))]
        (set cur-entry (string/trim base)))

      # Dataset result line: contains μs
      (string/find "μs" trimmed)
      (let [colon-idx (string/find ":" trimmed)]
        (when colon-idx
          (let [ds      (string/trim (string/slice trimmed 0 colon-idx))
                after   (string/trim (string/slice trimmed (+ colon-idx 1)))
                mus-idx (string/find "μs" after)]
            (when mus-idx
              (let [toks (filter (complement empty?)
                                 (string/split " " (string/trim (string/slice after 0 mus-idx))))
                    num  (scan-number (last toks))]
                (when num
                  (put result (string cur-entry "\t" ds) num)))))))))
  result)

(defn run-futhark-bench [perf-dir subdir fut-file backend]
  (def full-dir (string perf-dir "/" subdir))
  (def [out exit-code]
    (util/run-output* ["futhark" "bench" (string "--backend=" backend) fut-file] full-dir))
  (when (not= exit-code 0)
    (eprintf "ERROR: futhark bench failed for %s:\n%s\n" fut-file out)
    (os/exit exit-code))
  (parse-bench-output fut-file out))

(defn bench-kmeans [perf-dir backend]
  # futhark bench looks for <program>.tuning automatically; copy the shared
  # tuning file to match each variant's expected name.
  (def kmeans-dir (string perf-dir "/kmeans-sparse"))
  (util/run ["sh" "-c"
             "cp -f k10-manual.fut.tuning k10-manual-dynamic.fut.tuning 2>/dev/null; cp -f k10-manual.fut.tuning k10-manual-static.fut.tuning 2>/dev/null; true"]
            kmeans-dir)
  (printf "Benchmarking kmeans (dynamic)...\n")
  (def dyn-data    (run-futhark-bench perf-dir "kmeans-sparse" "k10-manual-dynamic.fut" backend))
  (printf "Benchmarking kmeans (static)...\n")
  (def static-data (run-futhark-bench perf-dir "kmeans-sparse" "k10-manual-static.fut" backend))
  # Merge: find matching datasets
  (def result @{})
  (each [k v] (pairs dyn-data)
    (def ds (get (string/split "\t" k) 1))
    (def ds-short
      (cond
        (string/find "movielens" ds) "movielens"
        (string/find "nytimes"   ds) "nytimes"
        (string/find "scrna"     ds) "scrna"
        ds))
    (var static-mean nil)
    (each [sk sv] (pairs static-data)
      (when (= ds (get (string/split "\t" sk) 1))
        (set static-mean sv)))
    (put result ds-short @{:dyn v :static static-mean}))
  result)

(defn bench-partition2 [perf-dir backend]
  (printf "Benchmarking partition2...\n")
  (def data (run-futhark-bench perf-dir "partition2" "partition2.fut" backend))
  (def result @{})
  (each [k v] (pairs data)
    (def parts (string/split "\t" k))
    (def prog (parts 0))
    (def ds   (parts 1))
    (def variant
      (cond
        (string/find "dynamicChecked" prog) :dyn
        (string/find "staticChecked"  prog) :static
        (string/find "staticWithOpt"  prog) :static-opt
        nil))
    (def size
      (cond
        (string/find "50000000"  ds) "50M"
        (string/find "100000000" ds) "100M"
        (string/find "200000000" ds) "200M"
        ds))
    (when (and variant size)
      (when (nil? (result size)) (put result size @{}))
      (put (result size) variant v)))
  result)

(defn save-results [kmeans partition2 output-path]
  (util/mkdirp output-path)
  (def data @{:kmeans kmeans :partition2 partition2})
  (def filename (string output-path "/perf-" (util/mk-timestamp) ".jdn"))
  (spit filename (string/format "%j" data))
  (printf "Results saved to %s\n" filename))

(defn main [& args]
  (def rest (slice args 1))
  (when (find-index |(= $ "--help") rest)
    (print usage)
    (os/exit 0))
  (util/check-unknown-args rest ["--perf-dir" "--output" "--backend" "--skip-kmeans" "--skip-partition" "--help"])

  (def perf-dir
    (os/realpath
      (or (util/get-arg "--perf-dir" rest false)
          "perf-tests")))
  (def output-path     (or (util/get-arg "--output"  rest false) "."))
  (def backend         (or (util/get-arg "--backend" rest false) "cuda"))
  (def skip-kmeans?    (find-index |(= $ "--skip-kmeans")    rest))
  (def skip-partition? (find-index |(= $ "--skip-partition") rest))

  (def kmeans    (if skip-kmeans?    @{} (bench-kmeans     perf-dir backend)))
  (def partition (if skip-partition? @{} (bench-partition2  perf-dir backend)))
  (save-results kmeans partition output-path))
