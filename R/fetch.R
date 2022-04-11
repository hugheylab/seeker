#' Fetch metadata for a genomic study
#'
#' This function can use the API of the European Nucleotide Archive
#' (recommended) or the Sequence Read Archive.
#'
#' @param bioproject String indicating bioproject accession.
#' @param host String indicating from where to fetch the metadata.
#' @param fields Character vector indicating which fields to fetch, if `host`
#'   is "ena".
#'
#' @return A `data.table`.
#'
#' @seealso [fetch()]
#'
#' @export
fetchMetadata = function(
  bioproject, host = c('ena', 'sra'),
  fields = c(
    'study_accession', 'sample_accession', 'secondary_sample_accession',
    'sample_alias', 'sample_title', 'experiment_accession', 'run_accession',
    'fastq_md5', 'fastq_ftp', 'fastq_aspera')) {

  assertString(bioproject)
  host = match.arg(host)
  assertCharacter(fields, any.missing = FALSE)

  if (host == 'ena') {
    url = paste0(
      'https://www.ebi.ac.uk/ena/portal/api/filereport?accession=',
      bioproject, '&result=read_run&format=tsv&download=true&fields=',
      paste0(fields, collapse = ','))
    sep = '\t'
  } else {
    url = paste0(
      'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi',
      '?save=efetch&db=sra&rettype=runinfo&term=', bioproject)
    sep = ','}

  raw = curl::curl_fetch_memory(url)
  metadata = fread(text = rawToChar(raw$content), sep = sep, na.strings = '')
  return(metadata)}


# #' Fetch files
# #'
# #' This function can download files using aspera ascp (recommended) or wget, by
# #' calling command-line interfaces using [system2()]. To download files in
# #' parallel, register a parallel backend, e.g., using
# #' [doParallel::registerDoParallel()].
# #'
# #' @param remoteFilepaths Character vector of remote filepaths. For single-end
# #'   reads, each element of the vector should be a single filepath. For
# #'   paired-end reads, each element should be two filepaths separated by ";". If
# #'   a remote filepath starts with "fasp", the file will be downloaded using
# #'   ascp, otherwise the file will be downloaded using wget.
# #' @param outputDir String indicating the local directory in which to save the
# #'   files. Will be created if it doesn't exist.
# #' @param overwrite Logical indicating whether to overwrite files that already
# #'   exist in `outputDir`.
# #' @param wgetCmd String indicating command for fetching files using wget.
# #' @param wgetArgs Character vector indicating arguments to pass to wget.
# #' @param ascpCmd String indicating path to the ascp program.
# #' @param ascpArgs Character vector indicating arguments to pass to ascp.
# #' @param ascpPrefix String indicating prefix for downloading files by ascp,
# #'   i.e., `ascpPrefix@remoteFilepath`.
# #'
# #' @return A list. As the function runs, it updates a tab-delimited log file in
# #'   `outputDir` called "progress.tsv".
# #'
# #' @seealso [fetchMetadata()], [getAscpCmd()], [getAscpArgs()]
# #'
# #' @export
# fetchOld = function(
#   remoteFilepaths, outputDir = 'fetch_output', overwrite = FALSE,
#   wgetCmd = 'wget', wgetArgs = '-q', ascpCmd = getAscpCmd(),
#   ascpArgs = getAscpArgs(), ascpPrefix = 'era-fasp') {
#
#   assertCharacter(remoteFilepaths, any.missing = FALSE)
#   assertString(outputDir)
#   assertPathForOutput(outputDir, overwrite = TRUE)
#   assertFlag(overwrite)
#   assertString(wgetCmd)
#   assertCharacter(wgetArgs, any.missing = FALSE)
#   assertString(ascpCmd)
#   assertCharacter(ascpArgs, any.missing = FALSE)
#   assertString(ascpPrefix)
#
#   f = fl = i = NULL
#   if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)
#
#   remoteFilepaths = getFileList(remoteFilepaths)
#   localFilepaths = lapply(
#     remoteFilepaths, function(f) file.path(outputDir, basename(f)))
#
#   fs = unlist(remoteFilepaths)
#   fls = unlist(localFilepaths)
#
#   logPath = getLogPath(outputDir)
#   writeLogFile(logPath, n = length(fs))
#
#   outputSafe = safe(outputDir)
#
#   feo = foreach(f = fs, fl = fls, i = seq_len(length(fs)), .combine = c,
#                 .options.future = list(scheduling = Inf))
#
#   result = feo %dopar% {
#     if (file.exists(fl) && isFALSE(overwrite)) {
#       r = 0
#     } else {
#       Sys.sleep(stats::runif(1L, 0, foreach::getDoParWorkers() / 4))
#
#       if (startsWith(f, 'fasp')) {
#         args = c(ascpArgs, sprintf('%s@%s', ascpPrefix, f), outputSafe)
#         r = system3(path.expand(ascpCmd), args)
#       } else {
#         r = system3(path.expand(wgetCmd), c(wgetArgs, '-P', outputSafe, f))}}
#
#     writeLogFile(logPath, f, i, r)
#     r}
#
#   writeLogFile(logPath, n = -length(fs))
#   d = list(localFilepaths = getFileVec(localFilepaths), statuses = result)
#   return(d)}


#' Fetch files
#'
#' This function uses the NCBI SRA Toolkit via [system2()] to download files
#' from SRA and convert them to fastq.gz. To process files in parallel, register
#' a parallel backend, e.g., using [doParallel::registerDoParallel()]. Beware
#' that intermediate files created by fasterq-dump are uncompressed and could
#' require hundreds of gigabytes if files are processed in parallel.
#'
#' @param accessions Character vector of SRA run accessions.
#' @param outputDir String indicating the local directory in which to save the
#'   files. Will be created if it doesn't exist.
#' @param overwrite Logical indicating whether to overwrite files that already
#'   exist in `outputDir`.
#' @param keepSra Logical indicating whether to keep the ".sra" files.
#' @param prefetchCmd String indicating command for prefetch, which downloads
#'   ".sra" files.
#' @param prefetchArgs Character vector indicating arguments to pass to
#'   prefetch.
#' @param fasterqdumpCmd String indicating command for fasterq-dump, which
#'   uses ".sra" files to create ".fastq" files.
#' @param fasterqdumpArgs Character vector indicating arguments to pass to
#'   fasterq-dump.
#' @param pigzCmd String indicating command for pigz, which converts ".fastq"
#'   files to ".fastq.gz" files.
#' @param pigzArgs Character vector indicating arguments to pass to pigz.
#'
#' @return A list. As the function runs, it updates a tab-delimited log file in
#'   `outputDir` called "progress.tsv".
#'
#' @seealso [fetchMetadata()]
#'
#' @export
fetch = function(
  accessions, outputDir, overwrite = FALSE, keepSra = FALSE,
  prefetchCmd = 'prefetch', prefetchArgs = NULL,
  fasterqdumpCmd = 'fasterq-dump', fasterqdumpArgs = NULL,
  pigzCmd = 'pigz', pigzArgs = NULL) {

  acc = i = NULL
  assertCharacter(accessions, any.missing = FALSE)
  assertString(outputDir)
  assertPathForOutput(outputDir, overwrite = TRUE)
  assertFlag(overwrite)
  assertFlag(keepSra)
  assertString(prefetchCmd)
  assertCharacter(prefetchArgs, any.missing = FALSE, null.ok = TRUE)
  assertString(fasterqdumpCmd)
  assertCharacter(fasterqdumpArgs, any.missing = FALSE, null.ok = TRUE)
  assertString(pigzCmd)
  assertCharacter(pigzArgs, any.missing = FALSE, null.ok = TRUE)

  if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)

  logPath = getLogPath(outputDir)
  writeLogFile(logPath, n = length(accessions))

  feo = foreach(
    acc = accessions, i = seq_len(length(accessions)),
    .options.future = list(scheduling = Inf))

  # TODO: possibly use dopar loop and single-thread fasterqdump and pigz
  result = feo %dopar% {
  # result = feo %do% {
    pat = '^{acc}(_1|_2|)\\.fastq'
    paths = dir(outputDir, glue(pat, '\\.gz$'), full.names = TRUE)

    if (length(paths) > 0 && isFALSE(overwrite)) {
      r = 0
    } else {
      Sys.sleep(stats::runif(1L, 0, foreach::getDoParWorkers() / 4))
      # above line to avoid possible rate limiting if dopar

      args = c(prefetchArgs, '-O', safe(outputDir), acc)
      r = system3(path.expand(prefetchCmd), args)

      args = c(
        fasterqdumpArgs, '-e', 1,
        # fasterqdumpArgs, '-e', foreach::getDoParWorkers(),
        '-O', safe(outputDir), '-f', acc)
      r = system3(path.expand(fasterqdumpCmd), args)

      args = c(
        pigzArgs, '-p', 1,
        # pigzArgs, '-p', foreach::getDoParWorkers(),
        '-f', safe(dir(outputDir, glue(pat, '$'), full.names = TRUE)))
      r = system3(path.expand(pigzCmd), args)
      paths = dir(outputDir, glue(pat, '\\.gz$'), full.names = TRUE)

      if (isFALSE(keepSra)) {
        unlink(file.path(outputDir, acc), recursive = TRUE)}}

    writeLogFile(logPath, acc, i, r)
    list(paths, r)}

  writeLogFile(logPath, n = -length(accessions))
  d = list(localFilepaths = getFileVec(lapply(result, `[[`, 1L)),
           statuses = sapply(result, `[[`, 2L))
  return(d)}
