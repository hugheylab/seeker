test_that("Test salmon and getSalmonMetadata", {
  skip("Skipping until done.")
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
  getSalmonMetadata(salmonDir, outputDir)
})
