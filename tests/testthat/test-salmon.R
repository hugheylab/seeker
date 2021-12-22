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
  salmonOutputControl = snapshot(salmonOutputObs, file.path(dataDir, 'salmon_output.qs'))
  expect_equal(sort(salmonOutputObs), sort(salmonOutputControl))

  excludeColumns = c('frag_length_mean', 'frag_length_sd', 'start_time',
                     'end_time', 'eq_class_properties', 'length_classes',
                     'salmon_version')
  salmonMetaObs = getSalmonMetadata(salmonDir, outputDir)[, .SD, .SDcols = !excludeColumns]
  salmonMetaControl = snapshot(salmonMetaObs, file.path(dataDir, 'salmon_meta_info.qs'))
  expect_equal(salmonMetaObs, salmonMetaControl)
})
