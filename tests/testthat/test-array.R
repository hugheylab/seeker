paramsArray = yaml::read_yaml(file.path(dataDir, 'GSE25585.yml'))
parentDirSeekerArray = file.path(dataDir, 'staging_seeker_array')
dir.create(parentDirSeekerArray)
withr::local_file(parentDirSeekerArray)

test_that('checkSeekerArrayArgs', {
  skip_on_os('windows', arch = NULL)

  checkSeekerArrayArgsObs = checkSeekerArrayArgs(paramsArray, parentDirSeekerArray)

  checkSeekerArrayArgsExp = snapshot(checkSeekerArrayArgsObs, file.path(dataDir, 'seeker_array_args_output.qs'))

  expect_equal(checkSeekerArrayArgsObs, checkSeekerArrayArgsExp)
})

test_that('checkSeekerArrayArgs errors', {
  skip_on_os('windows', arch = NULL)

  paramsArrayErr = paramsArray

  # GSE platform not null or GPL
  paramsArrayErr$platform = 'abcd'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirSeekerArray))

  # E- with platform
  paramsArrayErr$study = 'E-test'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirSeekerArray))

  # raw with raw dir not existing
  paramsArrayErr$study = 'LOCAL'
  paramsArrayErr$platform = 'GPL1'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirSeekerArray))
})

test_that('seekerArray GSE', {
  skip_on_os('windows', arch = NULL)

  seekerArray(paramsArray, parentDirSeekerArray)

  seekerArrayOutputObs = list.files(parentDirSeekerArray, recursive = TRUE)
  seekerArrayOutputExp = snapshot(seekerArrayOutputObs, file.path(dataDir, 'seeker_array_output_full.qs'))

  expect_equal(seekerArrayOutputObs, seekerArrayOutputExp)
})

test_that('seekerArray Ae', {
  skip_on_os('windows', arch = NULL)

  parentDirSeekerArrayAe = file.path(dataDir, 'staging_seeker_array_ae')
  dir.create(parentDirSeekerArrayAe)
  withr::local_file(parentDirSeekerArrayAe)
  paramsArrayAe = paramsArray
  paramsArrayAe$study = 'E-MTAB-8714'

  seekerArray(paramsArrayAe, parentDirSeekerArrayAe)

  seekerArrayAeOutputObs = list.files(parentDirSeekerArrayAe, recursive = TRUE)
  seekerArrayAeOutputExp = snapshot(seekerArrayAeOutputObs, file.path(dataDir, 'seeker_array_ae_output_full.qs'))

  expect_equal(seekerArrayAeOutputObs, seekerArrayAeOutputExp)
})

test_that('seekerArray LOCAL', {
  skip_on_os('windows', arch = NULL)

  parentDirSeekerArrayLocal = file.path(dataDir, 'staging_seeker_array_local')
  dir.create(parentDirSeekerArrayLocal)
  withr::local_file(parentDirSeekerArrayLocal)
  paramsArrayLocal = yaml::read_yaml(file.path(dataDir, 'LOCAL01.yml'))
  file.copy(file.path(dataDir, 'LOCAL01'), parentDirSeekerArrayLocal, recursive = TRUE)

  seekerArray(paramsArrayLocal, parentDirSeekerArrayLocal)

  seekerArrayLocalOutputObs = list.files(parentDirSeekerArrayLocal, recursive = TRUE)
  seekerArrayLocalOutputExp = snapshot(seekerArrayLocalOutputObs, file.path(dataDir, 'seeker_array_local_output_full.qs'))

  expect_equal(seekerArrayLocalOutputObs, seekerArrayLocalOutputExp)
})

