#' Run FastQC
#'
#' This function calls
#' [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) using
#' [system2()]. To run in parallel, register a parallel backend using
#' [doFuture::registerDoFuture()] or [doParallel::registerDoParallel()].
#'
#' @param filepaths Paths to fastq files. For single-end reads, each element
#'   should be a single filepath. For paired-end reads, each element can be two
#'   filepaths separated by ";".
#' @param outputDir Directory in which to store output. Will be created if it
#'   doesn't exist.
#' @param cmd Name or path of the command-line interface.
#' @param args Additional arguments to pass to the command-line interface.
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


#' Run FastQ Screen
#'
#' This function calls
#' [fastq_screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)
#' using [system2()]. To run in parallel, register a parallel backend using
#' [doFuture::registerDoFuture()] or [doParallel::registerDoParallel()].
#'
#' @param filepaths Paths to fastq files. For single-end reads, each element
#'   should be a single filepath. For paired-end reads, each element can be two
#'   filepaths separated by ";".
#' @param outputDir Directory in which to store output. Will be created if it
#'   doesn't exist.
#' @param cmd Name or path of the command-line interface.
#' @param args Additional arguments to pass to the command-line interface.
#'
#' @return A vector of exit codes, invisibly.
#'
#' @export
fastqscreen = function(
  filepaths, outputDir = 'fastqscreen_output', cmd = 'fastq_screen',
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


#' Run Trim Galore!
#'
#' This function calls
#' [trim_galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)
#' using [system2()]. To run in parallel, register a parallel backend using
#' [doFuture::registerDoFuture()] or [doParallel::registerDoParallel()].
#'
#' @param filepaths Paths to fastq files. For single-end reads, each element
#'   should be a single filepath. For paired-end reads, each element should be
#'   two filepaths separated by ";".
#' @param outputDir Directory in which to store output. Will be created if it
#'   doesn't exist.
#' @param cmd Name or path of the command-line interface.
#' @param args Additional arguments to pass to the command-line interface.
#'
#' @return A vector of exit codes, invisibly.
#'
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


#' Run MultiQC
#'
#' This function calls [multiqc](https://multiqc.info/) using [system2()].
#'
#' @param parentDir Directory that contains output to be aggregated.
#' @param outputDir Directory in which to store output. Will be created if it
#'   doesn't exist.
#' @param cmd Name or path of the command-line interface.
#' @param args Additional arguments to pass to the command-line interface.
#'
#' @return An exit code, invisibly.
#'
#' @export
multiqc = function(
  parentDir = '.', outputDir = 'multiqc_output', cmd = 'multiqc', args = NULL) {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}
