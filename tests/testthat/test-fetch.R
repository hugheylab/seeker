library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
if(Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/', '/Users/', params$salmon$indexDir)
params$fetch$run = FALSE
parentDir = 'test_data/staging'
dir.create(parentDir)
withr::local_file(parentDir)
file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
foreach::registerDoSEQ()

metadata = fread('test_data/metadata.csv')

test_that('Test fetchMetadata', {
  skip_on_os('windows', arch = NULL)
  originalColumns = c('study_accession', 'sample_accession', 'secondary_sample_accession',
                      'sample_alias', 'sample_title', 'experiment_accession',
                      'run_accession', 'fastq_md5', 'fastq_ftp', 'fastq_aspera')
  metadataControl = metadata[, ..originalColumns]
  outputDir = file.path(parentDir, 'GSE143524')
  if (!dir.exists(outputDir)) dir.create(outputDir)
  step = 'metadata'
  paramsNow = params[[step]]
  metadataObs = fetchMetadata(paramsNow$bioproject)

  idx = metadataObs[[paramsNow$include$colname]] %in% paramsNow$include$values
  metadataObs = metadataObs[idx]


  expect_equal(metadataObs, metadataControl)
  expect_true(grepl(';', metadataObs$fastq_aspera[1], fixed = TRUE))

  params2 = yaml::read_yaml('test_data/GSE159135.yml')
  paramsNow2 = params2[[step]]
  metadataObs2 = fetchMetadata(paramsNow2$bioproject)
  idx2 = metadataObs2[[paramsNow2$include$colname]] %in% paramsNow2$include$values
  metadataObs2 = metadataObs2[idx2]

  expect_false(grepl(';', metadataObs2$fastq_aspera[1], fixed = TRUE))

})

test_that('Test fetch', {
  skip_on_os('windows', arch = NULL)
  outputDir = file.path(parentDir, 'GSM5694054')
  if (!dir.exists(outputDir)) dir.create(outputDir)
  step = 'metadata'

  paramsFetch = yaml::read_yaml('test_data/GSM5694054.yml')
  paramsFetchNow = paramsFetch[[step]]
  metadataGSM = fetchMetadata(paramsFetchNow$bioproject, host = 'ena')
  idx = metadataGSM[[paramsFetchNow$include$colname]] %in% paramsFetchNow$include$values
  metadataGSM = metadataGSM[idx]

  step = 'fetch'
  paramsFetchNow = paramsFetch[[step]]
  fetchDir = file.path(outputDir, paste0(step, '_output'))
  remoteColname = 'fastq_aspera'
  fetchColname = 'fastq_fetched'
  paramsFetchNow[c('run', 'keep')] = NULL

  ascpCmd = getAscpCmd()
  ascpArgs = getAscpArgs()

  if(Sys.info()['sysname'] == "Darwin") {
    ascpCmd = '/Applications/Aspera Connect.app/Contents/Resources/ascp'

    a = c('-QT -l 300m -P33001 -i')
    f = 'asperaweb_id_dsa.openssh'
    ascpArgs = c(a, safe(file.path('/Applications/Aspera Connect.app/Contents/Resources', f)))}


  result = do.call(fetch, c(
    list(remoteFilepaths = metadataGSM[[remoteColname]], outputDir = fetchDir,
         ascpCmd = ascpCmd,
         ascpArgs = ascpArgs),
    paramsFetchNow))

  resultControl = fread('test_data/fetch_result.csv')

  expect_equal(result$localFilepaths, resultControl$localFilepaths)



})
