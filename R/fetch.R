#' @importFrom foreach foreach %do% %dopar%
#' @importFrom data.table data.table
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
#' @seealso [getFastq()]
#'
#' @export
getMetadata = function(
  study, host = c('ena', 'sra'),
  fields = c(
    'study_accession', 'sample_accession', 'secondary_sample_accession',
    'sample_alias', 'sample_title', 'experiment_accession', 'run_accession',
    'fastq_ftp', 'fastq_aspera')) {

  host = match.arg(host)

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
  metadata = data.table::fread(text = rawToChar(raw$content), sep = sep)
  return(metadata)}


#' Fetch fastq files
#'
#' This function can download fastq files using aspera (recommended) or ftp, by
#' calling command-line interfaces using [system2()]. To download files in
#' parallel, register a parallel backend using [doFuture::registerDoFuture()] or
#' [doParallel::registerDoParallel()].
#'
#' @param remoteFilepaths Character vector of remote filepaths. For single-end
#'   reads, each element of the vector should be a single filepath. For
#'   paired-end reads, each element should be two filepaths separated by ";". If
#'   a remote filepath starts with "fasp", the file will be downloaded using
#'   aspera, otherwise the file will be downloaded using ftp.
#' @param outputDir String indicating the local directory in which to save the
#'   files. Will be created if it doesn't exist.
#' @param overwrite Logical indicating whether to overwrite files that already
#'   exist in `outputDir`.
#' @param ftpCmd String indicating system command for fetching files by ftp.
#' @param ftpArgs Character vector indicating arguments to pass to `ftpCmd`.
#' @param asperaCmd String indicating path to the aspera ascp program.
#' @param asperaArgs Character vector indicating arguments to pass to
#'   `asperaCmd`.
#' @param asperaPrefix String indicating prefix for downloading files by aspera,
#'   i.e., `asperaPrefix@remoteFilepath`.
#'
#' @return A `data.table`. As the function runs, it updates a tab-delimited log
#'   file in `outputDir` called "progress.tsv".
#'
#' @seealso [getMetadata()]
#'
#' @export
getFastq = function(
  remoteFilepaths, outputDir = 'fastq', overwrite = FALSE, ftpCmd = 'wget',
  ftpArgs = '-q', asperaCmd = '~/.aspera/connect/bin/ascp',
  asperaArgs = c('-QT -l 300m -P33001', '-i',
                 '~/.aspera/connect/etc/asperaweb_id_dsa.openssh'),
  asperaPrefix = 'era-fasp') {

  f = fl = i = NULL
  dir.create(outputDir, recursive = TRUE)

  remoteFilepaths = getFileList(remoteFilepaths)
  localFilepaths = lapply(
    remoteFilepaths, function(f) file.path(outputDir, basename(f)))

  fs = unlist(remoteFilepaths)
  fls = unlist(localFilepaths)

  logPath = file.path(outputDir, 'progress.tsv')
  createLogFile(logPath, length(fs))

  feo = foreach(f = fs, fl = fls, i = 1:length(fs), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    if (file.exists(fl) && !isTRUE(overwrite)) {
      r = 0
    } else {
      Sys.sleep(stats::runif(1L, 0, foreach::getDoParWorkers() / 4))

      if (startsWith(f, 'fasp')) {
        args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputDir)
        r = system2(path.expand(asperaCmd), args)
      } else {
        r = system2(path.expand(ftpCmd), c(ftpArgs, '-P', outputDir, f))}}

    appendLogFile(logPath, f, i, r)
    r}

  d = data.table(local_filepath = getFileVec(localFilepaths), status = result)
  return(d)}
