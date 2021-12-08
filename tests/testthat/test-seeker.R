library('data.table')
params = yaml::read_yaml('test_data/GSE143524_josh.yml')
if(Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/', '/Users/', params$salmon$indexDir)
params$fetch$run = FALSE
parentDir = 'test_data/staging'
dir.create(parentDir)
withr::local_file(parentDir)
file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
foreach::registerDoSEQ()

metadata = fread('test_data/metadata.csv')

test_that('Test seeker', {
  skip_on_os('windows', arch = NULL)
  seeker(params, parentDir)
  expect_true(file.exists(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv')))
  expect_equal(2L, nrow(fread(file.path(parentDir, 'GSE143524', 'salmon_meta_info.csv'))))
})

test_that('Test checkSeekerArgs', {
  skip_on_os('windows', arch = NULL)
  outputDirObs = seeker:::checkSeekerArgs(params, parentDir)
  expect_equal(outputDirObs, file.path(parentDir, 'GSE143524'))
})

