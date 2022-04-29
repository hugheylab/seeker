#' @import checkmate
#' @importFrom data.table data.table fread fwrite set setDT setnames
#' @importFrom foreach foreach %do% %dopar%
#' @importFrom glue glue
#' @importFrom RCurl getURL
NULL
# readr not called explicitly, but used by tximport


checkSeekerArgs = function(params, parentDir, dryRun = FALSE) {
  steps = c(
    'metadata', 'fetch', 'trimgalore', 'fastqc', 'salmon', 'multiqc', 'tximport')

  command = NULL
  defaultCommands = checkDefaultCommands()

  assertCollection = makeAssertCollection()

  assertList(params, add = assertCollection)
  assertNames(names(params), permutation.of = c('study', steps), add = assertCollection)
  assertString(params$study, min.chars = 1L, add = assertCollection)

  assertString(parentDir, add = assertCollection)
  assertDirectoryExists(parentDir, add = assertCollection)
  outputDir = file.path(parentDir, params$study)

  for (step in steps) {
    assertFlag(params[[step]]$run, .var.name = glue('params${step}$run'), add = assertCollection)}

  if (params$metadata$run) {
    assertNames(
      names(params$metadata),
      subset.of = c('run', 'bioproject', 'include', 'exclude'), add = assertCollection)
    assertString(params$metadata$bioproject, min.chars = 1L, add = assertCollection)

    assertList(params$metadata$include, any.missing = FALSE, null.ok = TRUE, add = assertCollection)
    if (!is.null(params$metadata$include)) {
      assertNames(names(params$metadata$include),
                  permutation.of = c('colname', 'values'), add = assertCollection)
      assertString(params$metadata$include$colname, min.chars = 1L, add = assertCollection)
      assertVector(params$metadata$include$values, strict = TRUE, add = assertCollection)}

    assertList(params$metadata$exclude, any.missing = FALSE, null.ok = TRUE, add = assertCollection)
    if (!is.null(params$metadata$exclude)) {
      assertNames(names(params$metadata$exclude),
                  permutation.of = c('colname', 'values'), add = assertCollection)
      assertString(params$metadata$exclude$colname, min.chars = 1L, add = assertCollection)
      assertVector(params$metadata$exclude$values, strict = TRUE, add = assertCollection)}}
  tryCatch(assert(checkFALSE(params$fetch$run),
                  checkTRUE(params$metadata$run),
                  checkFileExists(file.path(outputDir, 'metadata.csv')),
                  combine = 'or'),
           error = function(e) assertTRUE(e, add = assertCollection))

  if (params$fetch$run) {
    assertNames(
      names(params$fetch),
      subset.of = c(
        'run', 'keep', 'overwrite', 'keepSra', 'prefetchCmd', 'prefetchArgs',
        'fasterqdumpCmd', 'fasterqdumpArgs', 'pigzCmd', 'pigzArgs'), add = assertCollection)
    assertFlag(params$fetch$keep, null.ok = TRUE, add = assertCollection)
    assertFlag(params$fetch$overwrite, null.ok = TRUE, add = assertCollection)
    assertFlag(params$fetch$keepSra, null.ok = TRUE, add = assertCollection)

    assertString(params$fetch$prefetchCmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$fetch$prefetchCmd, 'prefetch',
                  defaultCommands[command == 'prefetch']$path, add = assertCollection)
    assertCharacter(params$fetch$prefetchArgs, any.missing = FALSE, null.ok = TRUE, add = assertCollection)

    assertString(params$fetch$fasterqdumpCmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$fetch$fasterqdumpCmd, 'fasterq-dump',
                  defaultCommands[command == 'fasterq-dump']$path, add = assertCollection)
    assertCharacter(params$fetch$fasterqdumpArgs, any.missing = FALSE, null.ok = TRUE, add = assertCollection)

    assertString(params$fetch$pigzCmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$fetch$pigzCmd, 'pigz',
                  defaultCommands[command == 'pigz']$path, add = assertCollection)
    assertCharacter(params$fetch$pigzArgs, any.missing = FALSE, null.ok = TRUE, add = assertCollection)}

    tryCatch(assert(checkFALSE(params$trimgalore$run),
                    checkTRUE(params$fetch$run),
                    checkDirectoryExists(file.path(outputDir, 'fetch_output')),
                    combine = 'or'),
             error = function(e) assertTRUE(e, add = assertCollection))

  if (params$trimgalore$run) {
    assertNames(names(params$trimgalore),
                subset.of = c('run', 'keep', 'cmd', 'args', 'pigzCmd'), add = assertCollection)
    assertFlag(params$trimgalore$keep, null.ok = TRUE, add = assertCollection)
    assertString(params$trimgalore$cmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$trimgalore$cmd, 'trim_galore',
                  defaultCommands[command == 'trim_galore']$path, add = assertCollection)
    assertCharacter(params$trimgalore$args, any.missing = FALSE, null.ok = TRUE, add = assertCollection)
    assertString(params$trimgalore$pigzCmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$trimgalore$pigzCmd, 'pigz',
                  defaultCommands[command == 'pigz']$path, add = assertCollection)}

  tryCatch(assert(checkFALSE(params$fastqc$run),
                  checkTRUE(params$trimgalore$run),
                  checkTRUE(params$fetch$run),
                  checkDirectoryExists(file.path(outputDir, 'fetch_output')),
                  combine = 'or'),
           error = function(e) assertTRUE(e, add = assertCollection))

  if (params$fastqc$run) {
    assertNames(names(params$fastqc), subset.of = c('run', 'keep', 'cmd', 'args'), add = assertCollection)
    assertFlag(params$fastqc$keep, null.ok = TRUE, add = assertCollection)
    assertString(params$fastqc$cmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$fastqc$cmd, 'fastqc',
                  defaultCommands[command == 'fastqc']$path, add = assertCollection)
    assertCharacter(params$fastqc$args, any.missing = FALSE, null.ok = TRUE, add = assertCollection)}

  assert(checkFALSE(params$salmon$run),
         checkTRUE(params$trimgalore$run),
         checkTRUE(params$fetch$run),
         checkDirectoryExists(file.path(outputDir, 'fetch_output')),
         combine = 'or')

  if (params$salmon$run) {
    assertNames(
      names(params$salmon),
      subset.of = c('run', 'indexDir', 'sampleColname', 'keep', 'cmd', 'args'), add = assertCollection)
    assertString(params$salmon$indexDir, min.chars = 1L, add = assertCollection)
    assertDirectoryExists(params$salmon$indexDir, add = assertCollection)
    assertString(params$salmon$sampleColname, null.ok = TRUE, add = assertCollection)
    assertFlag(params$salmon$keep, null.ok = TRUE, add = assertCollection)
    assertString(params$salmon$cmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$salmon$cmd, 'salmon',
                  defaultCommands[command == 'salmon']$path, add = assertCollection)
    assertCharacter(params$salmon$args, any.missing = FALSE, null.ok = TRUE, add = assertCollection)}

  if (params$multiqc$run) {
    assertNames(names(params$multiqc), subset.of = c('run', 'cmd', 'args'), add = assertCollection)
    assertString(params$multiqc$cmd, min.chars = 1L, null.ok = TRUE, add = assertCollection)
    assertCommand(params$multiqc$cmd, 'multiqc',
                  defaultCommands[command == 'multiqc']$path, add = assertCollection)
    assertCharacter(params$multiqc$args, any.missing = FALSE, null.ok = TRUE, add = assertCollection)}

  assert(checkFALSE(params$tximport$run),
         checkTRUE(params$salmon$run),
         checkDirectoryExists(file.path(outputDir, 'salmon_output')),
         combine = 'or')

  if (params$tximport$run) {
    assertNames(
      names(params$tximport),
      subset.of = c('run', 'tx2gene', 'countsFromAbundance', 'ignoreTxVersion'), add = assertCollection)
    assertList(params$tximport$tx2gene, any.missing = FALSE, null.ok = TRUE, add = assertCollection)

    if (!is.null(params$tximport$tx2gene)) {
      assert(checkNames(names(params$tximport$tx2gene), must.include = 'species',
                        subset.of = c('species', 'version')),
             checkNames(names(params$tximport$tx2gene), identical.to = 'filename'),
             combine = 'or')

      if ('species' %in% names(params$tximport$tx2gene)) {
        assertString(params$tximport$tx2gene$species, min.chars = 2L, add = assertCollection)
        assertNumber(params$tximport$tx2gene$version, null.ok = TRUE, add = assertCollection)
      } else {
        acLen = length(assertCollection)
        assertFileExists(file.path(outputDir, params$tximport$tx2gene$filename), add = assertCollection)
        if (acLen != length(assertCollection)) {
          tx2gene = fread(file.path(outputDir, params$tximport$tx2gene$filename))
          assertDataTable(
            tx2gene, types = 'character', any.missing = FALSE, ncols = 2L, add = assertCollection)}}}

    assertString(params$tximport$countsFromAbundance, null.ok = FALSE, add = assertCollection)
    assertFlag(params$tximport$ignoreTxVersion, null.ok = TRUE, add = assertCollection)}
  if(isFALSE(dryRun)) {
    reportAssertions(assertCollection)
  }
  returnList = list(outputDir = outputDir, assertCollection = assertCollection)
  return(returnList)}


#' Process RNA-seq data end to end
#'
#' This function selectively performs various steps to process RNA-seq data.
#'
#' @param params Named list of parameters with components:
#' * `study`: String used to name the output directory within `parentDir`.
#' * `metadata`: Named list with components:
#'   * `run`: Logical indicating whether to fetch metadata. See
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
#'   * `run`: Logical indicating whether to fetch files from SRA. See [fetch()].
#'     If `TRUE`, saves files to `parentDir`/`study`/fetch_output. Whether
#'     `TRUE` or `FALSE`, expects metadata to have a column "run_accession", and
#'     updates metadata with column "fastq_fetched" containing paths to files in
#'     `parentDir`/`study`/fetch_output. Following components are only checked
#'     if `run` is `TRUE`.
#'   * `keep`: Logical indicating whether to keep fastq.gz files when all
#'     processing steps have completed. `NULL` indicates `TRUE`.
#'   * `overwrite`: Logical indicating whether to overwrite files that already
#'     exist. `NULL` indicates to use the default in [fetch()].
#'   * `keepSra`: Logical indicating whether to keep the ".sra" files. `NULL`
#'     indicates to use the default in [fetch()].
#'   * `prefetchCmd`: String indicating command for prefetch, which downloads
#'     ".sra" files. `NULL` indicates to use the default in [fetch()].
#'   * `prefetchArgs`: Character vector indicating arguments to pass to
#'     prefetch. `NULL` indicates to use the default in [fetch()].
#'   * `fasterqdumpCmd`: String indicating command for fasterq-dump, which
#'     uses ".sra" files to create ".fastq" files. `NULL` indicates to use the
#'     default in [fetch()].
#'   * `prefetchArgs`: Character vector indicating arguments to pass to
#'     fasterq-dump. `NULL` indicates to use the default in [fetch()].
#'   * `pigzCmd`: String indicating command for pigz, which converts ".fastq"
#'     files to ".fastq.gz" files. `NULL` indicates to use the default in
#'     [fetch()].
#'   * `pigzArgs`: Character vector indicating arguments to pass to pigz. `NULL`
#'     indicates to use the default in [fetch()].
#' * `trimgalore`: Named list with components:
#'   * `run`: Logical indicating whether to perform quality/adapter trimming of
#'     reads. See [trimgalore()]. If `TRUE`, expects metadata to have a column
#'     "fastq_fetched" containing paths to fastq files in
#'     `parentDir`/`study`/fetch_output, saves trimmed files to
#'     `parentDir`/`study`/trimgalore_output, and updates metadata with column
#'     "fastq_trimmed". If `FALSE`, expects and does nothing. Following
#'     components are only checked if `run` is `TRUE`.
#'   * `keep`: Logical indicating whether to keep trimmed fastq files when all
#'     processing steps have completed. `NULL` indicates `TRUE`.
#'   * `cmd`: Name or path of the command-line interface. `NULL` indicates to
#'     use the default in [trimgalore()].
#'   * `args`: Additional arguments to pass to the command-line interface.
#'     `NULL` indicates to use the default in [trimgalore()].
#'   * `pigzCmd`: String indicating command for pigz, which converts ".fastq"
#'     files to ".fastq.gz" files. `NULL` indicates to use the default in
#'     [trimgalore()].
#' * `fastqc`: Named list with components:
#'   * `run`: Logical indicating whether to perform QC on reads. See [fastqc()].
#'     If `TRUE` and `trimgalore$run` is `TRUE`, expects metadata to have a
#'     column "fastq_trimmed" containing paths to fastq files in
#'     `parentDir`/`study`/trimgalore_output. If `TRUE` and `trimgalore$run` is
#'     `FALSE`, expects metadata to have a column "fastq_fetched" containing
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
#'     have a column "fastq_trimmed" containing paths to fastq files in
#'     `parentDir`/`study`/trimgalore_output. If `TRUE` and `trimgalore$run` is
#'     `FALSE`, expects metadata to have a column "fastq_fetched" containing
#'     paths to fastq files in `parentDir`/`study`/fetch_output. If `TRUE`,
#'     saves results to `parentDir`/`study`/salmon_output and
#'     `parentDir`/`study`/salmon_meta_info.csv. If `FALSE`, expects and does
#'     nothing. Following components are only checked if `run` is `TRUE`.
#'   * `indexDir`: Directory that contains salmon index.
#'   * `sampleColname`: String indicating column in metadata containing sample
#'     ids. `NULL` indicates "sample_accession", which should work for data
#'     from SRA and ENA.
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
#'     metadata to have a column `sampleColname` of sample ids, and expects a
#'     directory `parentDir`/`study`/salmon_output containing directories of
#'     quantification results, and saves results to
#'     `parentDir`/`study`/tximport_output.qs. If `FALSE`, expects and does
#'     nothing. Following components are only checked if `run` is `TRUE`.
#'   * `tx2gene`: Optional named list with components:
#'     * `species`: String indicating species and thereby ensembl gene dataset.
#'       See [getTx2gene()].
#'     * `version`: Optional number indicating ensembl version. `NULL` indicates
#'       the latest version. See [getTx2gene()].
#'     * `filename`: Optional string indicating name of pre-existing text file
#'       in `parentDir`/`params$study` containing mapping between transcripts
#'       (first column) and genes (second column), with column names in the
#'       first row. If `filename` is specified, `species` and `version` must not
#'       be specified.
#'
#'     If not `NULL`, saves a file `parentDir`/`study`/tx2gene.csv.gz.
#'   * `countsFromAbundance`: String indicating whether or how to estimate
#'     counts using estimated abundances. See [tximport::tximport()].
#'   * `ignoreTxVersion`: Logical indicating whether to the version suffix on
#'     transcript ids. `NULL` indicates to use `TRUE`. See
#'     [tximport::tximport()].
#'
#' `params` can be derived from a yaml file, see
#' \code{vignette("introduction", package = "seeker")}. The yaml representation
#' of `params` will be saved to `parentDir`/`params$study`/params.yml.
#' @param parentDir Directory in which to store the output, which will be a
#'   directory named according to `params$study`.
#' @param dryRun Boolean to determine if you want to actually run the functions
#'   or just validate your params and system requirements.
#'
#' @return Path to the output directory `parentDir`/`params$study`, invisibly.
#'
#' @seealso [fetchMetadata()], [fetch()], [trimgalore()], [fastqc()],
#'   [salmon()], [multiqc()], [tximport()]
#'
#' @export
seeker = function(params, parentDir = '.', dryRun = FALSE) {
  assertOS(c('linux', 'mac', 'solaris'))
  checkList = checkSeekerArgs(params, parentDir, dryRun)
  if(isTRUE(dryRun)) {
    msg = paste0("Results of dry run: ", paste0(checkList$assertCollection$getMessages(), collapse = "\n"))
    writeLines(msg, 'seeker_dryrun.log')
    print(msg)
    return(invisible())
  }
  if(length(checkList$assertCollection) > 0) {
    reportAssertions(checkList$assertCollection)
  }
  outputDir = checkList$outputDir
  # if (isTRUE(dryRun)) {
  #   print('Dry run results: ')
  #   print(checkResult$checkArgsList)
  #   return()
  # }
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
  # check salmon stuff before going further
  if (params$salmon$run) {
    sampleColname = params$salmon$sampleColname
    if (is.null(sampleColname)) sampleColname = 'sample_accession'
    assertChoice(sampleColname, colnames(metadata))
    # don't use 'strict', since the same sample could have multiple runs
    assertNames(metadata[[sampleColname]], type = 'ids')}

  ####################
  step = 'fetch'
  paramsNow = params[[step]]
  fetchDir = file.path(outputDir, paste0(step, '_output'))
  # remoteColname = 'fastq_aspera'
  remoteColname = 'run_accession'
  fetchColname = 'fastq_fetched'

  if (paramsNow$run) {
    paramsNow[c('run', 'keep')] = NULL
    # result = do.call(fetch, c(
    #   list(remoteFilepaths = metadata[[remoteColname]], outputDir = fetchDir),
    #   paramsNow))
    result = do.call(fetch, c(
      list(accessions = metadata[[remoteColname]], outputDir = fetchDir),
      paramsNow))
    set(metadata, j = fetchColname, value = result$localFilepaths)

  } else {
    # localFilepaths = getFileVec(
    #   lapply(getFileList(metadata[[remoteColname]]),
    #          function(f) file.path(fetchDir, basename(f))))
    localFilepaths = sapply(metadata[[remoteColname]], function(acc) {
      paste0(
        dir(fetchDir, glue('^{acc}(_1|_2|)\\.fastq\\.gz$'), full.names = TRUE),
        collapse = ';')})
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
  # sampleColname = 'sample_accession'
  # 'sample_accession', unlike 'sample_alias', should be a valid name without
  # colons or spaces regardless of whether dataset originated from SRA or ENA

  if (paramsNow$run) {
    paramsNow[c('run', 'keep', 'sampleColname')] = NULL
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
      if ('species' %in% names(paramsNow$tx2gene)) {
        tx2gene = do.call(getTx2gene, c(
          list(outputDir = outputDir), paramsNow$tx2gene))
        params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
      } else {
        tx2gene = fread(file.path(outputDir, paramsNow$tx2gene$filename))}
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

  invisible(outputDir)}
