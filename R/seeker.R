checkSeekerParams = function(params) {
  steps = c('metadata', 'fetch', 'trimgalore', 'fastqc', 'salmon', 'multiqc',
            'tximport')

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
    assertCharacter(params$multiqc$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$salmon$run) {
    assertSubset(names(params$salmon), c('run', 'indexDir', 'cmd', 'args'))
    assertString(params$salmon$indexDir, min.chars = 1L)
    assertDirectoryExists(params$salmon$indexDir)
    assertString(params$salmon$cmd, min.chars = 1L, null.ok = TRUE)
    assertCharacter(params$salmon$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$fastqc$run) {
    assertSubset(names(params$fastqc), c('run', 'cmd', 'args'))
    assertString(params$fastqc$cmd, min.chars = 1L, null.ok = TRUE)
    assertCharacter(params$fastqc$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$trimgalore$run) {
    assertSubset(names(params$trimgalore), c('run', 'cmd', 'args'))
    assertString(params$trimgalore$cmd, min.chars = 1L, null.ok = TRUE)
    assertCharacter(params$trimgalore$args, any.missing = FALSE, null.ok = TRUE)}

  if (params$fetch$run) {
    assertSubset(names(params$fetch), c('run', 'cmd', 'args'))
    assertFlag(params$fetch$overwrite, null.ok = TRUE)
    assertString(params$fetch$asperaCmd, min.chars = 1L, null.ok = TRUE)
    assertCharacter(params$fetch$asperaArgs, any.missing = FALSE, null.ok = TRUE)
    assertString(params$fetch$asperaPrefix, min.chars = 1L, null.ok = TRUE)}

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
  checkSeekerParams(params)

  assertString(parentDir)
  assertDirectoryExists(parentDir)
  outputDir = file.path(parentDir, params$study)
  if (!dir.exists(outputDir)) dir.create(outputDir)

  ####################
  step = 'metadata'
  paramsNow = params[[step]]
  dataDir = file.path(outputDir, 'data')
  metadataPath = file.path(dataDir, 'metadata.csv')

  if (paramsNow$run) {
    # host must be 'ena' to download fastq files using aspera
    metadata = getMetadata(paramsNow$bioproject)
    if (!dir.exists(dataDir)) dir.create(dataDir)
    data.table::fwrite(metadata, metadataPath) # could be overwritten
  } else {
    data.table::fread(metadataPath, na.strings = '')}

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
  inputColname = 'fastq_aspera'
  outputColname = 'fastq_local'

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(fetch, c(
      list(remoteFilepaths = metadata[[inputColname]],
           outputDir = fetchDir),
      paramsNow))
    set(metadata, j = outputColname, value = result$localFilepaths)

  } else {
    localFilepaths = getFileVec(
      lapply(getFileList(metadata[[inputColname]]),
             function(f) file.path(fetchDir, basename(f))))
    set(metadata, j = outputColname, value = localFilepaths)}

  data.table::fwrite(metadata, metadataPath) # could be overwritten

  ####################
  step = 'trimgalore'
  paramsNow = params[[step]]
  trimDir = file.path(outputDir, paste0(step, '_output'))
  inputColname = 'fastq_local'
  outputColname = 'fastq_trimmed'

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(trimgalore, c(
      list(filepaths = metadata[[inputColname]],
           outputDir = trimDir),
      paramsNow))
    set(metadata, j = outputColname, value = result$fastq_trimmed)

  } else {
    set(metadata, j = outputColname, value = metadata[[inputColname]])}

  data.table::fwrite(metadata, metadataPath) # could be overwritten

  ####################
  step = 'fastqc'
  paramsNow = params[[step]]
  fastqcDir = file.path(outputDir, paste0(step, '_output'))
  inputColname = 'fastq_trimmed'

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(fastqc, c(
      list(filepaths = metadata[[inputColname]],
           outputDir = fastqcDir),
      paramsNow))}

  ####################
  step = 'salmon'
  paramsNow = params[[step]]
  salmonDir = file.path(outputDir, paste0(step, '_output'))
  fileColname = 'fastq_trimmed'
  sampleColname = 'sample_accession'
  # 'sample_accession', unlike 'sample_alias', should be a valid name without
  # colons or spaces regardless of whether dataset originated from SRA or ENA

  if (paramsNow$run) {
    paramsNow$run = NULL
    result = do.call(salmon, c(
      list(filepaths = metadata[[fileColname]],
           samples = metadata[[sampleColname]],
           outputDir = salmonDir),
      paramsNow))
    getSalmonMetadata(salmonDir, dataDir)}

  ####################
  step = 'multiqc'
  multiqcDir = file.path(outputDir, paste0(step, '_output'))

  if (params[[step]]$run) {
    paramsNow = params[[step]]
    paramsNow$run = NULL

    result = do.call(multiqc, c(
      list(parentDir = outputDir,
           outputDir = multiqcDir),
      paramsNow))}

  ####################
  step = 'tximport'
  paramsNow = params[[step]]

  if (paramsNow$run) {
    paramsNow$run = NULL

    tx2gene = if (is.list(paramsNow$tx2gene)) {
      do.call(getTx2gene, c(
        list(outputDir = dataDir),
        paramsNow$tx2gene))
    } else {
      NULL}
    paramsNow$tx2gene = NULL

    result = do.call(tximport, c(
      list(inputDir = salmonDir,
           tx2gene = tx2gene,
           outputDir = dataDir),
      paramsNow))}

  ####################
  data.table::fwrite(metadata, metadataPath)
  invisible()}
