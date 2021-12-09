test_that('Test seeker', {
  skip_on_os('windows', arch = NULL)
  seeker(params, parentDir)
  expect_true(file.exists(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv')))
  expect_equal(2L, nrow(fread(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv'))))
})

test_that('Test checkSeekerArgs', {
  skip_on_os('windows', arch = NULL)
  outputDirObs = seeker:::checkSeekerArgs(params, parentDir)
  expect_equal(outputDirObs, outputDir)
})

