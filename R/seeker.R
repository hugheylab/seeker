#' @import checkmate
#' @importFrom foreach foreach %do% %dopar%
#' @importFrom data.table data.table fread fwrite set
NULL
# readr not called explicitly, but used by tximport


checkSeekerArgs = function(params, parentDir) {
  steps = c('metadata', 'fetch', 'trimgalore', 'fastqc', 'salmon', 'multiqc',
            'tximport')

  command = NULL
  defaultCommands = checkDefaultCommands()
  assertSetEqual(names(params), c('study', steps))
  assertString(params$study, min.chars = 1L)

  assertString(parentDir)
  assertDirectoryExists(parentDir)
  outputDir = file.path(parentDir, params$study)

  for (step in steps) {
    assertFlag(params[[step]]$run, .var.name = sprintf('params$%s$run', step))}

  if (params$metadata$run) {
    assertSubset(names(params$metadata),
                 c('run', 'bioproject', 'include', 'exclude'))
    assertString(params$metadata$bioproject, min.chars = 1L)

    assertList(params$metadata$include, any.missing = FALSE, null.ok = TRUE)
    if (!is.null(params$metadata$include)) {
      assertSetEqual(names(params$metadata$include), c('colname', 'values'))
      assertString(params$metadata$include$colname, min.chars = 1L)
      assertVector(params$metadata$include$values, strict = TRUE)}

    assertList(params$metadata$exclude, any.missing = FALSE, null.ok = TRUE)
    if (!is.null(params$metadata$exclude)) {
      assertSetEqual(names(params$metadata$exclude), c('colname', 'values'))
      assertString(params$metadata$exclude$colname, min.chars = 1L)
      assertVector(params$metadata$exclude$values, strict = TRUE)}}

  assert(checkFALSE(params$fetch$run),
         checkTRUE(params$metadata$run),
         checkFileExists(file.path(outputDir, 'metadata.csv')),
         combine = 'or')

  if (params$fetch$run) {
    assertSubset(names(params$fetch),
                 c('run', 'keep', 'overwrite', 'ascpCmd', 'ascpArgs', 'ascpPrefix'))
    assertFlag(params$fetch$keep, null.ok = TRUE)
    assertFlag(params$fetch$overwrite, null.ok = TRUE)
    assertString(params$fetch$ascpCmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$fetch$ascpCmd, 'ascp',
                  defaultCommands[command == 'ascp']$path)
    assertCharacter(params$fetch$ascpArgs, any.missing = FALSE, null.ok = TRUE)
    assertString(params$fetch$ascpPrefix, min.chars = 1L, null.ok = TRUE)}

  assert(checkFALSE(params$trimgalore$run),
         checkTRUE(params$fetch$run),
         checkDirectoryExists(file.path(outputDir, 'fetch_output')),
         combine = 'or')

  if (params$trimgalore$run) {
    assertSubset(names(params$trimgalore), c('run', 'keep', 'cmd', 'args'))
    assertFlag(params$trimgalore$keep, null.ok = TRUE)
    assertString(params$trimgalore$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$trimgalore$cmd, 'trim_galore',
                  defaultCommands[command == 'trim_galore']$path)
    assertCharacter(params$trimgalore$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$fastqc$run) {
    assertSubset(names(params$fastqc), c('run', 'keep', 'cmd', 'args'))
    assertFlag(params$fastqc$keep, null.ok = TRUE)
    assertString(params$fastqc$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$fastqc$cmd, 'fastqc',
                  defaultCommands[command == 'fastqc']$path)
    assertCharacter(params$fastqc$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$salmon$run) {
    assertSubset(names(params$salmon),
                 c('run', 'indexDir', 'keep', 'cmd', 'args'))
    assertString(params$salmon$indexDir, min.chars = 1L)
    assertDirectoryExists(params$salmon$indexDir)
    assertFlag(params$salmon$keep, null.ok = TRUE)
    assertString(params$salmon$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$salmon$cmd, 'salmon',
                  defaultCommands[command == 'salmon']$path)
    assertCharacter(params$salmon$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$multiqc$run) {
    assertSubset(names(params$multiqc), c('run', 'cmd', 'args'))
    assertString(params$multiqc$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$multiqc$cmd, 'multiqc',
                  defaultCommands[command == 'multiqc']$path)
    assertCharacter(params$multiqc$args, any.missing = FALSE, null.ok = TRUE)}

  assert(checkFALSE(params$tximport$run),
         checkTRUE(params$salmon$run),
         checkDirectoryExists(file.path(outputDir, 'salmon_output')),
         combine = 'or')

  if (params$tximport$run) {
    assertSubset(names(params$tximport),
                 c('run', 'tx2gene', 'countsFromAbundance', 'ignoreTxVersion'))
    assertList(params$tximport$tx2gene, any.missing = FALSE, null.ok = TRUE)
    if (!is.null(params$tximport$tx2gene)) {
      assertSubset(names(params$tximport$tx2gene), c('species', 'version'))
      assertString(params$tximport$tx2gene$species, min.chars = 2L)
      assertNumber(params$tximport$tx2gene$version, null.ok = TRUE)}

    assertString(params$tximport$countsFromAbundance, null.ok = FALSE)
    assertFlag(params$tximport$ignoreTxVersion, null.ok = TRUE)}

  return(outputDir)}


#' Process RNA-seq data end to end
#'
#' This function selectively performs various steps to process RNA-seq data.
#'
#' @param params Named list of parameters with components:
#' * `study`: String used to name the output directory within `parentDir`.
#' * `metadata`: Named list with components:
#'   * `run`: Logical indicating whether to fetch metadata from ENA. See
#'     [fetchMetadata()]. If `TRUE`, saves a file
#'     `parentDir`/`study`/metadata.csv. If `FALSE`, expects that file to
#'     already exist. Following components are only checked if `run` is `TRUE`.
#'   * `bioproject`: String indicating the study's bioproject accession.
#'   * `include`: Optional named list for specifying which rows of metadata to
#'     include for further processing, with components:
#'     * `colname`: String indicating column in metadata
#'     * `values`: Vector indicating values within `colname`
#'   * `exclude`: Optional named list for specifying which rows of metadata to
#'     exclude from further processing (superseding `include`), with components:
#'     * `colname`: String indicating column in metadata
#'     * `values`: Vector indicating values within `colname`
#' * `fetch`: Named list with components:
#'   * `run`: Logical indicating whether to fetch fastq(.gz) files using ascp.
#'     See [fetch()]. If `TRUE`, expects metadata to have a column
#'     'fastq_aspera' containing remote paths, and saves files to
#'     `parentDir`/`study`/fetch_output. If `FALSE`, expects metadata to have a
#'     column 'fastq_aspera' containing names (or complete paths, local or
#'     remote) of fastq files. Whether `TRUE` or `FALSE`, updates metadata with
#'     column 'fastq_fetched' containing paths to files that should be in
#'     `parentDir`/`study`/fetch_output. Following components are only checked
#'     if `run` is `TRUE`.
#'   * `keep`: Logical indicating whether to keep fetched fastq files when all
#'     processing steps have completed. `NULL` indicates `TRUE`.
#'   * `overwrite`: Logical indicating whether to overwrite files that already
#'     exist. `NULL` indicates to use the default in [fetch()].
#'   * `ascpCmd`: String indicating path to ascp. `NULL` indicates to use the
#'     default in [fetch()].
#'   * `ascpArgs`: Character vector of arguments to pass to ascp. `NULL`
#'     indicates to use the default in [fetch()].
#'   * `ascpPrefix`: String indicating prefix for fetching files. `NULL`
#'     indicates to use the default in [fetch()].
#' * `trimgalore`: Named list with components:
#'   * `run`: Logical indicating whether to perform quality/adapter trimming of
#'     reads. See [trimgalore()]. If `TRUE`, expects metadata to have a column
#'     'fastq_fetched' containing paths to fastq files in
#'     `parentDir`/`study`/fetch_output, saves trimmed files to
#'     `parentDir`/`study`/trimgalore_output, and updates metadata with column
#'     'fastq_trimmed'. If `FALSE`, expects and does nothing. Following
#'     components are only checked if `run` is `TRUE`.
#'   * `keep`: Logical indicating whether to keep trimmed fastq files when all
#'     processing steps have completed. `NULL` indicates `TRUE`.
#'   * `cmd`: Name or path of the command-line interface. `NULL` indicates to
#'     use the default in [trimgalore()].
#'   * `args`: Additional arguments to pass to the command-line interface.
#'     `NULL` indicates to use the default in [trimgalore()].
#' * `fastqc`: Named list with components:
#'   * `run`: Logical indicating whether to perform QC on reads. See [fastqc()].
#'     If `TRUE` and `trimgalore$run` is `TRUE`, expects metadata to have a
#'     column 'fastq_trimmed' containing paths to fastq files in
#'     `parentDir`/`study`/trimgalore_output. If `TRUE` and `trimgalore$run` is
#'     `FALSE`, expects metadata to have a column 'fastq_fetched' containing
#'     paths to fastq files in `parentDir`/`study`/fetch_output. If `TRUE`,
#'     saves results to `parentDir`/`study`/fastqc_output. If `FALSE`, expects
#'     and does nothing. Following components are only checked if `run` is
#'     `TRUE`.
#'   * `keep`: Logical indicating whether to keep fastqc files when all
#'     processing steps have completed. `NULL` indicates `TRUE`.
#'   * `cmd`: Name or path of the command-line interface. `NULL` indicates to
#'     use the default in [fastqc()].
#'   * `args`: Additional arguments to pass to the command-line interface.
#'     `NULL` indicates to use the default in [fastqc()].
#' * `salmon`: Named list with components:
#'   * `run`: Logical indicating whether to quantify transcript abundances. See
#'     [salmon()]. If `TRUE` and `trimgalore$run` is `TRUE`, expects metadata to
#'     have a column 'fastq_trimmed' containing paths to fastq files in
#'     `parentDir`/`study`/trimgalore_output. If `TRUE` and `trimgalore$run` is
#'     `FALSE`, expects metadata to have a column 'fastq_fetched' containing
#'     paths to fastq files in `parentDir`/`study`/fetch_output. If `TRUE`, also
#'     expects metadata to have a column 'sample_accession' containing sample
#'     ids, and saves results to `parentDir`/`study`/salmon_output and
#'     `parentDir`/`study`/salmon_meta_info.csv. If `FALSE`, expects and does
#'     nothing. Following components are only checked if `run` is `TRUE`.
#'   * `indexDir`: Directory that contains salmon index.
#'   * `keep`: Logical indicating whether to keep quantification results when
#'     all processing steps have completed. `NULL` indicates `TRUE`.
#'   * `cmd`: Name or path of the command-line interface. `NULL` indicates to
#'     use the default in [salmon()].
#'   * `args`: Additional arguments to pass to the command-line interface.
#'     `NULL` indicates to use the default in [salmon()].
#' * `multiqc`: Named list with components:
#'   * `run`: Logical indicating whether to aggregrate results of various
#'     processing steps. See [multiqc()]. If `TRUE`, saves results to
#'     `parentDir`/`study`/multiqc_output. If `FALSE`, expects and does nothing.
#'     Following components are only checked if `run` is `TRUE`.
#'   * `cmd`: Name or path of the command-line interface. `NULL` indicates to
#'     use the default in [multiqc()].
#'   * `args`: Additional arguments to pass to the command-line interface.
#'     `NULL` indicates to use the default in [multiqc()].
#' * `tximport`: Named list with components:
#'   * `run`: Logical indicating whether to summarize transcript- or gene-level
#'     estimates for downstream analysis. See [tximport()]. If `TRUE`, expects
#'     metadata to have a column 'sample_accession' of sample ids, and expects a
#'     directory `parentDir`/`study`/salmon_output containing directories of
#'     quantification results, and saves results to
#'     `parentDir`/`study`/tximport_output.qs. If `FALSE`, expects and does
#'     nothing. Following components are only checked if `run` is `TRUE`.
#'   * `tx2gene`: Optional named list with components:
#'     * `species`: String indicating species and thereby ensembl gene dataset.
#'       See [getTx2gene()].
#'     * `version`: Optional number indicating ensembl version. `NULL` indicates
#'       the latest version. See [getTx2gene()].
#'
#'     If not `NULL`, saves a file `parentDir`/`study`/tx2gene.csv.gz.
#'   * `countsFromAbundance`: String indicating whether or how to estimate
#'     counts using estimated abundances. See [tximport::tximport()].
#'   * `ignoreTxVersion`: Logical indicating whether to the version suffix on
#'     transcript ids. `NULL` indicates to use `TRUE`. See
#'     [tximport::tximport()].
#'
#' `params` can be derived from a yaml file, see
#' \code{vignette('introduction', package = 'seeker')}. The yaml representation
#' of `params` will be saved to `parentDir`/`params$study`/params.yml.
#' @param parentDir Directory in which to store the output, which will be a
#'   directory named according to `params$study`.
#'
#' @return `NULL`, invisibly.
#'
#' @seealso [fetchMetadata()], [fetch()], [trimgalore()], [fastqc()],
#'   [salmon()], [multiqc()], [tximport()]
#'
#' @export
seeker = function(params, parentDir = '.') {
  assertOS(c('linux', 'mac', 'solaris'))
  outputDir = checkSeekerArgs(params, parentDir)
  if (!dir.exists(outputDir)) dir.create(outputDir)

  ####################
  step = 'metadata'
  paramsNow = params[[step]]
  metadataPath = file.path(outputDir, 'metadata.csv')

  if (paramsNow$run) {
    # host must be 'ena' to download fastq files using ascp
    metadata = fetchMetadata(paramsNow$bioproject)
    fwrite(metadata, metadataPath) # could be overwritten
  } else {
    metadata = fread(metadataPath, na.strings = '')}

  # exclude supersedes include
  if (!is.null(paramsNow$include)) {
    idx = metadata[[paramsNow$include$colname]] %in% paramsNow$include$values
    metadata = metadata[idx]}

  if (!is.null(paramsNow$exclude)) {
    idx = metadata[[paramsNow$exclude$colname]] %in% paramsNow$exclude$values
    metadata = metadata[!idx]}

  ####################
  step = 'fetch'
  paramsNow = params[[step]]
  fetchDir = file.path(outputDir, paste0(step, '_output'))
  remoteColname = 'fastq_aspera'
  fetchColname = 'fastq_fetched'

  if (paramsNow$run) {
    paramsNow[c('run', 'keep')] = NULL
    result = do.call(fetch, c(
      list(remoteFilepaths = metadata[[remoteColname]], outputDir = fetchDir),
      paramsNow))
    set(metadata, j = fetchColname, value = result$localFilepaths)

  } else {
    localFilepaths = getFileVec(
      lapply(getFileList(metadata[[remoteColname]]),
             function(f) file.path(fetchDir, basename(f))))
    set(metadata, j = fetchColname, value = localFilepaths)}

  fwrite(metadata, metadataPath) # could be overwritten

  ####################
  step = 'trimgalore'
  paramsNow = params[[step]]
  trimDir = file.path(outputDir, paste0(step, '_output'))
  trimColname = 'fastq_trimmed'

  if (paramsNow$run) {
    paramsNow[c('run', 'keep')] = NULL
    result = do.call(trimgalore, c(
      list(filepaths = metadata[[fetchColname]], outputDir = trimDir),
      paramsNow))
    set(metadata, j = trimColname, value = result$fastq_trimmed)
    fwrite(metadata, metadataPath)} # could be overwritten

  ####################
  step = 'fastqc'
  paramsNow = params[[step]]
  fastqcDir = file.path(outputDir, paste0(step, '_output'))
  fileColname = if (params$trimgalore$run) trimColname else fetchColname

  if (paramsNow$run) {
    paramsNow[c('run', 'keep')] = NULL
    result = do.call(fastqc, c(
      list(filepaths = metadata[[fileColname]], outputDir = fastqcDir),
      paramsNow))}

  ####################
  step = 'salmon'
  paramsNow = params[[step]]
  salmonDir = file.path(outputDir, paste0(step, '_output'))
  sampleColname = 'sample_accession'
  # 'sample_accession', unlike 'sample_alias', should be a valid name without
  # colons or spaces regardless of whether dataset originated from SRA or ENA

  if (paramsNow$run) {
    paramsNow[c('run', 'keep')] = NULL
    result = do.call(salmon, c(
      list(filepaths = metadata[[fileColname]],
           samples = metadata[[sampleColname]], outputDir = salmonDir),
      paramsNow))
    getSalmonMetadata(salmonDir, outputDir)}

  ####################
  step = 'multiqc'
  multiqcDir = file.path(outputDir, paste0(step, '_output'))

  if (params[[step]]$run) {
    paramsNow = params[[step]]
    paramsNow$run = NULL

    result = do.call(multiqc, c(
      list(parentDir = outputDir, outputDir = multiqcDir), paramsNow))}

  ####################
  step = 'tximport'
  paramsNow = params[[step]]

  if (paramsNow$run) {
    paramsNow$run = NULL

    if (is.list(paramsNow$tx2gene)) {
      tx2gene = do.call(getTx2gene, c(
        list(outputDir = outputDir), paramsNow$tx2gene))
      params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
      paramsNow$tx2gene = NULL # for calling tximport
    } else {
      tx2gene = NULL}

    # samples don't have to be unique here
    result = do.call(tximport, c(
      list(inputDir = salmonDir, tx2gene = tx2gene,
           samples = metadata[[sampleColname]], outputDir = outputDir),
      paramsNow))}

  ####################
  fwrite(metadata, metadataPath)
  yaml::write_yaml(params, file.path(outputDir, 'params.yml'))
  getRCondaInfo(outputDir)

  if (params$fetch$run && isFALSE(params$fetch$keep)) {
    unlink(unlist(getFileList(metadata[[fetchColname]])))}

  if (params$trimgalore$run && isFALSE(params$trimgalore$keep)) {
    unlink(unlist(getFileList(metadata[[trimColname]])))}

  if (params$fastqc$run && isFALSE(params$fastqc$keep)) {
    fastqcFilenames = getFastqcFilenames(metadata[[fileColname]])
    unlink(file.path(fastqcDir, fastqcFilenames))}

  if (params$salmon$run && isFALSE(params$salmon$keep)) {
    unlink(file.path(salmonDir, unique(metadata[[sampleColname]]), 'quant.sf*'),
           recursive = TRUE)}

  invisible()}
