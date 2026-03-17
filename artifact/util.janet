(defn mkdirp [path]
  (var cur "")
  (each part (string/split "/" path)
    (set cur (if (= cur "") part (string cur "/" part)))
    (when (and (not= cur "") (not (os/stat cur)))
      (os/mkdir cur))))

(defn get-args [flag rest]
  (def idx (find-index |(= $ flag) rest))
  (if (not idx)
    @[]
    (let [after (slice rest (+ idx 1))
          end (or (find-index |(string/has-prefix? "--" $) after) (length after))]
      (slice after 0 end))))

(defn get-arg [flag rest &opt required usage]
  (default required true)
  (def value (first (get-args flag rest)))
  (when (and required (nil? value))
    (eprintf "Error: %s is required\n" flag)
    (when usage (eprintf "%s\n" usage))
    (os/exit 1))
  value)

(defn run [cmd &opt cwd]
  (def original (os/cwd))
  (when cwd (os/cd cwd))
  (def exit-code (os/execute cmd :p))
  (when cwd (os/cd original))
  (unless (= exit-code 0)
    (eprintf "ERROR: command failed with exit code %d\n" exit-code)
    (os/exit exit-code)))

(defn time-run [cmd &opt cwd]
  (def t0 (os/clock))
  (run cmd cwd)
  (- (os/clock) t0))

(defn time-run* [cmd &opt cwd]
  # Like time-run but returns [elapsed-seconds success?] without exiting on failure.
  (def original (os/cwd))
  (when cwd (os/cd cwd))
  (def t0 (os/clock))
  (def exit-code (os/execute cmd :p))
  (def elapsed (- (os/clock) t0))
  (when cwd (os/cd original))
  [elapsed (= exit-code 0)])

(defn run-output* [cmd &opt cwd]
  # Like run-output but returns [output exit-code] without exiting on failure.
  (def original (os/cwd))
  (when cwd (os/cd cwd))
  (def tmpfile "/tmp/janet-cmd-output.txt")
  (def shell-str (string (string/join (map string cmd) " ") " > " tmpfile " 2>&1"))
  (def exit-code (os/execute ["sh" "-c" shell-str] :p))
  (def result (slurp tmpfile))
  (when cwd (os/cd original))
  [result exit-code])

(defn run-output [cmd &opt cwd]
  (def [result exit-code] (run-output* cmd cwd))
  (unless (= exit-code 0)
    (def shell-str (string/join (map string cmd) " "))
    (eprintf "ERROR: command failed: %s\n" shell-str)
    (eprintf "%s\n" result)
    (os/exit exit-code))
  result)

(defn mk-timestamp []
  (def t (os/date))
  (string/format "%04d%02d%02d-%02d%02d%02d"
    (t :year) (t :month) (t :month-day)
    (t :hours) (t :minutes) (t :seconds)))
