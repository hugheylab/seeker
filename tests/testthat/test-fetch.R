test_that('Test fetchMetadata', {
  skip_on_os('windows', arch = NULL)
  originalColumns = c('study_accession', 'sample_accession', 'secondary_sample_accession',
                      'sample_alias', 'sample_title', 'experiment_accession',
                      'run_accession', 'fastq_md5', 'fastq_ftp', 'fastq_aspera')
  metadataControl = metadata[, ..originalColumns]
  step = 'metadata'
  paramsNow = params[[step]]
  metadataObs = fetchMetadata(paramsNow$bioproject)

  idx = metadataObs[[paramsNow$include$colname]] %in% paramsNow$include$values
  metadataObs = metadataObs[idx]


  expect_equal(metadataObs, metadataControl)
  expect_true(grepl(';', metadataObs$fastq_aspera[1], fixed = TRUE))

  params2 = yaml::read_yaml(file.path(dataDir, 'GSE159135.yml'))
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

  paramsFetch = yaml::read_yaml(file.path(dataDir, 'GSM5694054.yml'))
  paramsFetchNow = paramsFetch[[step]]
  metadataGSM = fetchMetadata(paramsFetchNow$bioproject, host = 'ena')
  idx = metadataGSM[[paramsFetchNow$include$colname]] %in% paramsFetchNow$include$values
  metadataGSM = metadataGSM[idx]

  step = 'fetch'
  paramsFetchNow = paramsFetch[[step]]

  paramsFetchNow[c('run', 'keep')] = NULL


  result = do.call(fetch, c(
    list(remoteFilepaths = metadataGSM[[remoteColname]], outputDir = fetchDir),
    paramsFetchNow))


  print(result)
  file1 = paste0("./", strsplit(result$localFilepaths, ';')[[1]][1])
  file2 = paste0("./", strsplit(result$localFilepaths, ';')[[1]][2])
  print(file1)
  print(file2)


  expect_true(file.exists(file1))
  expect_true(file.exists(file2))



})
