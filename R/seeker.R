#' @importFrom foreach foreach
#' @importFrom foreach "%do%"
#' @importFrom foreach "%dopar%"


#' @export
getMetadata = function(study, downloadMethod = 'aspera') {
  fastqColname = ifelse(downloadMethod == 'aspera', 'fastq_aspera', 'fastq_ftp')
  url = sprintf('%s%s%s%s%s%s','https://www.ebi.ac.uk/ena/data/warehouse/filereport?accession=',
                study, '&result=read_run&fields=sample_accession,secondary_sample_accession,',
                'experiment_accession,run_accession,', fastqColname, '&download=txt')
  raw = curl::curl_fetch_memory(url)
  metadata = data.frame(readr::read_tsv(rawToChar(raw$content)))
  colnames(metadata)[ncol(metadata)] = 'fastq'
  metadata$fastq = strsplit(metadata$fastq, ';')
  return(metadata)}


#' @export
getFastq = function(metadata, outputDir, ftpCmd = 'wget', ftpArgs = '-q',
                    asperaCmd = '~/.aspera/connect/bin/ascp',
                    asperaArgs = c('-QT -l 300m -P33001', '-i',
                                   '~/.aspera/connect/etc/asperaweb_id_dsa.openssh'),
                    asperaPrefix = 'era-fasp') {
  dir.create(outputDir, recursive = TRUE)
  files = unlist(metadata$fastq)
  downloadMethod = ifelse(startsWith(files[1], 'fasp'), 'aspera', 'ftp')

  result = foreach(f = files, ii = 1:length(files), .combine = c) %dopar% {
    if (downloadMethod == 'aspera') {
      args = c(asperaArgs, sprintf('%s@%s', asperaPrefix, f), outputDir)
      system2(path.expand(asperaCmd), args)
    } else {
      system2(path.expand(ftpCmd), c(ftpArgs, '-P', outputDir, f))}}
  invisible(result)}


#' @export
runFastqc = function(inputDir, outputDir = 'fastqc_output', cmd = 'fastqc',
                     args = c('-t', foreach::getDoParWorkers()),
                     fileExt = '.fastq.gz') {
  dir.create(outputDir, recursive = TRUE)
  filepaths = Sys.glob(file.path(inputDir, paste0('*', fileExt)))
  result = foreach(f = filepaths, ii = 1:length(filepaths), .combine = c) %do% {
    system2(path.expand(cmd), c(args, '-o', outputDir, f))}
  invisible(result)}


#' @export
runFastqscreen = function(inputDir, outputDir = 'fastqscreen_output',
                           cmd = '~/fastq_screen_v0.13.0/fastq_screen',
                           args = c('--threads', foreach::getDoParWorkers(),
                                    '--conf', '~/FastQ_Screen_Genomes/fastq_screen.conf'),
                           fileExt = '.fastq.gz') {
  dir.create(outputDir, recursive = TRUE)
  filepaths = Sys.glob(file.path(inputDir, paste0('*', fileExt)))
  result = foreach(f = filepaths, ii = 1:length(filepaths), .combine = c) %do% {
    system2(path.expand(cmd), c(args, '--outdir', outputDir, f))}
  invisible(result)}


#' @export
runSalmon = function(metadata, inputDir, outputDir = 'salmon_output', cmd = 'salmon',
                     indexPath = '~/transcriptomes/homo_sapiens_transcripts',
                     args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
                              '-q --seqBias --gcBias --no-version-check'),
                     idColname = 'run_accession') {
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', '-i', indexPath, args)

  pe = is.list(metadata$fastq)
  if (pe) {
    metadata$fastq_local = lapply(metadata$fastq,
                                  function(f) file.path(inputDir, basename(f)))
    idx = sapply(metadata$fastq_local, function(f) all(file.exists(f)))
  } else {
    metadata$fastq_local = file.path(inputDir, basename(metadata$fastq))
    idx = file.exists(metadata$fastq_local)}
  metadata = metadata[idx, , drop = FALSE]

  if (nrow(metadata) == 0) {
    stop('Insufficient sequencing files exist to run salmon.')}

  result = foreach(ii = 1:nrow(metadata), .combine = c) %do% {
    args1 = c(argsBase, '-o', file.path(outputDir, metadata[[idColname]][ii]))
    if (pe) {
      args2 = c('-1', metadata$fastq_local[[ii]][1],
                '-2', metadata$fastq_local[[ii]][2])
    } else {
      args2 = c('-r', metadata$fastq_local[ii])}
    system2(path.expand(cmd), c(args1, args2))}
  invisible(result)}


#' @export
runTximport = function(inputDir, outputFilename,
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

  filepaths = Sys.glob(file.path(inputDir, '*', filename))
  names(filepaths) = basename(dirname(filepaths))
  txi = tximport::tximport(filepaths, tx2gene = t2g, type = type,
                           countsFromAbundance = countsFromAbundance,
                           ignoreTxVersion = ignoreTxVersion, ...)
  saveRDS(txi, file = outputFilename)
  invisible(txi)}


#' @export
runMultiqc = function(parentDir = '.', outputDir = 'multiqc_output',
                      cmd = 'multiqc', args = '') {
  invisible(system2(path.expand(cmd), c(args, '-o', outputDir, parentDir)))}

