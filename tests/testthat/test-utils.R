test_that('Test getAscpCmd', {
  ascpCmdObs = getAscpCmd()

  ascpCmdControl = snapshot(ascpCmdObs, file.path(dataDir, paste0(os, '_get_ascp_cmd_output.qs')))

  expect_equal(ascpCmdObs, ascpCmdControl)
})

test_that('Test getAscpArgs', {
  ascpArgsObs = getAscpArgs()

  ascpArgsControl = snapshot(ascpArgsObs, file.path(dataDir, paste0(os, '_get_ascp_args_output.qs')))

  expect_equal(ascpArgsObs, ascpArgsControl)
})
