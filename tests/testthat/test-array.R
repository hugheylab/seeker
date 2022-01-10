paramsArray = yaml::read_yaml(file.path(dataDir, 'GSE25585.yml'))
parentDirSeekerArray = file.path(dataDir, 'staging_seeker_array')
dir.create(parentDirSeekerArray)
withr::local_file(parentDirSeekerArray)

test_that('seekerArray', {
  skip_on_os('windows', arch = NULL)

  seekerArray(paramsArray, parentDirSeekerArray)

  seekerArrayOutputObs = list.files(parentDirSeekerArray, recursive = TRUE)
  seekerArrayOutputExp = snapshot(seekerArrayOutputObs, file.path(dataDir, 'seeker_array_output_full.qs'))

  expect_equal(seekerArrayOutputObs, seekerArrayOutputExp)
})

