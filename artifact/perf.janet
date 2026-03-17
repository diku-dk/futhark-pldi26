#!/usr/bin/env janet

# Runs GPU performance benchmarks for Fig 14 (right table).
# Requires futhark with a CUDA backend and appropriate datasets.
# For kmeans, datasets must be present in perf-dir/kmeans-sparse/data/.
# See artifact_tools/perf-tests/README for details.

(import ./util)

(def usage
  ``
  Usage: janet perf.janet [--perf-dir <path>] [--output <path>] [--skip-kmeans] [--skip-partition] [--help]

    --perf-dir:       Path to the perf-tests directory
                      (default: futhark-PropProp/artifact_tools/perf-tests)
    --output:         Directory to save results (default: current directory)
    --skip-kmeans:    Skip kmeans benchmarks (e.g. if datasets are unavailable)
    --skip-partition: Skip partition2 benchmarks
    --help:           Print this usage information.
  ``)

(defn parse-bench-json [json-file]
  # Parse futhark bench JSON output using Python.
  # Returns @{"entry:dataset" mean-runtime-us}
  (def py
    (string
      "import json, statistics\n"
      "data = json.load(open('" json-file "'))\n"
      "for prog, info in data.items():\n"
      "    for ds, vals in info['datasets'].items():\n"
      "        rts = vals.get('runtimes', [])\n"
      "        if rts:\n"
      "            print(prog + '\\t' + ds + '\\t' + str(statistics.mean(rts)))\n"))
  (def output (util/run-output ["python3" "-c" py]))
  (def result @{})
  (each line (string/split "\n" (string/trimr output))
    (unless (empty? line)
      (def parts (string/split "\t" line))
      (when (= (length parts) 3)
        (put result (string (parts 0) "\t" (parts 1)) (scan-number (parts 2))))))
  result)

(defn run-futhark-bench [perf-dir subdir fut-file json-file]
  (def full-dir (string perf-dir "/" subdir))
  (def json-path (string full-dir "/" json-file))
  (def [out exit-code]
    (util/run-output* ["futhark" "bench" "--backend=cuda"
                       (string "--json=" json-path) fut-file]
                      full-dir))
  (when (not= exit-code 0)
    (eprintf "ERROR: futhark bench failed for %s:\n%s\n" fut-file out)
    (os/exit exit-code))
  (parse-bench-json json-path))

(defn bench-kmeans [perf-dir]
  # futhark bench looks for <program>.tuning automatically; copy the shared
  # tuning file to match each variant's expected name.
  (def kmeans-dir (string perf-dir "/kmeans-sparse"))
  (util/run ["sh" "-c"
             "cp -f k10-manual.fut.tuning k10-manual-dynamic.fut.tuning 2>/dev/null; \
              cp -f k10-manual.fut.tuning k10-manual-static.fut.tuning  2>/dev/null; \
              true"]
            kmeans-dir)
  (printf "Benchmarking kmeans (dynamic)...\n")
  (def dyn-data
    (run-futhark-bench perf-dir "kmeans-sparse" "k10-manual-dynamic.fut" "kmeans-dynamic.json"))
  (printf "Benchmarking kmeans (static)...\n")
  (def static-data
    (run-futhark-bench perf-dir "kmeans-sparse" "k10-manual-static.fut"  "kmeans-static.json"))
  # Merge: find matching datasets
  (def result @{})
  (each [k v] (pairs dyn-data)
    (def parts (string/split "\t" k))
    (def ds (parts 1))
    (def ds-short
      (cond
        (string/find "movielens" ds) "movielens"
        (string/find "nytimes"   ds) "nytimes"
        (string/find "scrna"     ds) "scrna"
        ds))
    # Find matching static entry by comparing dataset component
    (var static-mean nil)
    (each [sk sv] (pairs static-data)
      (def sk-parts (string/split "\t" sk))
      (when (= ds (get sk-parts 1))
        (set static-mean sv)))
    (put result ds-short @{:dyn v :static static-mean}))
  result)

(defn bench-partition2 [perf-dir]
  (printf "Benchmarking partition2...\n")
  (def data
    (run-futhark-bench perf-dir "partition2" "partition2.fut" "partition2.json"))
  # Extract entries by variant and dataset size
  (def result @{})
  (each [k v] (pairs data)
    (def parts (string/split "\t" k))
    (def prog (parts 0))
    (def ds   (parts 1))
    (def variant
      (cond
        (string/find "dynamicChecked"  prog) :dyn
        (string/find "staticChecked"   prog) :static
        (string/find "staticWithOpt"   prog) :static-opt
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
  (def perf-dir
    (os/realpath
      (or (util/get-arg "--perf-dir" rest false)
          "futhark-PropProp/artifact_tools/perf-tests")))
  (def output-path     (or (util/get-arg "--output" rest false) "."))
  (def skip-kmeans?    (find-index |(= $ "--skip-kmeans")    rest))
  (def skip-partition? (find-index |(= $ "--skip-partition") rest))

  (def kmeans    (if skip-kmeans?    @{} (bench-kmeans    perf-dir)))
  (def partition (if skip-partition? @{} (bench-partition2 perf-dir)))
  (save-results kmeans partition output-path))
