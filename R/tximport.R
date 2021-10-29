#' Get mapping between transcripts and genes
#'
#' This function uses the
#' [biomaRt package](https://doi.org/doi:10.18129/B9.bioc.biomaRt).
#'
#' @param species String used to pass `paste0(species, '_gene_ensembl')` as the
#'   `dataset` argument to [biomaRt::useEnsembl()]. To see available datasets,
#'   do `mart = biomaRt::useEnsembl('genes'); biomaRt::listDatasets(mart)`.
#' @param version Passed to [biomaRt::useEnsembl()]. `NULL` indicates the latest
#'   version. To see available versions, do `biomaRt::listEnsemblArchives()`.
#' @param outputDir Directory in which to save the result, a file named
#'   "tx2gene.csv.gz". If `NULL`, no file is saved.
#'
#' @return A data.table based on the result from [biomaRt::getBM()], with an
#'   attribute 'version'.
#'
#' @export
getTx2gene = function(
  species = 'mmusculus', version = NULL, outputDir = 'data') {

  if (is.null(version)) {
    arch = data.table::setDT(biomaRt::listEnsemblArchives())
    version = arch[arch$current_release == '*']$version}

  assertString(species)
  assert(checkNumber(version), checkString(version)) # useEnsembl allows both
  assertString(outputDir, null.ok = TRUE)

  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  dataset = paste0(species, '_gene_ensembl')
  mart = biomaRt::useEnsembl('genes', dataset, version = version)
  attribs = c('ensembl_transcript_id', 'ensembl_gene_id')
  t2g = data.table::setDT(biomaRt::getBM(attributes = attribs, mart = mart))
  data.table::setattr(t2g, 'version', version)

  if (!is.null(outputDir)) {
    fwrite(t2g, file.path(outputDir, 'tx2gene.csv.gz'))}
  return(t2g)}


#' Run tximport on RNA-seq quantifications
#'
#' This function uses the
#' [tximport package](https://doi.org/doi:10.18129/B9.bioc.tximport).
#'
#' @param inputDir Directory that contains the quantification directories.
#' @param tx2gene `NULL` or data.frame of mapping between transcripts and
#'   genes, as returned by [getTx2gene()], passed to [tximport::tximport()].
#' @param samples Names of quantification directories to include. `NULL`
#'   indicates all.
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
  inputDir, tx2gene, samples = NULL, outputDir = 'data',
  type = c('salmon', 'kallisto'), countsFromAbundance = 'lengthScaledTPM',
  ignoreTxVersion = TRUE, ...) {

  assertString(inputDir)
  assertDirectoryExists(inputDir)
  assertDataFrame(tx2gene, null.ok = TRUE)
  assertCharacter(samples, null.ok = TRUE)
  assertString(outputDir, null.ok = TRUE)
  if (!is.null(outputDir)) {
    assertPathForOutput(outputDir, overwrite = TRUE)
    if (!dir.exists(outputDir)) dir.create(outputDir, recursive = TRUE)}

  type = match.arg(type)
  pat = switch(type, salmon = 'quant\\.sf$', kallisto = 'abundance\\.h5$')

  paths = dir(inputDir, pat, full.names = TRUE, recursive = TRUE)
  names(paths) = basename(dirname(paths))

  if (!is.null(samples)) {
    paths = paths[names(paths) %in% samples]} # ok if samples has duplicates

  txi = tximport::tximport(
    paths, tx2gene = tx2gene, type = type,
    countsFromAbundance = countsFromAbundance,
    ignoreTxVersion = ignoreTxVersion, ...)

  if (!is.null(outputDir)) {
    qs::qsave(txi, file.path(outputDir, 'tximport_output.qs'))}
  invisible(txi)}
