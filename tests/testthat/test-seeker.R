test_that('Test seeker', {
  skip_on_os('windows', arch = NULL)

  # Add unique folders for seeker full output
  parentDirSeeker = 'test_data/staging_seeker'
  dir.create(parentDirSeeker)
  withr::local_file(parentDirSeeker)
  file.copy('test_data/GSE143524', parentDirSeeker, recursive = TRUE)
  outputDirSeeker = file.path(parentDirSeeker, 'GSE143524')

  seeker(params, parentDirSeeker)

  seekerOutputObs = sort(list.files(outputDirSeeker, recursive = TRUE))
  seekerOutputControl = sort(readRDS('test_data/seeker_output_full.rds'))

  expect_equal(seekerOutputObs, seekerOutputControl)
})

test_that('Test seeker skip all', {
  skip_on_os('windows', arch = NULL)

  # Add unique folders for seeker skipped output
  paramsSkip = yaml::read_yaml('test_data/GSE143524_skip_all.yml')
  parentDirSeekerSkip = 'test_data/staging_seeker_skip'
  dir.create(parentDirSeekerSkip)
  withr::local_file(parentDirSeekerSkip)
  file.copy('test_data/GSE143524', parentDirSeekerSkip, recursive = TRUE)
  outputDirSeekerSkip = file.path(parentDirSeekerSkip, 'GSE143524')

  seeker(paramsSkip, parentDirSeekerSkip)

  seekerOutputObs = sort(list.files(outputDirSeekerSkip, recursive = TRUE))
  seekerOutputControl = sort(readRDS('test_data/seeker_output_skip.rds'))

  expect_equal(seekerOutputObs, seekerOutputControl)
})

test_that('Test checkSeekerArgs', {
  skip_on_os('windows', arch = NULL)
  outputDirObs = seeker:::checkSeekerArgs(params, parentDir)
  expect_equal(outputDirObs, outputDir)
})

