test_that('Test fastqc', {
  skip("Skipping until done.")
  skip_on_os('windows', arch = NULL)
  step = 'fastqc'
  paramsNow = params[[step]]


  paramsNow[c('run', 'keep')] = NULL
  result = do.call(fastqc, c(
    list(filepaths = metadata[[fileColname]], outputDir = fastqcDir),
    paramsNow))
})

test_that('Test fastqscreen', {
  skip("Skipping until done.")

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
  trimFilesControl = snapshot(trimFilesObs, 'test_data/trimgalore_output.qs')

  expect_equal(trimFilesObs, trimFilesControl)

})

test_that('Test multiqc', {
  skip("Skipping until done.")

})
