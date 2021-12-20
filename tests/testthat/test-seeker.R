test_that('Test seeker', {
  skip_on_os('windows', arch = NULL)

  # Add unique folders for seeker full output
  parentDirSeeker = file.path(testDir, 'staging_seeker')
  dir.create(parentDirSeeker)
  withr::local_file(parentDirSeeker)
  file.copy(file.path(testDir, 'GSE143524'), parentDirSeeker, recursive = TRUE)
  outputDirSeeker = file.path(parentDirSeeker, 'GSE143524')

  seeker(params, parentDirSeeker)

  seekerOutputObs = list.files(outputDirSeeker, recursive = TRUE)
  seekerOutputControl = snapshot(seekerOutputObs, file.path(testDir, 'seeker_output_full.qs'))

  expect_equal(seekerOutputObs, seekerOutputControl)
})

test_that('Test seeker skip all', {
  skip_on_os('windows', arch = NULL)

  # Add unique folders for seeker skipped output
  paramsSkip = yaml::read_yaml(file.path(testDir, 'GSE143524_skip_all.yml'))
  parentDirSeekerSkip = file.path(testDir, 'staging_seeker_skip')
  dir.create(parentDirSeekerSkip)
  withr::local_file(parentDirSeekerSkip)
  file.copy(file.path(testDir, 'GSE143524'), parentDirSeekerSkip, recursive = TRUE)
  outputDirSeekerSkip = file.path(parentDirSeekerSkip, 'GSE143524')

  seeker(paramsSkip, parentDirSeekerSkip)

  seekerOutputObs = list.files(outputDirSeekerSkip, recursive = TRUE)
  seekerOutputControl = snapshot(seekerOutputObs, file.path(testDir, 'seeker_output_skip.qs'))

  expect_equal(seekerOutputObs, seekerOutputControl)
})

test_that('Test checkSeekerArgs', {
  skip_on_os('windows', arch = NULL)
  outputDirObs = seeker:::checkSeekerArgs(params, parentDir)
  expect_equal(outputDirObs, outputDir)
})

