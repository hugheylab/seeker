#' @importFrom foreach foreach %do% %dopar%


globalVariables(c('f', 'i', 'id'))


createLogFile = function(filepath, n) {
  d = data.frame(datetime = as.character(Sys.time()),
                 task = sprintf('started (%d tasks)', n),
                 idx = 0, stringsAsFactors = FALSE)
  readr::write_tsv(d, filepath)
  invisible(d)}


appendLogFile = function(filepath, task, idx) {
  d = data.frame(datetime = as.character(Sys.time()), task = task,
                 idx = idx, stringsAsFactors = FALSE)
  readr::write_tsv(d, filepath, append = TRUE)
  invisible(d)}


#' @export
getMetadataSra = function(study) {
  urlBase = c('http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi',
              '?save=efetch&db=sra&rettype=runinfo&term=')
  url = paste0(c(urlBase, study), collapse = '')
  raw = curl::curl_fetch_memory(url)
  metadata = data.frame(readr::read_csv(rawToChar(raw$content)))
  return(metadata)}


#' @export
getMetadataEna = function(study, downloadMethod = 'aspera') {
  fastqColname = ifelse(downloadMethod == 'aspera', 'fastq_aspera', 'fastq_ftp')
  url = paste0('https://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=',
                study, '&result=read_run&fields=sample_accession,secondary_sample_accession,',
                'experiment_accession,run_accession,', fastqColname, '&download=txt')
  raw = curl::curl_fetch_memory(url)
  metadata = data.frame(readr::read_tsv(rawToChar(raw$content)))
  if (grepl(';', metadata[[fastqColname]][1])) {
    metadata[[fastqColname]] = strsplit(metadata[[fastqColname]], ';')}
  return(metadata)}


#' @export
getFastq = function(remoteFilepaths, outputDir, overwrite = FALSE, ftpCmd = 'wget',
                    ftpArgs = '-q', asperaCmd = '~/.aspera/connect/bin/ascp',
                    asperaArgs = c('-QT -l 300m -P33001', '-i',
                                   '~/.aspera/connect/etc/asperaweb_id_dsa.openssh'),
                    asperaPrefix = 'era-fasp') {
  dir.create(outputDir, recursive = TRUE)

  if (is.list(remoteFilepaths)) {
    localFilepaths = lapply(remoteFilepaths,
                            function(f) file.path(outputDir, basename(f)))
  } else {
    localFilepaths = file.path(outputDir, basename(remoteFilepaths))}

  fs = unlist(remoteFilepaths)
  fls = unlist(localFilepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  result = foreach(f = fs, fl = fls, i = 1:length(fs), .combine = c) %dopar% {
    if (file.exists(fl) && !overwrite) {
      r = 0
    } else {
      if (startsWith(f, 'fasp')) {
        args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputDir)
        r = system2(path.expand(asperaCmd), args)
      } else {
        r = system2(path.expand(ftpCmd), c(ftpArgs, '-P', outputDir, f))}}
    appendLogFile(logFilepath, f, i)
    r}

  return(list(localFilepaths = localFilepaths, exitCodes = result))}


checkFilepaths = function(filepaths) {
  if (!all(file.exists(unlist(filepaths)))) {
    stop('Not all supplied file paths exist.')}
  invisible(0)}


#' @export
fastqc = function(filepaths, outputDir = 'fastqc_output', cmd = 'fastqc',
                  args = c('-t', foreach::getDoParWorkers())) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  result = foreach(f = fs, i = 1:length(fs), .combine = c) %do% {
    r = system2(path.expand(cmd), c(args, '-o', outputDir, f))
    appendLogFile(logFilepath, f, i)
    r}
  invisible(result)}


#' @export
fastqscreen = function(filepaths, outputDir = 'fastqscreen_output',
                       cmd = '~/fastq_screen_v0.13.0/fastq_screen',
                       args = c('--threads', foreach::getDoParWorkers(),
                                '--conf', '~/FastQ_Screen_Genomes/fastq_screen.conf')) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  result = foreach(f = fs, i = 1:length(fs), .combine = c) %do% {
    r = system2(path.expand(cmd), c(args, '--outdir', outputDir, f))
    appendLogFile(logFilepath, f, i)
    r}
  invisible(result)}


#' @export
trimgalore = function(filepaths, outputDir = 'trimgalore_output',
                      cmd = 'trim_galore', args = '') {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(filepaths))

  result = foreach(f = filepaths, i = 1:length(filepaths), .combine = c) %dopar% {
    argsNow = c(args, '-o', outputDir)
    if (length(f) > 1) {
      argsNow = c(argsNow, '--paired', f[1], f[2])
    } else {
      argsNow = c(argsNow, f)}
    r = system2(path.expand(cmd), argsNow)
    appendLogFile(logFilepath, paste(f, collapse = '; '), i)
    r}
  invisible(result)}


#' @export
salmon = function(filepaths, runs, samples = runs,
                  outputDir = 'salmon_output', cmd = 'salmon',
                  indexPath = '~/transcriptomes/homo_sapiens_transcripts',
                  args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
                           '-q --seqBias --gcBias --no-version-check')) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', args, '-i', indexPath)

  samplesUnique = sort(unique(samples))
  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(samplesUnique))

  result = foreach(i = 1:length(samplesUnique), .combine = c) %do% {
    samp = samplesUnique[i]
    f = filepaths[samp == samples]
    r = runs[samp = samples]
    args1 = c(argsBase, '-o', file.path(outputDir, samp))

    if (is.list(f)) {
      f1 = sapply(f, function(f) f[1])
      f2 = sapply(f, function(f) f[2])
      args2 = c('-1', f1, '-2', f2)
    } else {
      args2 = c('-r', f)}
    res = system2(path.expand(cmd), c(args1, args2))
    appendLogFile(logFilepath, samp, i)
    res}
  invisible(result)}


#' @export
getTx2gene = function(dataset = 'hsapiens_gene_ensembl', version = 94) {
  # biomaRt::listEnsemblArchives()
  mart = biomaRt::useEnsembl('ensembl', dataset, version = version)
  t2g = biomaRt::getBM(attributes = c('ensembl_transcript_id', 'ensembl_gene_id'),
                       mart = mart)
  return(t2g)}


#' @export
tximport = function(dirpaths, tx2gene, outputFilepath = 'tximport_output.rds',
                    type = 'salmon', countsFromAbundance = 'lengthScaledTPM',
                    ignoreTxVersion = TRUE, ...) {
  if (type == 'salmon') {
    filename = 'quant.sf'
  } else if (type == 'kallisto') {
    filename = 'abundance.h5'}

  filepaths = file.path(dirpaths, filename)
  names(filepaths) = basename(dirpaths)
  checkFilepaths(filepaths)
  txi = tximport::tximport(filepaths, tx2gene = tx2gene, type = type,
                           countsFromAbundance = countsFromAbundance,
                           ignoreTxVersion = ignoreTxVersion, ...)

  if (!is.null(outputFilepath)) {
    saveRDS(txi, outputFilepath)}
  invisible(txi)}


#' @export
multiqc = function(parentDir = '.', outputDir = 'multiqc_output',
                   cmd = 'multiqc', args = '') {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}
