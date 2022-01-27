test_that('fetchMetadata', {
  skip_on_os('windows', arch = NULL)
  step = 'metadata'
  paramsNow = params[[step]]

  metadataObs = fetchMetadata(paramsNow$bioproject)
  idx = metadataObs[[paramsNow$include$colname]] %in% paramsNow$include$values
  metadataObs = metadataObs[idx]

  metadataExp = snapshot(metadataObs, file.path(dataDir, 'fetch_metadata_output.qs'))

  expect_equal(metadataObs, metadataExp)

  # Test on another bioproject
  params2 = yaml::read_yaml(file.path(dataDir, 'GSE159135.yml'))
  paramsNow2 = params2[[step]]
  metadataObs2 = fetchMetadata(paramsNow2$bioproject)
  idx2 = metadataObs2[[paramsNow2$include$colname]] %in% paramsNow2$include$values
  metadataObs2 = metadataObs2[idx2]

  metadataExp2 = snapshot(metadataObs2, file.path(dataDir, 'fetch_metadata_output_2.qs'))

  expect_equal(metadataObs2, metadataExp2)
})

test_that('fetch', {
  skip("Skipping until aspera command error can be pinned down/solved")
  skip_if(!commandsDt[filename == 'ascp',]$exists, 'Missing ascp command, skipping.')
  skip_on_os('windows', arch = NULL)
  outputDirFetchTest = file.path(parentDir, 'GSM5694054')
  if (!dir.exists(outputDirFetchTest)) dir.create(outputDirFetchTest)
  step = 'metadata'

  paramsFetch = yaml::read_yaml(file.path(dataDir, 'GSM5694054.yml'))
  paramsFetchNow = paramsFetch[[step]]
  metadataGSM = fetchMetadata(paramsFetchNow$bioproject, host = 'ena')
  idx = metadataGSM[[paramsFetchNow$include$colname]] %in% paramsFetchNow$include$values
  metadataGSM = metadataGSM[idx]

  step = 'fetch'
  paramsFetchNow = paramsFetch[[step]]

  paramsFetchNow[c('run', 'keep')] = NULL

  resultObs = do.call(fetch, c(
    list(remoteFilepaths = metadataGSM[[remoteColname]], outputDir = outputDirFetchTest),
    paramsFetchNow))

  resultExp = snapshot(resultObs, file.path(dataDir, 'fetch_output_testing.qs'))

  expect_equal(resultObs, resultExp)

  for (file in strsplit(resultExp$localFilepaths, ';')[[1]]) {
    expect_true(file.exists(file))
  }
})
