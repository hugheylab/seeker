library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
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

test_that('Test fetchMetadata', {
  skip_on_os('windows', arch = NULL)
  originalColumns = c('study_accession', 'sample_accession', 'secondary_sample_accession',
                      'sample_alias', 'sample_title', 'experiment_accession',
                      'run_accession', 'fastq_md5', 'fastq_ftp', 'fastq_aspera')
  metadataControl = metadata[, ..originalColumns]
  outputDir = file.path(parentDir, 'GSE143524')
  if (!dir.exists(outputDir)) dir.create(outputDir)
  step = 'metadata'
  paramsNow = params[[step]]
  metadataObs = fetchMetadata(paramsNow$bioproject)

  idx = metadataObs[[paramsNow$include$colname]] %in% paramsNow$include$values
  metadataObs = metadataObs[idx]


  expect_equal(metadataObs, metadataControl)
  expect_true(grepl(';', metadataObs$fastq_aspera[1], fixed = TRUE))

  params2 = yaml::read_yaml('test_data/GSE159135.yml')
  paramsNow2 = params2[[step]]
  metadataObs2 = fetchMetadata(paramsNow2$bioproject)
  idx2 = metadataObs2[[paramsNow2$include$colname]] %in% paramsNow2$include$values
  metadataObs2 = metadataObs2[idx2]

  expect_false(grepl(';', metadataObs2$fastq_aspera[1], fixed = TRUE))

})
