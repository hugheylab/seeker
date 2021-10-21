#' Get mapping between transcripts and genes
#'
#' This function uses the
#' [biomaRt package](https://doi.org/doi:10.18129/B9.bioc.biomaRt).
#'
#' @param dataset Ensembl gene dataset, passed to [biomaRt::useEnsembl()]. To
#'   see which datasets are available, do
#'   `mart = useEnsembl('genes'); listDatasets(mart)`.
#' @param outputDir Directory in which to save the result, a file named
#'   "tx2gene.csv". If `NULL`, no file is saved.
#' @param ... Additional arguments passed to [biomaRt::useEnsembl()].
#'
#' @return A data.frame, as returned by [biomaRt::getBM()].
#'
#' @export
getTx2gene = function(
  dataset = 'hsapiens_gene_ensembl', outputDir = '.', ...) {
  # x = biomaRt::listEnsemblArchives()
  # version = max(as.integer(x$version[x$version != 'GRCh37']))
  outputFilename = 'tx2gene.csv'

  assertString(dataset)
  assertString(outputDir, null.ok = TRUE)
  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  mart = biomaRt::useEnsembl('ensembl', dataset, ...)
  t2g = biomaRt::getBM(
    attributes = c('ensembl_transcript_id', 'ensembl_gene_id'), mart = mart)

  if (!is.null(outputDir)) {
    data.table::fwrite(t2g, file.path(outputDir, outputFilename))}
  return(t2g)}


#' Run tximport on RNA-seq quantifications
#'
#' This function uses the
#' [tximport package](https://doi.org/doi:10.18129/B9.bioc.tximport).
#'
#' @param dirpaths Paths to directories that contain quantification results.
#' @param tx2gene Data.frame, as returned by [getTx2gene()], passed to
#'   [tximport::tximport()].
#' @param outputDir Directory in which to save the result, a file named
#'   "tximport_output.qs", using [qs::qsave()]. If `NULL`, no file is saved.
#' @param type Passed to [tximport::tximport()].
#' @param countsFromAbundance Passed to [tximport::tximport()].
#' @param ignoreTxVersion Passed to [tximport::tximport()].
#' @param ... Additional arguments passed to [tximport::tximport()].
#'
#' @return A list, as returned by [tximport::tximport()], invisibly.
#'
#' @export
tximport = function(
  dirpaths, tx2gene, outputDir = '.', type = c('salmon', 'kallisto'),
  countsFromAbundance = 'lengthScaledTPM', ignoreTxVersion = TRUE, ...) {

  outputFilename = 'tximport_output.qs'

  assertDataFrame(tx2gene)
  assertString(outputDir, null.ok = TRUE)
  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  type = match.arg(type)
  filename = switch(type, salmon = 'quant.sf', kallisto = 'abundance.h5')

  filepaths = file.path(dirpaths, filename)
  names(filepaths) = basename(dirpaths)
  assertFileExists(filepaths)

  txi = tximport::tximport(
    filepaths, tx2gene = tx2gene, type = type,
    countsFromAbundance = countsFromAbundance,
    ignoreTxVersion = ignoreTxVersion, ...)

  if (!is.null(outputDir)) {
    qs::qsave(txi, file.path(outputDir, outputFilename))}
  invisible(txi)}
