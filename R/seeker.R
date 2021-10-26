#' @import checkmate
#' @importFrom foreach foreach %do% %dopar%
#' @importFrom data.table data.table fread fwrite set
NULL
# readr not explicitly called, but used by tximport


assertCommand = function(cmd, cmdName, defaultPath) {
  if (is.null(cmd)) {
    if (is.na(defaultPath)) {
      stop(sprintf('%s is not available at the default location.', cmdName))}
  } else {
    path = checkCommand(cmd)
    if (is.na(path)) {
      stop(sprintf("'%s' is not a valid command.", cmd))}}
  invisible()}


checkSeekerParams = function(params) {
  steps = c('metadata', 'fetch', 'trimgalore', 'fastqc', 'salmon', 'multiqc',
            'tximport')

  command = NULL
  defaultCommands = checkDefaultCommands()
  assertSetEqual(names(params), c('study', steps))
  assertString(params$study, min.chars = 1L)
  for (step in steps) {
    assertFlag(params[[step]]$run, .var.name = sprintf('params$%s$run', step))}

  if (params$tximport$run) {
    assertSubset(names(params$tximport),
                 c('run', 'tx2gene', 'countsFromAbundance', 'ignoreTxVersion'))

    assertList(params$tximport$tx2gene, any.missing = FALSE, null.ok = TRUE)
    if (!is.null(params$tximport$tx2gene)) {
      assertSetEqual(names(params$tximport$tx2gene), c('dataset', 'version'))
      assertString(params$tximport$tx2gene$dataset, min.chars = 1L)
      assertNumber(params$tximport$tx2gene$version)}

   assertString(params$tximport$countsFromAbundance, null.ok = FALSE)
   assertFlag(params$tximport$ignoreTxVersion, null.ok = TRUE)}

  if (params$multiqc$run) {
    assertSubset(names(params$multiqc), c('run', 'cmd', 'args'))
    assertString(params$multiqc$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$multiqc$cmd, 'multiqc',
                  defaultCommands[command == 'multiqc']$path)
    assertCharacter(params$multiqc$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$salmon$run) {
    assertSubset(names(params$salmon), c('run', 'indexDir', 'cmd', 'args'))
    assertString(params$salmon$indexDir, min.chars = 1L)
    assertDirectoryExists(params$salmon$indexDir)
    assertString(params$salmon$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$salmon$cmd, 'salmon',
                  defaultCommands[command == 'salmon']$path)
    assertCharacter(params$salmon$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$fastqc$run) {
    assertSubset(names(params$fastqc), c('run', 'cmd', 'args'))
    assertString(params$fastqc$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$fastqc$cmd, 'fastqc',
                  defaultCommands[command == 'fastqc']$path)
    assertCharacter(params$fastqc$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$trimgalore$run) {
    assertSubset(names(params$trimgalore), c('run', 'cmd', 'args'))
    assertString(params$trimgalore$cmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$trimgalore$cmd, 'trim_galore',
                  defaultCommands[command == 'trim_galore']$path)
    assertCharacter(params$trimgalore$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$fetch$run) {
    assertSubset(names(params$fetch),
                 c('run', 'overwrite', 'ascpCmd', 'ascpArgs', 'ascpPrefix'))
    assertFlag(params$fetch$overwrite, null.ok = TRUE)
    assertString(params$fetch$ascpCmd, min.chars = 1L, null.ok = TRUE)
    assertCommand(params$fetch$ascpCmd, 'ascp',
                  defaultCommands[command == 'ascp']$path)
    assertCharacter(params$fetch$ascpArgs, any.missing = FALSE, null.ok = TRUE)
    assertString(params$fetch$ascpPrefix, min.chars = 1L, null.ok = TRUE)}

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

  invisible()}


#' @export
seeker = function(params, parentDir = '.') {
  assertOS(c('linux', 'mac', 'solaris'))
  checkSeekerParams(params)

  assertString(parentDir)
  assertDirectoryExists(parentDir)
  outputDir = file.path(parentDir, params$study)
  if (!dir.exists(outputDir)) dir.create(outputDir)

  ####################
  step = 'metadata'
  # if run, expects bioproject to be a valid bioproject accession
  # if not run, expects a metadata file at
  # <parentDir>/<params$study>/data/metadata.csv
  paramsNow = params[[step]]
  dataDir = file.path(outputDir, 'data')
  metadataPath = file.path(dataDir, 'metadata.csv')

  if (paramsNow$run) {
    # host must be 'ena' to download fastq files using ascp
    metadata = getMetadata(paramsNow$bioproject)
    if (!dir.exists(dataDir)) dir.create(dataDir)
    fwrite(metadata, metadataPath) # could be overwritten
  } else {
    fread(metadataPath, na.strings = '')}

  # exclude supersedes include
  if (!is.null(paramsNow$include)) {
    idx = metadata[[paramsNow$include$colname]] %in% paramsNow$include$values
    metadata = metadata[idx]}

  if (!is.null(paramsNow$exclude)) {
    idx = metadata[[paramsNow$exclude$colname]] %in% paramsNow$exclude$values
    metadata = metadata[!idx]}

  ####################
  step = 'fetch'
  # if run, expects metadata to have a column 'fastq_aspera' containing remote
  # paths to download fastq.gz files by ascp
  # if not run, expects metadata to have a column 'fastq_aspera' containing
  # names (or complete paths, local or remote) of fastq.gz files
  paramsNow = params[[step]]
  fetchDir = file.path(outputDir, paste0(step, '_output'))
  inputColname = 'fastq_aspera'
  outputColname = 'fastq_fetched'

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(fetch, c(
      list(remoteFilepaths = metadata[[inputColname]], outputDir = fetchDir),
      paramsNow))
    set(metadata, j = outputColname, value = result$localFilepaths)

  } else {
    localFilepaths = getFileVec(
      lapply(getFileList(metadata[[inputColname]]),
             function(f) file.path(fetchDir, basename(f))))
    set(metadata, j = outputColname, value = localFilepaths)}

  fwrite(metadata, metadataPath) # could be overwritten

  ####################
  step = 'trimgalore'
  # if run, expects metadata to have a column 'fastq_fetched' containing local
  # paths to fastq.gz files
  # if not run, expects nothing
  paramsNow = params[[step]]
  trimDir = file.path(outputDir, paste0(step, '_output'))
  inputColname = outputColname
  outputColname = 'fastq_trimmed'

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(trimgalore, c(
      list(filepaths = metadata[[inputColname]], outputDir = trimDir),
      paramsNow))
    set(metadata, j = outputColname, value = result$fastq_trimmed)
    fwrite(metadata, metadataPath) # could be overwritten
  } #else {
    #set(metadata, j = outputColname, value = metadata[[inputColname]])}

  # fwrite(metadata, metadataPath) # could be overwritten

  ####################
  step = 'fastqc'
  # if run, if trimgalore run, expects metadata to have a column 'fastq_trimmed'
  # containing paths to fastq.gz files
  # if run, if trimgalore not run, expects metadata to have a column
  # 'fastq_fetched' containing paths to fastq.gz files
  # if not run, expects nothing
  paramsNow = params[[step]]
  fastqcDir = file.path(outputDir, paste0(step, '_output'))
  fileColname = if (params$trimgalore$run) outputColname else inputColname

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(fastqc, c(
      list(filepaths = metadata[[fileColname]], outputDir = fastqcDir),
      paramsNow))}

  ####################
  step = 'salmon'
  # if run and trimgalore run, expects metadata to have a column 'fastq_trimmed'
  # containing paths to fastq.gz files and a column 'sample_accession'
  # containing sample ids
  # if run and trimgalore not run, expects metadata to have a column
  # 'fastq_fetched' containing paths to fastq.gz files and a column
  # 'sample_accession' containing sample ids
  # if not run, expects nothing
  paramsNow = params[[step]]
  salmonDir = file.path(outputDir, paste0(step, '_output'))
  sampleColname = 'sample_accession'
  # 'sample_accession', unlike 'sample_alias', should be a valid name without
  # colons or spaces regardless of whether dataset originated from SRA or ENA

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(salmon, c(
      list(filepaths = metadata[[fileColname]],
           samples = metadata[[sampleColname]], outputDir = salmonDir),
      paramsNow))
    getSalmonMetadata(salmonDir, dataDir)}

  ####################
  step = 'multiqc'
  # if run or not run, expects nothing
  multiqcDir = file.path(outputDir, paste0(step, '_output'))

  if (params[[step]]$run) {
    paramsNow = params[[step]]
    paramsNow$run = NULL

    result = do.call(multiqc, c(
      list(parentDir = outputDir, outputDir = multiqcDir), paramsNow))}

  ####################
  step = 'tximport'
  # if run, expects a directory <parentDir>/<params$study>/salmon_output
  # containing directories of quantification results from salmon
  # if not run, expects nothing
  paramsNow = params[[step]]

  if (paramsNow$run) {
    paramsNow$run = NULL

    tx2gene = if (is.list(paramsNow$tx2gene)) {
      do.call(getTx2gene, c(list(outputDir = dataDir), paramsNow$tx2gene))
    } else {
      NULL}
    paramsNow$tx2gene = NULL

    result = do.call(tximport, c(
      list(inputDir = salmonDir, tx2gene = tx2gene, outputDir = dataDir),
      paramsNow))}

  ####################
  fwrite(metadata, metadataPath)
  invisible()}
