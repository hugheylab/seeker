test_that('Test fastqc', {
  skip_on_os('windows', arch = NULL)
  step = 'fastqc'
  paramsNow = params[[step]]


  paramsNow[c('run', 'keep')] = NULL
  result = do.call(fastqc, c(
    list(filepaths = metadata[[fileColname]], outputDir = fastqcDir),
    paramsNow))

  fastqcFilesObs = list.files(fastqcDir, recursive = TRUE)
  fastqcFilesExp = snapshot(fastqcFilesObs, file.path(dataDir, 'fastqc_output.qs'))

  expect_equal(fastqcFilesObs, fastqcFilesExp)

})

test_that('Test trimgalore', {
  skip_on_os('windows', arch = NULL)
  step = 'trimgalore'
  paramsNow = params[[step]]

  paramsNow[c('run', 'keep')] = NULL

  result = do.call(trimgalore, c(
    list(filepaths = metadata[[fetchColname]], outputDir = trimDir),
    paramsNow))

  trimFilesObs = list.files(trimDir)
  trimFilesExp = snapshot(trimFilesObs, file.path(dataDir, 'trimgalore_output.qs'))

  expect_equal(trimFilesObs, trimFilesExp)
})

test_that('Test multiqc', {
  skip_on_os('windows', arch = NULL)
  step = 'multiqc'

  paramsNow = params[[step]]
  paramsNow$run = NULL

  result = do.call(multiqc, c(
    list(parentDir = outputDir, outputDir = multiqcDir), paramsNow))

  multiqcFilesObs = list.files(multiqcDir)
  multiqcFilesExp = snapshot(multiqcFilesObs, file.path(dataDir, 'multiqc_output.qs'))

  expect_equal(multiqcFilesObs, multiqcFilesExp)
})
