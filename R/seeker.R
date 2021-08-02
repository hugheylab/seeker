#' @importFrom foreach foreach %do% %dopar%
# readr not explicitly called, but used by tximport

globalVariables(c('f', 'fl', 'i', 'id'))


createLogFile = function(filepath, n) {
  d = list(datetime = as.character(Sys.time()),
           task = sprintf('started (%d tasks)', n), idx = 0, status = 0)
  data.table::fwrite(d, filepath, sep = '\t')
  invisible(d)}


appendLogFile = function(filepath, task, idx, status) {
  d = list(
    datetime = as.character(Sys.time()), task = task, idx = idx, status = status)
  data.table::fwrite(d, filepath, sep = '\t', append = TRUE)
  invisible(d)}


getFileList = function(fileVec) {
  if (is.list(fileVec)) {
    return(fileVec)}
  return(strsplit(fileVec, ';'))}


getFileVec = function(fileList) {
  return(sapply(fileList, function(f) paste0(f, collapse = ';')))}


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
    urlBase = c('http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi',
                '?save=efetch&db=sra&rettype=runinfo&term=')
    url = paste0(c(urlBase, study), collapse = '')
    sep = ','}

  raw = curl::curl_fetch_memory(url)
  metadata = data.table::fread(text = rawToChar(raw$content), sep = sep)
  return(metadata)}


#' @export
getFastq = function(
  remoteFilepaths, outputDir = 'fastq', overwrite = FALSE, ftpCmd = 'wget',
  ftpArgs = '-q', asperaCmd = '~/.aspera/connect/bin/ascp',
  asperaArgs = c('-QT -l 300m -P33001', '-i',
                 '~/.aspera/connect/etc/asperaweb_id_dsa.openssh'),
  asperaPrefix = 'era-fasp') {

  dir.create(outputDir, recursive = TRUE)

  remoteFilepaths = getFileList(remoteFilepaths)
  localFilepaths = lapply(
    remoteFilepaths, function(f) file.path(outputDir, basename(f)))

  fs = unlist(remoteFilepaths)
  fls = unlist(localFilepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  feo = foreach(f = fs, fl = fls, i = 1:length(fs), .combine = c,
                .options.future = list(scheduling = Inf))
  result = feo %dopar% {
    if (file.exists(fl) && !overwrite) {
      r = 0
    } else {
      if (startsWith(f, 'fasp')) {
        args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputDir)
        r = system2(path.expand(asperaCmd), args)
      } else {
        r = system2(path.expand(ftpCmd), c(ftpArgs, '-P', outputDir, f))}}
    appendLogFile(logFilepath, f, i, r)
    r}

  return(list(localFilepaths = getFileVec(localFilepaths), statuses = result))}


checkFilepaths = function(filepaths) {
  if (!all(file.exists(unlist(filepaths)))) {
    stop('Not all supplied file paths exist.')}
  invisible(0)}


#' @export
fastqc = function(
  filepaths, outputDir = 'fastqc_output', cmd = 'fastqc', args = NULL) {

  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  feo = foreach(f = fs, i = 1:length(fs), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    r = system2(path.expand(cmd), c(args, '-o', outputDir, f))
    appendLogFile(logFilepath, f, i, r)
    r}
  invisible(result)}


#' @export
fastqscreen = function(
  filepaths, outputDir = 'fastqscreen_output',
  cmd = '~/miniconda3/bin/fastq_screen',
  args = c('--threads', foreach::getDoParWorkers(), '--conf',
           '~/FastQ_Screen_Genomes/fastq_screen.conf')) {

  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(fs))

  result = foreach(f = fs, i = 1:length(fs), .combine = c) %do% {
    r = system2(path.expand(cmd), c(args, '--outdir', outputDir, f))
    appendLogFile(logFilepath, f, i, r)
    r}
  invisible(result)}


#' @export
trimgalore = function(
  filepaths, outputDir = 'trimgalore_output', cmd = 'trim_galore', args = NULL) {

  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)

  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(filepaths))

  feo = foreach(f = filepaths, i = 1:length(filepaths), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %dopar% {
    argsNow = c(args, '-o', outputDir)
    if (length(f) > 1) {
      argsNow = c(argsNow, '--paired', f[1], f[2])
    } else {
      argsNow = c(argsNow, f)}
    r = system2(path.expand(cmd), argsNow)
    appendLogFile(logFilepath, paste(f, collapse = '; '), i, r)
    r}
  invisible(result)}


#' @export
salmon = function(
  filepaths, samples, outputDir = 'salmon_output', cmd = 'salmon',
  indexPath = '~/transcriptomes/homo_sapiens_transcripts',
  args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
           '-q --seqBias --gcBias --no-version-check')) {

  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', args, '-i', indexPath)

  samplesUnique = sort(unique(samples))
  logFilepath = file.path(outputDir, 'progress.tsv')
  createLogFile(logFilepath, length(samplesUnique))

  feo = foreach(i = 1:length(samplesUnique), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %do% {
    samp = samplesUnique[i]
    f = filepaths[samp == samples]
    args1 = c(argsBase, '-o', file.path(outputDir, samp))

    if (length(f[[1]]) > 1) {
      f1 = sapply(f, function(f) f[1])
      f2 = sapply(f, function(f) f[2])
      args2 = c('-1', f1, '-2', f2)
    } else {
      args2 = c('-r', unlist(f))}

    r = system2(path.expand(cmd), c(args1, args2))
    appendLogFile(logFilepath, samp, i, r)
    r}
  invisible(result)}


#' @export
getSalmonMetadata = function(
  outputDir = 'salmon_output', outputFilename = 'meta_info.csv') {

  filepaths = list.files(
    outputDir, 'meta_info.json', full.names = TRUE, recursive = TRUE)
  sampleNames = sapply(
    strsplit(filepaths, .Platform$file.sep), function(x) x[length(x) - 2L])

  metaList = lapply(filepaths, function(x) rjson::fromJSON(file = x))
  names(metaList) = sampleNames

  fieldNames = c('eq_class_properties', 'length_classes')
  metaSpecial = list()
  for (fieldName in fieldNames) {
    fieldSpecial = lapply(metaList, function(x) x[[fieldName]])
    if (!all(lapply(fieldSpecial, length) == 0)) {
      metaSpecial[[fieldName]] = lapply(metaList, function(x) x[[fieldName]])}}

  metaList = lapply(metaList, function(x) {
    idx = !(names(x) %in% c('quant_errors', fieldNames))
    x[idx]})
  metadata = data.table::rbindlist(metaList, fill = TRUE, idcol = 'sample_name')

  for (fieldName in names(metaSpecial)) {
    data.table::set(
      metadata, i = NULL, j = fieldName, value = metaSpecial[[fieldName]])}

  if (!is.null(outputFilename)) {
    data.table::fwrite(metadata, file.path(outputDir, outputFilename))}
  invisible(metadata)}


#' @export
getTx2gene = function(dataset = 'hsapiens_gene_ensembl', version = 99) {
  # biomaRt::listEnsemblArchives()
  mart = biomaRt::useEnsembl('ensembl', dataset, version = version)
  t2g = biomaRt::getBM(
    attributes = c('ensembl_transcript_id', 'ensembl_gene_id'), mart = mart)
  return(t2g)}


#' @export
tximport = function(
  dirpaths, tx2gene, outputFilepath = 'tximport_output.qs',
  type = c('salmon', 'kallisto'), countsFromAbundance = 'lengthScaledTPM',
  ignoreTxVersion = TRUE, ...) {

  type = match.arg(type)
  if (type == 'salmon') {
    filename = 'quant.sf'
  } else if (type == 'kallisto') {
    filename = 'abundance.h5'}

  filepaths = file.path(dirpaths, filename)
  names(filepaths) = basename(dirpaths)
  checkFilepaths(filepaths)

  txi = tximport::tximport(
    filepaths, tx2gene = tx2gene, type = type,
    countsFromAbundance = countsFromAbundance,
    ignoreTxVersion = ignoreTxVersion, ...)

  if (!is.null(outputFilepath)) {
    qs::qsave(txi, outputFilepath)}
  invisible(txi)}


#' @export
multiqc = function(
  parentDir = '.', outputDir = 'multiqc_output', cmd = 'multiqc', args = NULL) {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}
