#' @importFrom foreach foreach
#' @importFrom foreach "%do%"
#' @importFrom foreach "%dopar%"


#' @export
getMetadata = function(study, downloadMethod = 'aspera') {
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
getFastq = function(remoteFilepaths, outputDir, ftpCmd = 'wget', ftpArgs = '-q',
                    asperaCmd = '~/.aspera/connect/bin/ascp',
                    asperaArgs = c('-QT -l 300m -P33001', '-i',
                                   '~/.aspera/connect/etc/asperaweb_id_dsa.openssh'),
                    asperaPrefix = 'era-fasp') {
  dir.create(outputDir, recursive = TRUE)

  if (is.list(remoteFilepaths)) {
    fs = unlist(remoteFilepaths)
    localFilepaths = lapply(remoteFilepaths,
                            function(f) file.path(outputDir, basename(f)))
  } else {
    fs = remoteFilepaths
    localFilepaths = file.path(outputDir, basename(remoteFilepaths))}

  result = foreach(f = fs, ii = 1:length(fs), .combine = c) %dopar% {
    if (startsWith(f, 'fasp')) {
      args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputDir)
      system2(path.expand(asperaCmd), args)
    } else {
      system2(path.expand(ftpCmd), c(ftpArgs, '-P', outputDir, f))}}
  return(list(localFilepaths = localFilepaths, exitCodes = result))}


checkFilepaths = function(filepaths) {
  if (!all(file.exists(unlist(filepaths)))) {
    stop('Not all supplied file paths exist.')}
  invisible(NULL)}


#' @export
fastqc = function(filepaths, outputDir = 'fastqc_output', cmd = 'fastqc',
                  args = c('-t', foreach::getDoParWorkers())) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)
  result = foreach(f = fs, ii = 1:length(fs), .combine = c) %do% {
    system2(path.expand(cmd), c(args, '-o', outputDir, f))}
  invisible(result)}


#' @export
fastqscreen = function(filepaths, outputDir = 'fastqscreen_output',
                       cmd = '~/fastq_screen_v0.13.0/fastq_screen',
                       args = c('--threads', foreach::getDoParWorkers(),
                                '--conf', '~/FastQ_Screen_Genomes/fastq_screen.conf')) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  fs = unlist(filepaths)
  result = foreach(f = fs, ii = 1:length(fs), .combine = c) %do% {
    system2(path.expand(cmd), c(args, '--outdir', outputDir, f))}
  invisible(result)}


#' @export
trimgalore = function(filepaths, outputDir = 'trimgalore_output',
                      cmd = 'trim_galore', args = '') {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  result = foreach(f = filepaths, .combine = c) %dopar% {
    argsNow = c(args, '-o', outputDir)
    if (length(f) > 1) {
      argsNow = c(argsNow, '--paired', f[1], f[2])
    } else {
      argsNow = c(argsNow, f)}
    system2(path.expand(cmd), argsNow)}
  invisible(result)}


#' @export
salmon = function(filepaths, ids, outputDir = 'salmon_output', cmd = 'salmon',
                  indexPath = '~/transcriptomes/homo_sapiens_transcripts',
                  args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
                           '-q --seqBias --gcBias --no-version-check')) {
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', args, '-i', indexPath)

  result = foreach(f = filepaths, id = ids, .combine = c) %do% {
    args1 = c(argsBase, '-o', file.path(outputDir, id))
    if (length(f) > 1) {
      args2 = c('-1', f[1], '-2', f[2])
    } else {
      args2 = c('-r', f)}
    system2(path.expand(cmd), c(args1, args2))}
  invisible(result)}


#' @export
tximport = function(dirpaths, outputFilename = 'tximport_output.rds',
                    ensemblDataset = 'hsapiens_gene_ensembl',
                    ensemblVersion = 94, type = 'salmon',
                    countsFromAbundance = 'lengthScaledTPM',
                    ignoreTxVersion = TRUE, ...) {
  # listEnsemblArchives()
  mart = biomaRt::useEnsembl('ensembl', ensemblDataset, version = ensemblVersion)
  t2g = biomaRt::getBM(attributes = c('ensembl_transcript_id', 'ensembl_gene_id'),
                       mart = mart)

  if (type == 'salmon') {
    filename = 'quant.sf'
  } else if (type == 'kallisto') {
    filename = 'abundance.h5'}

  filepaths = file.path(dirpaths, filename)
  names(filepaths) = basename(dirpaths)
  checkFilepaths(filepaths)
  txi = tximport::tximport(filepaths, tx2gene = t2g, type = type,
                           countsFromAbundance = countsFromAbundance,
                           ignoreTxVersion = ignoreTxVersion, ...)
  saveRDS(txi, file = outputFilename)
  invisible(txi)}


#' @export
multiqc = function(parentDir = '.', outputDir = 'multiqc_output',
                   cmd = 'multiqc', args = '') {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}
