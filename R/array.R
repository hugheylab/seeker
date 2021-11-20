checkSeekerArrayArgs = function(params, parentDir) {
  assertList(params)
  assertSetEqual(names(params), c('study', 'geneIdType'))
  assertString(params$study, min.chars = 1L)
  assertChoice(params$geneIdType, c('ensembl', 'entrez'))
  assertString(parentDir)
  assertDirectoryExists(parentDir)
  outputDir = file.path(path.expand(parentDir), params$study) # untar no like ~
  return(outputDir)}


#' Process microarray data end to end
#'
#' This function fetches data and metadata from NCBI GEO and ArrayExpress,
#' processes raw Affymetrix data using RMA and custom CDFs from Brainarray, and
#' maps probes to genes.
#'
#' @param params Named list of parameters with components:
#' * `study`: String indicating the study accession and used to name the output
#'   directory within `parentDir`. If `study` starts with 'GSE', data will be
#'   fetched using [GEOquery::getGEO()]. Otherwise the data will be fetched
#'   using [ArrayExpress::getAE()].
#' * `geneIdType`: String indicating whether to map probes to Ensembl Gene IDs
#'   ('ensembl') or Entrez Gene IDs ('entrez').
#'
#' `params` can be derived from a yaml file, see
#' \code{vignette('introduction', package = 'seeker')}. The yaml representation
#' of `params` will be saved to `parentDir`/`params$study`/params.yml.
#' @param parentDir Directory in which to store the output, which will be a
#'   directory named according to `params$study`.
#'
#' @return `NULL`, invisibly.
#'
#' @export
seekerArray = function(params, parentDir) {
  outputDir = checkSeekerArrayArgs(params, parentDir)
  if (!dir.exists(outputDir)) dir.create(outputDir)
  rawDir = file.path(outputDir, 'raw')

  withr::local_options(timeout = 600)
  withr::local_envvar(VROOM_CONNECTION_SIZE = 131072 * 20)

  repo = if (startsWith(params$study, 'GSE')) 'geo' else 'ae'

  result = if (repo == 'geo') {
    getNaiveEsetGeo(params$study, outputDir, rawDir)
  } else {
    getNaiveEsetAe(params$study, outputDir, rawDir)}

  if (is.character(result)) {
    warning(result)
    return(invisible())}
  eset = result[[1L]]
  rmaOk = result[[2L]]

    # expers = getAeMetadata(params$study, 'experiments')
    # if (nrow(expers) > 1) stop()
    # arrays = expers[1L]$arraydesign
    # if (length(arrays) > 1) stop()
    # platform = arrays[[1L]]$accession
    #
    # files = getAeMetadata(params$study, 'files')
    # if (!is.data.frame(files)) stop()
    # setDT(files)
    # hasRaw = any(files$kind == 'raw')
    # hasProc = any(sapply(files$kind, function(k) any(k == 'processed')))
    #
    # if ((platform %in% getPlatforms('cdf')$ae_accession) && hasRaw) {
    #   mage = ArrayExpress::getAE(params$study, path = outputDir, type = 'raw')
    #   eset = ArrayExpress::ae2bioc(mage)
    #   rmaOk = TRUE
    # } else {
    #   type = if (hasRaw && hasProc) 'full' else if (hasRaw) 'raw' else 'processed'
    #   mage = ArrayExpress::getAE(
    #     params$study, path = outputDir, type = type, extract = FALSE)
    #   warning(glue('Study {params$study} does not have raw data from a ',
    #                'supported Affymetrix array. You take it from here.'))
    #   return(invisible())}
    #
    # if (!is.null(mage$rawArchive)) {
    #   unlink(file.path(outputDir, mage$rawArchive))}
    #
    # if (!dir.exists(rawDir)) dir.create(rawDir)
    #
    # . = file.rename(file.path(outputDir, mage$rawFiles),
    #                 file.path(rawDir, mage$rawFiles))}

  qs::qsave(eset, file.path(outputDir, 'naive_expression_set.qs'))

  sampColname = 'sample_id'
  metadata = data.table(eset@phenoData@data, keep.rownames = sampColname)
  set(metadata, j = sampColname, value = stripFileExt(metadata[[sampColname]]))
  fwrite(metadata, file.path(outputDir, 'sample_metadata.csv'))

  if (rmaOk) {
    cdfname = getCdfname(eset@annotation, params$geneIdType)
    if (length(cdfname) == 0) {
      warning(glue(
        '{params$study} uses platform {eset@annotation}, which is ',
        'unsupported for mapping probes to genes using raw data.'))
      return(invisible())}

    if (!requireNamespace(cdfname, quietly = TRUE)) {
      installCustomCdfPackages(cdfname)}

    emat = seekerRma(rawDir, cdfname)
    colnames(emat) = getNewEmatColnames(colnames(emat), repo)
    emat = emat[, metadata[[sampColname]]]

    paths = dir(rawDir, '\\.cel$', full.names = TRUE, ignore.case = TRUE)
    for (path in paths) {
      R.utils::gzip(path, overwrite = TRUE)}

  } else {
    featureDt = data.table(eset@featureData@data)
    platforms = getPlatforms('mapping')
    platformDt = platforms[platforms$platform == eset@annotation]

    if (nrow(platformDt) == 0) {
      warning(glue(
        '{params$study} uses platform {eset@annotation}, which is ',
        'unsupported for mapping probes to genes using processed data.'))
      return(invisible())}

    mapping = getProbeGeneMapping(featureDt, platformDt, params$geneIdType)
    fwrite(mapping, file.path(outputDir, 'probe_gene_mapping.csv.gz'))
    emat = getEmatGene(eset@assayData$exprs, mapping)}

  qs::qsave(emat, file.path(outputDir, 'gene_expression_matrix.qs'))
  yaml::write_yaml(params, file.path(outputDir, 'params.yml'))
  sessioninfo::session_info(
    info = c('platform', 'packages'),
    to_file = file.path(outputDir, 'session.log'))

  invisible()}
