#!/usr/bin/env janet

# Runs Dafny verification for Section 2 programs.
# Programs in soacs.dfy and sec1/ should succeed; sec2/, sec3/, and
# unverified_minimal_examples.dfy are expected to fail.

(import ./util)

(def usage
  ``
  Usage: janet dafny.janet [--dafny-dir <path>] [--timeout <seconds>] [--help]

    --dafny-dir: Path to the dafny directory (default: dafny)
    --timeout:   Per-condition verification time limit in seconds (default: 120)
    --help:      Print this usage information.
  ``)

# [file, expected-to-verify?]
(def programs
  [["soacs.dfy"                                          true]
   ["sec1/partition_inds.dfy"                           true]
   ["sec1/partition_inds_verbose.dfy"                   true]
   ["sec2/exclusive_prefix_sum.dfy"                     false]
   ["sec2/partition_inds_rev_scan.dfy"                  false]
   ["sec2/partition_inds_rev_scan_verbose.dfy"          false]
   ["sec3/partition.dfy"                                false]
   ["sec3/partition_gather_sigma.dfy"                   false]
   ["sec3/partition_gather_sigma_guided_version.dfy"    false]
   ["sec3/partition_gather_sigma_inj.dfy"               false]
   ["unverified_minimal_examples.dfy"                   false]])

# Dafny exit code 4 means verification timed out.
(defn run-dafny [dafny-dir file timeout]
  (def [_ exit-code] (util/run-output* ["dafny" "verify" "--verification-time-limit" (string timeout) file] dafny-dir))
  (cond
    (= exit-code 0) :verified
    (= exit-code 4) :timeout
    :failed))

(defn main [& args]
  (def rest (slice args 1))
  (when (find-index |(= $ "--help") rest)
    (print usage)
    (os/exit 0))
  (util/check-unknown-args rest ["--dafny-dir" "--timeout" "--help"])

  (def dafny-dir
    (os/realpath (or (util/get-arg "--dafny-dir" rest false) "dafny")))
  (def timeout
    (scan-number (or (util/get-arg "--timeout" rest false) "120")))

  (var all-ok true)
  (each [file expected?] programs
    (printf "%-52s " file)
    (flush)
    (def result (run-dafny dafny-dir file timeout))
    (def verified? (= result :verified))
    # timeouts count as failures (not verified), so they satisfy expected-to-fail
    (def ok? (= verified? expected?))
    (unless ok? (set all-ok false))
    (printf "%s  (expected: %s)%s\n"
      (match result
        :verified "verified"
        :timeout  "timeout "
        :failed   "failed  ")
      (if expected? "verify" "fail  ")
      (if ok? "" "  *** UNEXPECTED")))

  (print "")
  (if all-ok
    (print "All results match expectations.")
    (do (print "Some results were unexpected.")
        (os/exit 1))))
