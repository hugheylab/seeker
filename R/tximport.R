#' Get mapping between transcripts and genes
#'
#' This function uses the
#' [biomaRt package](https://doi.org/doi:10.18129/B9.bioc.biomaRt).
#'
#' @param dataset Ensembl gene dataset, passed to [biomaRt::useEnsembl()]. To
#'   see which datasets are available, do
#'   `mart = biomaRt::useEnsembl('genes'); biomaRt::listDatasets(mart)`.
#' @param version Passed to [biomaRt::useEnsembl()].
#' @param outputDir Directory in which to save the result, a file named
#'   "tx2gene.csv". If `NULL`, no file is saved.
#'
#' @return A data.frame, as returned by [biomaRt::getBM()].
#'
#' @export
getTx2gene = function(
  dataset = 'mmusculus_gene_ensembl', version = NULL, outputDir = 'data') {
  # x = biomaRt::listEnsemblArchives()
  # version = max(as.integer(x$version[x$version != 'GRCh37']))
  outputFilename = 'tx2gene.csv'

  assertString(dataset)
  assertString(outputDir, null.ok = TRUE)
  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  mart = biomaRt::useEnsembl('ensembl', dataset, version = version)
  t2g = biomaRt::getBM(
    attributes = c('ensembl_transcript_id', 'ensembl_gene_id'), mart = mart)

  if (!is.null(outputDir)) {
    fwrite(t2g, file.path(outputDir, outputFilename))}
  return(t2g)}


#' Run tximport on RNA-seq quantifications
#'
#' This function uses the
#' [tximport package](https://doi.org/doi:10.18129/B9.bioc.tximport).
#'
#' @param inputDir Directory that contains the quantification directories.
#' @param tx2gene `NULL` or data.frame of mapping between transcripts and
#'   genes, as returned by [getTx2gene()], passed to [tximport::tximport()].
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
  inputDir, tx2gene, outputDir = 'data', type = c('salmon', 'kallisto'),
  countsFromAbundance = 'lengthScaledTPM', ignoreTxVersion = TRUE, ...) {

  outputFilename = 'tximport_output.qs'

  assertString(inputDir)
  assertDirectoryExists(inputDir)
  assertDataFrame(tx2gene, null.ok = TRUE)
  assertString(outputDir, null.ok = TRUE)
  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  type = match.arg(type)
  pat = switch(type, salmon = 'quant\\.sf$', kallisto = 'abundance\\.h5$')

  paths = dir(inputDir, pat, full.names = TRUE, recursive = TRUE)
  names(paths) = basename(dirname(paths))

  txi = tximport::tximport(
    paths, tx2gene = tx2gene, type = type,
    countsFromAbundance = countsFromAbundance,
    ignoreTxVersion = ignoreTxVersion, ...)

  if (!is.null(outputDir)) {
    qs::qsave(txi, file.path(outputDir, outputFilename))}
  invisible(txi)}
