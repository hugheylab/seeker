test_that("Test salmon and getSalmonMetadata", {
  skip_on_os('windows', arch = NULL)
  step = 'salmon'
  paramsNow = params[[step]]
  salmonDir = file.path(outputDir, paste0(step, '_output'))
  sampleColname = 'sample_accession'
  # 'sample_accession', unlike 'sample_alias', should be a valid name without
  # colons or spaces regardless of whether dataset originated from SRA or ENA

  paramsNow[c('run', 'keep')] = NULL
  result = do.call(salmon, c(
    list(filepaths = metadata[[fileColname]],
         samples = metadata[[sampleColname]], outputDir = salmonDir),
    paramsNow))
  salmonOutputObs = list.files(salmonDir, recursive = TRUE)
  salmonOutputControl = readRDS('test_data/salmon_output.rds')
  expect_equal(sort(salmonOutputObs), sort(salmonOutputControl))
  getSalmonMetadata(salmonDir, outputDir)
})
