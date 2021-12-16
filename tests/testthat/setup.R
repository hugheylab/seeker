library('data.table')
library('qs')
params = yaml::read_yaml('test_data/GSE143524.yml')
# Do away with josh params and regular params, instead modify below if statement
# to build the path using Sys.info()['user'] in addition to OS.
# salmonPartialDir = '/genomes/alias/mm10/salmon_partial_sa_index/default'
if (Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/',
                                                                    '/Users/',
                                                                    params$salmon$indexDir)
if (Sys.info()['user'] != 'runner') params$salmon$indexDir = gsub('/runner/',
                                                                  paste0('/', Sys.info()['user'], '/'),
                                                                  params$salmon$indexDir)

params$fetch$run = FALSE
parentDir = 'test_data/staging'
dir.create(parentDir)
withr::local_file(parentDir, .local_envir = teardown_env())
file.copy('test_data/GSE143524', parentDir, recursive = TRUE)
foreach::registerDoSEQ()

metadata = fread('test_data/metadata.csv')

outputDir = file.path(parentDir, 'GSE143524')


fetchDir = file.path(outputDir, 'fetch_output')
remoteColname = 'fastq_aspera'
fetchColname = 'fastq_fetched'
trimDir = file.path(outputDir, 'trimgalore_output')
trimColname = 'fastq_trimmed'
fastqcDir = file.path(outputDir, 'fastqc_output')
fileColname = if (params$trimgalore$run) trimColname else fetchColname
salmonDir = file.path(outputDir, 'salmon_output')
sampleColname = 'sample_accession'
fileColname = 'fastq_fetched'

snapshot = function(xObs, path) {
  if (file.exists(path)) {
    xExp = qs::qread(path)
  } else {
    qs::qsave(xObs, path)
    xExp = xObs}
  return(xExp)}