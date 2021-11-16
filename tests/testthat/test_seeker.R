library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
params$fetch$run = FALSE
foreach::registerDoSEQ()
parentDir = 'test_data/staging'
parentDir2 = 'test_data/staging2'

test_that('Test seeker', {
  dir.create(parentDir)
  withr::local_file(parentDir)
  file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
  seeker(params, parentDir)
  expect_true(file.exists(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv')))
  expect_equal(2L, nrow(fread(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv'))))
})

test_that('Test checkSeekerArgs', {
  dir.create(parentDir2)
  withr::local_file(parentDir2)
  file.copy('test_data/GSE143524', parentDir2, recursive = TRUE)
  outputDirObs = seeker:::checkSeekerArgs(params, parentDir2)
  expect_equal(outputDirObs, file.path(parentDir2, 'GSE143524'))
})
