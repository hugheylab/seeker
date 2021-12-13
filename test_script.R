library('seeker')
library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
if (Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/',
                                                                     '/Users/',
                                                                     params$salmon$indexDir)
if (Sys.info()['user'] != 'runner') params$salmon$indexDir = gsub('/runner/',
                                                                  paste0('/', Sys.info()['user'], '/'),
                                                                  params$salmon$indexDir)
params$fetch$run = FALSE
parentDir = 'test_data/staging'
dir.create(parentDir)
withr::local_file(parentDir)
file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
foreach::registerDoSEQ()

outputDir = seeker:::checkSeekerArgs(params, parentDir)
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
  localFilepaths = seeker:::getFileVec(
    lapply(seeker:::getFileList(metadata[[remoteColname]]),
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