paramsArray = yaml::read_yaml(file.path(dataDir, 'GSE25585.yml'))
parentDirArr = file.path(dataDir, 'staging_seeker_array')
dir.create(parentDirArr)
withr::local_file(parentDirArr)

test_that('checkSeekerArrayArgs', {
  skip_on_os('windows', arch = NULL)

  resultObs = checkSeekerArrayArgs(paramsArray, parentDirArr)
  resultExp = snapshot(resultObs, file.path(dataDir, 'seeker_array_args_output.qs'))

  expect_equal(resultObs, resultExp)
})

test_that('checkSeekerArrayArgs errors', {
  skip_on_os('windows', arch = NULL)

  paramsArrayErr = paramsArray

  # GSE platform not null or GPL
  paramsArrayErr$platform = 'abcd'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirArr))

  # E- with platform
  paramsArrayErr$study = 'E-test'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirArr))

  # raw with raw dir not existing
  paramsArrayErr$study = 'LOCAL'
  paramsArrayErr$platform = 'GPL1'
  expect_error(checkSeekerArrayArgs(paramsArrayErr, parentDirArr))
})

test_that('seekerArray GSE', {
  skip_on_os('windows', arch = NULL)

  seekerArray(paramsArray, parentDirArr)

  resultObs = list.files(parentDirArr, recursive = TRUE)
  resultExp = snapshot(resultObs, file.path(dataDir, 'seeker_array_gse_output.qs'))

  expect_equal(resultObs, resultExp)
})

test_that('seekerArray Ae', {
  skip_on_os('windows', arch = NULL)

  parentDirArrAe = file.path(dataDir, 'staging_seeker_array_ae')
  dir.create(parentDirArrAe)
  withr::local_file(parentDirArrAe)
  paramsArrayAe = paramsArray
  paramsArrayAe$study = 'E-MTAB-8714'

  seekerArray(paramsArrayAe, parentDirArrAe)

  resultObs = list.files(parentDirArrAe, recursive = TRUE)
  resultExp = snapshot(resultObs, file.path(dataDir, 'seeker_array_ae_output.qs'))

  expect_equal(resultObs, resultExp)
})

test_that('seekerArray LOCAL', {
  skip_on_os('windows', arch = NULL)

  parentDirArrLcl = file.path(dataDir, 'staging_seeker_array_local')
  dir.create(parentDirArrLcl)
  withr::local_file(parentDirArrLcl)
  paramsArrayLocal = yaml::read_yaml(file.path(dataDir, 'LOCAL01.yml'))
  file.copy(file.path(dataDir, 'LOCAL01'), parentDirArrLcl, recursive = TRUE)

  seekerArray(paramsArrayLocal, parentDirArrLcl)

  resultObs = list.files(parentDirArrLcl, recursive = TRUE)
  resultExp = snapshot(resultObs, file.path(dataDir, 'seeker_array_local_output.qs'))

  expect_equal(resultObs, resultExp)
})
