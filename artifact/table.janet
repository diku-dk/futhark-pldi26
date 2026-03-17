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

# Static metadata for the evaluation table.
# Properties: FP = FiltPart, InvFP = FiltPartInv, Inj = Injective, Equiv = Equiv
# #S = number of scatter operations; #A = number of non-trivial annotations.
# :tex-name is used in LaTeX rows; :properties-tex uses ~ for non-breaking spaces.
# ------------------------------------------------------------------------------
(def program-order
  [:max-match :mis :fft :primes :kmeans-ker
   :partition :partition3 :seg-part :filter :filter-irreg])

(def program-meta
  {:max-match    {:md "max_match"     :tex-name `$\mathsf{max\_match}$`     :properties "Range, Equiv, Inj, FP"  :properties-tex `Range,~Equiv,~Inj,~FP` :num-s 6 :num-a 14}
   :mis          {:md "MIS"           :tex-name `$\mathsf{MIS}$`            :properties "Range"                  :properties-tex `Range`                  :num-s 3 :num-a 35}
   :fft          {:md "FFT"           :tex-name `$\mathsf{FFT}$`            :properties "Inj"                    :properties-tex `Inj`                    :num-s 1 :num-a 1}
   :primes       {:md "primes"        :tex-name `$\mathsf{primes}$`         :properties "Range, FP"              :properties-tex `Range,~FP`              :num-s 2 :num-a 12}
   :kmeans-ker   {:md "kmeans_ker"    :tex-name `$\mathsf{kmeans\_ker}$`    :properties "Range"                  :properties-tex `Range`                  :num-s 0 :num-a 3}
   :partition    {:md "partition"     :tex-name `$\mathsf{partition}$`      :properties "Equiv, FP"              :properties-tex `Equiv,~FP`              :num-s 1 :num-a 1}
   :partition3   {:md "partition3"    :tex-name `$\mathsf{partition3}$`     :properties "Equiv, FP"              :properties-tex `Equiv,~FP`              :num-s 1 :num-a 2}
   :seg-part     {:md "seg_partition" :tex-name `$\mathsf{seg\_partition}$` :properties "Range, Equiv, FP"       :properties-tex `Range,~Equiv,~FP`       :num-s 1 :num-a 3}
   :filter       {:md "filter"        :tex-name `$\mathsf{filter}$`         :properties "Equiv, FP"              :properties-tex `Equiv,~FP`              :num-s 1 :num-a 3}
   :filter-irreg {:md "filter_irreg"  :tex-name `$\mathsf{filter\_irreg}$`  :properties "Range, Equiv, InvFP"    :properties-tex `Range,~Equiv,~InvFP`    :num-s 1 :num-a 3}})

# Formatting helpers
# ------------------------------------------------------------------------------
(defn fmt-secs [n]
  (if n (string/format "%.1fs" n) "—"))

(defn fmt-pct [n]
  (if n (string/format "%d%%" (math/round n)) "—"))

(defn fmt-pct-tex [n]
  (if n (string/format "%d\\%%" (math/round n)) "---"))

(defn fmt-ms [us]
  (if us (string/format "%dms" (math/round (/ us 1000))) "—"))

(defn fmt-ms-tex [us]
  (if us (string/format "%d" (math/round (/ us 1000))) "---"))

(defn fmt-speedup [a b]
  (if (and a b (> b 0))
    (string/format "%.1f×" (/ a b))
    "—"))

(defn fmt-speedup-tex [a b]
  (if (and a b (> b 0))
    (string/format "$%.1f\\times$" (/ a b))
    "---"))

(defn fmt-speedup-opt-tex [a b]
  (if (and a b (> b 0))
    (string/format "$%.2f\\times$" (/ a b))
    "---"))

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
(defn render-latex-figure [verify perf]
  (defn v [key field] (get-in verify [key field]))
  (def kmeans    (get perf :kmeans    @{}))
  (def partition (get perf :partition2 @{}))

  # Left table rows
  (def verify-rows
    (map (fn [key]
           (def m (program-meta key))
           (string/format "  %s & %s & %s & %d & %d & %s & %s \\\\"
             (m :tex-name)
             (m :properties-tex)
             (if (get-in verify [key :safe]) `$\checkmark$` `$\times$`)
             (m :num-s)
             (m :num-a)
             (fmt-secs (v key :prop-time))
             (fmt-pct-tex (v key :pct))))
         program-order))

  # Right table rows: kmeans
  (def kmeans-rows
    (map (fn [ds]
           (def entry (get kmeans ds @{}))
           (string/format `  \hspace{0.5em} %s & %s & %s \\`
             ds
             (fmt-ms-tex (get entry :dyn))
             (fmt-speedup-tex (get entry :dyn) (get entry :static))))
         ["movielens" "nytimes" "scrna"]))

  # Right table rows: partition2
  (def part-rows
    (map (fn [sz]
           (def entry (get partition sz @{}))
           (string/format `  \hspace{0.5em} %s & %s & %s & %s \\`
             sz
             (fmt-ms-tex (get entry :dyn))
             (fmt-speedup-tex (get entry :dyn) (get entry :static))
             (fmt-speedup-opt-tex (get entry :static) (get entry :static-opt))))
         ["50M" "100M" "200M"]))

  (string/join
    [`\begin{figure}`
     `\footnotesize`
     `\begin{minipage}[t]{0.66\linewidth}`
     `\begin{tabular}{lrrrrrr}`
     `\vspace{-0.5em}`
     `                       &                        &               &              &              &                & \textsc{\% of}\\`
     `\vspace{-0.5em}`
     `                       & \textsc{Properties \&} &               &              &              & \textsc{Check} & \textsc{Compile}\\`
     `\textsc{Program}       & \textsc{annotations}   & \textsc{Safe} & \textsc{\#S} & \textsc{\#A} & \textsc{time}  & \textsc{time}\\`
     `\hline`
     ;verify-rows
     `\end{tabular}`
     `\end{minipage}\begin{minipage}[t]{0.34\linewidth}`
     `\begin{tabular}{lrrr}`
     `\vspace{-0.3em}`
     `\textsc{Program}     & \textsc{Dyn.}   & \multicolumn{2}{c}{\textsc{Speedup}}  \\`
     `\textsc{\& Data}     & \textsc{($ms$)} & \textsc{Static} & $+$\textsc{Opt}\\`
     `\hline`
     `  $\mathsf{kmeans\_ker}$ & \\`
     ;kmeans-rows
     `  $\mathsf{partition2}$ & \\`
     ;part-rows
     `\end{tabular}`
     `\end{minipage}`
     `\caption{`
     `  Left:`
     `  Summary of evaluated programs.`
     `  FP abbreviates FiltPart.`
     `  \textsc{Safe} indicates whether all indexing and scatters are verified.`
     `  \textsc{\#S} and \textsc{\#A} denote scatters and annotations.`
     `  Check time measures \system's runtime (Apple M4 chip).`
     `  Right: NVIDIA A100 performance with dynamic checks (\textsc{Dyn.}) as baseline.`
     `  \textsc{Static} shows speedup over dynamic checks.`
     `  \textsc{+Opt} additionally removes scattered array initialization (speedup over \textsc{Static}).`
     `}`
     `\label{tab:eval}`
     `\end{figure}`]
    "\n"))

(defn render-latex-document [verify perf]
  (string/join
    [`\documentclass{article}`
     `\usepackage{amssymb}`
     `\begin{document}`
     (render-latex-figure verify perf)
     `\end{document}`]
    "\n"))

# Main
# ------------------------------------------------------------------------------
(defn main [& args]
  (def rest (slice args 1))
  (when (or (find-index |(= $ "--help") rest) (empty? rest))
    (print usage)
    (os/exit 0))

  (util/check-unknown-args rest ["--verify" "--perf" "--output" "--pdf" "--help"])

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
  (def pdf-file (string output-path "/fig14-" ts ".pdf"))

  (util/mkdirp output-path)
  (spit md-file  (render-markdown verify perf))
  (spit tex-file (render-latex-document verify perf))
  (if render-pdf?
    (do
      (util/run ["latexmk" "-pdf" "-interaction=nonstopmode"
                 (string "-outdir=" output-path) tex-file])
      (util/run ["latexmk" "-c" (string "-outdir=" output-path) tex-file])
      (printf "Results saved to %s, %s, and %s\n" md-file tex-file pdf-file))
    (printf "Results saved to %s and %s\n" md-file tex-file)))
