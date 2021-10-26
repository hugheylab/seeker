#' @import checkmate
#' @importFrom foreach foreach %do% %dopar%
#' @importFrom data.table data.table set
NULL
# readr not explicitly called, but used by tximport


#' Fetch metadata for a genomic study
#'
#' This function can use the API of the European Nucleotide Archive
#' (recommended) or the Sequence Read Archive.
#'
#' @param study String indicating study accession.
#' @param host String indicating from where to fetch the metadata.
#' @param fields Character vector indicating which fields to fetch.
#'
#' @return A `data.table`.
#'
#' @seealso [fetch()]
#'
#' @export
getMetadata = function(
  study, host = c('ena', 'sra'),
  fields = c(
    'study_accession', 'sample_accession', 'secondary_sample_accession',
    'sample_alias', 'sample_title', 'experiment_accession', 'run_accession',
    'fastq_ftp', 'fastq_aspera')) {

  assertString(study)
  host = match.arg(host)
  assertCharacter(fields, any.missing = FALSE)

  if (host == 'ena') {
    url = paste0(
      'https://www.ebi.ac.uk/ena/portal/api/filereport?accession=',
      study, '&result=read_run&format=tsv&download=true&fields=',
      paste0(fields, collapse = ','))
    sep = '\t'
  } else {
    url = paste0(
      'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi',
      '?save=efetch&db=sra&rettype=runinfo&term=', study)
    sep = ','}

  raw = curl::curl_fetch_memory(url)
  metadata = data.table::fread(
    text = rawToChar(raw$content), sep = sep, na.strings = '')
  return(metadata)}


#' Fetch files
#'
#' This function can download files using aspera (recommended) or wget, by
#' calling command-line interfaces using [system2()]. To download files in
#' parallel, register a parallel backend using [doFuture::registerDoFuture()] or
#' [doParallel::registerDoParallel()].
#'
#' @param remoteFilepaths Character vector of remote filepaths. For single-end
#'   reads, each element of the vector should be a single filepath. For
#'   paired-end reads, each element should be two filepaths separated by ";". If
#'   a remote filepath starts with "fasp", the file will be downloaded using
#'   aspera ascp, otherwise the file will be downloaded using wget.
#' @param outputDir String indicating the local directory in which to save the
#'   files. Will be created if it doesn't exist.
#' @param overwrite Logical indicating whether to overwrite files that already
#'   exist in `outputDir`.
#' @param wgetCmd String indicating command for fetching files using wget.
#' @param wgetArgs Character vector indicating arguments to pass to wget.
#' @param asperaCmd String indicating path to the aspera ascp program.
#' @param asperaArgs Character vector indicating arguments to pass to ascp.
#' @param asperaPrefix String indicating prefix for downloading files by aspera,
#'   i.e., `asperaPrefix@remoteFilepath`.
#'
#' @return A list. As the function runs, it updates a tab-delimited log file in
#'   `outputDir` called "progress.tsv".
#'
#' @seealso [getMetadata()], [getAsperaCmd()], [getAsperaArgs()]
#'
#' @export
fetch = function(
  remoteFilepaths, outputDir = 'fetch_output', overwrite = FALSE,
  wgetCmd = 'wget', wgetArgs = '-q', asperaCmd = getAsperaCmd(),
  asperaArgs = getAsperaArgs(), asperaPrefix = 'era-fasp') {

  assertCharacter(remoteFilepaths, any.missing = FALSE)
  assertString(outputDir)
  assertPathForOutput(outputDir, overwrite = TRUE)
  assertFlag(overwrite)
  assertString(wgetCmd)
  assertCharacter(wgetArgs, any.missing = FALSE)
  assertString(asperaCmd)
  assertCharacter(asperaArgs, any.missing = FALSE)
  assertString(asperaPrefix)

  f = fl = i = NULL
  if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)

  remoteFilepaths = getFileList(remoteFilepaths)
  localFilepaths = lapply(
    remoteFilepaths, function(f) file.path(outputDir, basename(f)))

  fs = unlist(remoteFilepaths)
  fls = unlist(localFilepaths)

  logPath = getLogPath(outputDir)
  writeLogFile(logPath, n = length(fs))

  outputSafe = safe(outputDir)

  feo = foreach(f = fs, fl = fls, i = 1:length(fs), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    if (file.exists(fl) && isFALSE(overwrite)) {
      r = 0
    } else {
      Sys.sleep(stats::runif(1L, 0, foreach::getDoParWorkers() / 4))

      if (startsWith(f, 'fasp')) {
        args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputSafe)
        r = system2(path.expand(asperaCmd), args)
      } else {
        r = system2(path.expand(wgetCmd), c(wgetArgs, '-P', outputSafe, f))}}

    writeLogFile(logPath, f, i, r)
    r}

  writeLogFile(logPath, n = -length(fs))
  d = list(localFilepaths = getFileVec(localFilepaths), statuses = result)
  return(d)}
