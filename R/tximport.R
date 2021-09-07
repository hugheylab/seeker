
#' @export
getTx2gene = function(dataset = 'hsapiens_gene_ensembl', version = 104) {
  # x = biomaRt::listEnsemblArchives()
  # version = max(as.integer(x$version[x$version != 'GRCh37']))
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
