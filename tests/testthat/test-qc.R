library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
if(Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/', '/Users/', params$salmon$indexDir)
params$fetch$run = FALSE
parentDir = 'test_data/staging'
dir.create(parentDir)
withr::local_file(parentDir)
file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
foreach::registerDoSEQ()
outputDir = file.path(parentDir, 'GSE143524')

metadata = fread('test_data/metadata.csv')

test_that('Test trimgalore', {
  skip_on_os('windows', arch = NULL)
  step = 'trimgalore'
  paramsNow = params[[step]]
  trimDir = file.path(outputDir, paste0(step, '_output'))
  trimColname = 'fastq_trimmed'
  paramsNow[c('run', 'keep')] = NULL
  fetchColname = 'fastq_fetched'
  result = do.call(trimgalore, c(
    list(filepaths = metadata[[fetchColname]], outputDir = trimDir),
    paramsNow))
})

test_that('Test fastqc', {
  skip_on_os('windows', arch = NULL)
  step = 'fastqc'
  paramsNow = params[[step]]
  fastqcDir = file.path(outputDir, paste0(step, '_output'))
  fetchColname = 'fastq_fetched'
  trimColname = 'fastq_trimmed'
  fileColname = if (params$trimgalore$run) trimColname else fetchColname

  paramsNow[c('run', 'keep')] = NULL
  result = do.call(fastqc, c(
    list(filepaths = metadata[[fileColname]], outputDir = fastqcDir),
    paramsNow))
})

