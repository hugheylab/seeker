test_that('Test trimgalore', {
  skip("Skipping until done.")
  skip_on_os('windows', arch = NULL)
  step = 'trimgalore'
  paramsNow = params[[step]]

  paramsNow[c('run', 'keep')] = NULL

  result = do.call(trimgalore, c(
    list(filepaths = metadata[[fetchColname]], outputDir = trimDir),
    paramsNow))
})

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

