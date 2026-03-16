#!/usr/bin/env janet

# Generates Fig 14 from the paper as Markdown, LaTeX, and optionally PDF.
# Reads verify .jdn (from verify.janet) and perf .jdn (from perf.janet).

(import ./util)

(def usage
  ``
  Usage: janet table.janet [--verify <path>] [--perf <path>] [--output <path>] [--pdf] [--help]

    --verify:  Path to a verify .jdn result file, or a directory from which
               the latest verify-*.jdn is used automatically.
    --perf:    Path to a perf .jdn result file, or a directory from which
               the latest perf-*.jdn is used automatically.
    --output:  Directory to save output files (default: current directory)
    --pdf:     Compile the generated .tex file to PDF after writing it.
    --help:    Print this usage information.
  ``)

# Loading
# ------------------------------------------------------------------------------
(defn latest-jdn [dir prefix]
  (def files
    (->> (os/dir dir)
         (filter (fn [f] (and (string/has-prefix? prefix f)
                              (string/has-suffix? ".jdn" f))))
         sort))
  (when (not (empty? files))
    (string dir "/" (last files))))

(defn load-jdn [path]
  (parse (slurp path)))

(defn resolve-path [path prefix]
  (if (= :directory ((os/stat path) :mode))
    (latest-jdn path prefix)
    path))

# Static metadata for Fig 14 (left table).
# Properties abbreviations: FP=FiltPart, InvFP=FiltPartInv, Inj=Injective,
#   Mono=Monotonic, FP2=FiltPart2, InvFP2=FiltPartInv2
# #S = number of scatter operations; #A = number of non-trivial annotations.
# All programs are Safe (they all verify successfully).
# ------------------------------------------------------------------------------
(def program-order
  [:max-match :mis :fft :primes :kmeans-ker
   :partition :partition3 :seg-part :filter :filter-irreg])

(def program-meta
  {:max-match    {:md "max_match"      :tex "max\\_match"      :properties "Inj, Range, FP, InvFP" :num-s 6  :num-a 18}
   :mis          {:md "MIS"            :tex "MIS"              :properties "Range, Mono"            :num-s 4  :num-a 20}
   :fft          {:md "FFT"            :tex "FFT"              :properties "Range"                  :num-s 1  :num-a 5}
   :primes       {:md "primes"         :tex "primes"           :properties "Range"                  :num-s 3  :num-a 18}
   :kmeans-ker   {:md "kmeans_ker"     :tex "kmeans\\_ker"     :properties "Range"                  :num-s 0  :num-a 7}
   :partition    {:md "partition"      :tex "partition"        :properties "FP"                     :num-s 1  :num-a 1}
   :partition3   {:md "partition3"     :tex "partition3"       :properties "FP, InvFP"              :num-s 1  :num-a 2}
   :seg-part     {:md "seg_partition"  :tex "seg\\_partition"  :properties "FP, InvFP, Range"       :num-s 2  :num-a 10}
   :filter       {:md "filter"         :tex "filter"           :properties "FP, InvFP"              :num-s 1  :num-a 2}
   :filter-irreg {:md "filter_irreg"   :tex "filter\\_irreg"   :properties "FP, InvFP, Range"       :num-s 2  :num-a 9}})

# Formatting helpers
# ------------------------------------------------------------------------------
(defn fmt-secs [n]
  (if n (string/format "%.1fs" n) "—"))

(defn fmt-pct [n]
  (if n (string/format "%d%%" (math/round n)) "—"))

(defn fmt-ms [us]
  # Convert microseconds to milliseconds, round to nearest integer
  (if us (string/format "%dms" (math/round (/ us 1000))) "—"))

(defn fmt-speedup [a b]
  # a/b speedup, e.g. dyn/static
  (if (and a b (> b 0))
    (string/format "%.1f\\times" (/ a b))
    "—"))

# Markdown rendering
# ------------------------------------------------------------------------------
(defn str-width [s] (count |(not= (band $ 0xC0) 0x80) s))

(defn pad-right [s w]
  (string s (string/repeat " " (- w (str-width s)))))

(defn mk-md-table [headers rows]
  (def col-widths
    (map (fn [i]
           (max (str-width (string (headers i)))
                (max ;(map (fn [r] (str-width (string (r i)))) rows))))
         (range (length headers))))
  (defn fmt-row [cells]
    (string "| "
      (string/join
        (map (fn [i] (pad-right (string (cells i)) (col-widths i)))
             (range (length cells)))
        " | ")
      " |"))
  (string/join
    [(fmt-row headers)
     (string "|" (string/join (map (fn [w] (string/repeat "-" (+ w 2))) col-widths) "|") "|")
     ;(map fmt-row rows)]
    "\n"))

(defn render-markdown-verify [verify]
  (defn v [key field] (get-in verify [key field]))
  (def headers ["Program" "Properties" "Safe" "#S" "#A" "Check time" "% Compile"])
  (def rows
    (map (fn [key]
           (def m (program-meta key))
           [(m :md)
            (m :properties)
            (if (get-in verify [key :safe]) "✓" "✗")
            (string (m :num-s))
            (string (m :num-a))
            (fmt-secs (v key :prop-time))
            (fmt-pct  (v key :pct))])
         program-order))
  (mk-md-table headers rows))

(defn render-markdown-perf [perf]
  (def kmeans    (get perf :kmeans    @{}))
  (def partition (get perf :partition2 @{}))
  (def headers ["Program" "Data" "Dyn." "Speedup (static)" "+Opt"])
  (def rows
    @[;(map (fn [ds]
              (def entry (get kmeans ds @{}))
              ["kmeans_ker" ds
               (fmt-ms (get entry :dyn))
               (fmt-speedup (get entry :dyn) (get entry :static))
               "—"])
            ["movielens" "nytimes" "scrna"])
      ;(map (fn [sz]
              (def entry (get partition sz @{}))
              ["partition2" sz
               (fmt-ms (get entry :dyn))
               (fmt-speedup (get entry :dyn) (get entry :static))
               (fmt-speedup (get entry :static) (get entry :static-opt))])
            ["50M" "100M" "200M"])])
  (mk-md-table headers rows))

(defn render-markdown [verify perf]
  (string
    "## Fig 14 (left): Verification results\n\n"
    (render-markdown-verify verify)
    "\n\n"
    "## Fig 14 (right): Performance results\n\n"
    (render-markdown-perf perf)
    "\n"))

# LaTeX rendering
# ------------------------------------------------------------------------------
(defn render-latex-verify [verify]
  (defn v [key field] (get-in verify [key field]))
  (def rows
    (map (fn [key]
           (def m (program-meta key))
           (string/format "  %s & %s & %s & %d & %d & %s & %s \\\\"
             (m :tex)
             (if (get-in verify [key :safe]) `$\checkmark$` `$\times$`)
             (m :properties)
             (m :num-s)
             (m :num-a)
             (fmt-secs (v key :prop-time))
             (fmt-pct  (v key :pct))))
         program-order))
  (string/join
    [`\begin{table}[t]`
     `  \small\centering`
     `  \caption{Evaluated programs. FP = FiltPart, InvFP = FiltPartInv, Inj = Injective, Mono = Monotonic.}`
     `  \begin{tabular}{l l c r r r r}`
     `  \toprule`
     `  Program & Properties & Safe & \#S & \#A & Check time & \% Compile \\`
     `  \midrule`
     ;rows
     `  \bottomrule`
     `  \end{tabular}`
     `  \label{tab:verify}`
     `\end{table}`]
    "\n"))

(defn render-latex-perf [perf]
  (def kmeans    (get perf :kmeans    @{}))
  (def partition (get perf :partition2 @{}))
  (def kmeans-rows
    (map (fn [ds]
           (def entry (get kmeans ds @{}))
           (string/format "  kmeans\\_ker & %s & %s & %s & --- \\\\"
             ds
             (fmt-ms (get entry :dyn))
             (fmt-speedup (get entry :dyn) (get entry :static))))
         ["movielens" "nytimes" "scrna"]))
  (def part-rows
    (map (fn [sz]
           (def entry (get partition sz @{}))
           (string/format "  partition2 & %s & %s & %s & %s \\\\"
             sz
             (fmt-ms (get entry :dyn))
             (fmt-speedup (get entry :dyn) (get entry :static))
             (fmt-speedup (get entry :static) (get entry :static-opt))))
         ["50M" "100M" "200M"]))
  (string/join
    [`\begin{table}[t]`
     `  \small\centering`
     `  \caption{Performance: dynamic vs.\ static verification. Speedup = dyn/static. +Opt = static/static+opt.}`
     `  \begin{tabular}{l l r r r}`
     `  \toprule`
     `  Program & Data & Dyn.\ (ms) & Speedup (static) & +Opt \\`
     `  \midrule`
     ;kmeans-rows
     `  \midrule`
     ;part-rows
     `  \bottomrule`
     `  \end{tabular}`
     `  \label{tab:perf}`
     `\end{table}`]
    "\n"))

(defn render-latex-document [verify perf]
  (string/join
    [`\documentclass{article}`
     `\usepackage{booktabs}`
     `\usepackage{amssymb}`
     `\begin{document}`
     (render-latex-verify verify)
     ""
     (render-latex-perf perf)
     `\end{document}`]
    "\n"))

# Main
# ------------------------------------------------------------------------------
(defn main [& args]
  (def rest (slice args 1))
  (when (or (find-index |(= $ "--help") rest) (empty? rest))
    (print usage)
    (os/exit 0))

  (def verify-arg (util/get-arg "--verify" rest false))
  (def perf-arg   (util/get-arg "--perf"   rest false))

  (unless (or verify-arg perf-arg)
    (eprintf "ERROR: at least one of --verify or --perf is required\n")
    (print usage)
    (os/exit 1))

  (def output-path (or (util/get-arg "--output" rest false) "."))
  (def render-pdf? (find-index |(= $ "--pdf") rest))

  (def verify-path (when verify-arg (resolve-path verify-arg "verify-")))
  (def perf-path   (when perf-arg   (resolve-path perf-arg   "perf-")))

  (def verify (if verify-path (load-jdn verify-path) @{}))
  (def perf   (if perf-path   (load-jdn perf-path)   @{}))

  (def ts       (util/mk-timestamp))
  (def md-file  (string output-path "/fig14-" ts ".md"))
  (def tex-file (string output-path "/fig14-" ts ".tex"))

  (util/mkdirp output-path)
  (spit md-file  (render-markdown verify perf))
  (spit tex-file (render-latex-document verify perf))
  (printf "Results saved to %s and %s\n" md-file tex-file)

  (when render-pdf?
    (util/run ["latexmk" "-pdf" "-interaction=nonstopmode"
               (string "-outdir=" output-path) tex-file])
    (util/run ["latexmk" "-c" (string "-outdir=" output-path) tex-file])))
