#' Run fastqc
#'
#' This function calls
#' [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) using
#' [system2()]. To run in parallel, register a parallel backend using
#' [doFuture::registerDoFuture()] or [doParallel::registerDoParallel()].
#'
#' @param filepaths Paths to fastq files.
#' @param outputDir Directory in which to store fastqc's
#'   output.
#' @param cmd Name of fastqc command-line interface.
#' @param args Arguments to pass to fastqc's CLI.
#'
#' @return A vector of exit codes, invisibly.
#'
#' @export
fastqc = function(
  filepaths, outputDir = 'fastqc_output', cmd = 'fastqc', args = NULL) {

  f = i = NULL
  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logPath = file.path(outputDir, 'progress.tsv')
  createLogFile(logPath, length(fs))

  feo = foreach(f = fs, i = 1:length(fs), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    r = system2(path.expand(cmd), c(args, '-o', outputDir, f))
    appendLogFile(logPath, f, i, r)
    r}
  invisible(result)}


#' @export
fastqscreen = function(
  filepaths, outputDir = 'fastqscreen_output',
  cmd = '~/miniconda3/bin/fastq_screen',
  args = c('--threads', foreach::getDoParWorkers(), '--conf',
           '~/FastQ_Screen_Genomes/fastq_screen.conf')) {

  f = i = NULL
  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logPath = file.path(outputDir, 'progress.tsv')
  createLogFile(logPath, length(fs))

  result = foreach(f = fs, i = 1:length(fs), .combine = c) %do% {
    r = system2(path.expand(cmd), c(args, '--outdir', outputDir, f))
    appendLogFile(logPath, f, i, r)
    r}
  invisible(result)}


#' @export
trimgalore = function(
  filepaths, outputDir = 'trimgalore_output', cmd = 'trim_galore', args = NULL) {

  f = i = NULL
  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)

  logPath = file.path(outputDir, 'progress.tsv')
  createLogFile(logPath, length(filepaths))

  feo = foreach(f = filepaths, i = 1:length(filepaths), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    argsNow = c(args, '-o', outputDir)
    if (length(f) > 1) {
      argsNow = c(argsNow, '--paired', f[1], f[2])
    } else {
      argsNow = c(argsNow, f)}
    r = system2(path.expand(cmd), argsNow)
    appendLogFile(logPath, paste(f, collapse = '; '), i, r)
    r}
  invisible(result)}


#' @export
multiqc = function(
  parentDir = '.', outputDir = 'multiqc_output', cmd = 'multiqc', args = NULL) {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}
