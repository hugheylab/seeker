library('data.table')
library('qs')
dataDir = 'data'
params = yaml::read_yaml(file.path(dataDir, 'GSE143524.yml'))
# Do away with josh params and regular params, instead modify below if statement
# to build the path using Sys.info()['user'] in addition to OS.
# salmonPartialDir = '/genomes/alias/mm10/salmon_partial_sa_index/default'
os = Sys.info()['sysname']
if (os == "Darwin") params$salmon$indexDir = gsub('/home/',
                                                                    '/Users/',
                                                                    params$salmon$indexDir)
if (Sys.info()['user'] != 'runner') params$salmon$indexDir = gsub('/runner/',
                                                                  paste0('/', Sys.info()['user'], '/'),
                                                                  params$salmon$indexDir)

params$fetch$run = FALSE
parentDir = file.path(dataDir, 'staging')
dir.create(parentDir)
withr::local_file(parentDir, .local_envir = teardown_env())
file.copy(file.path(dataDir, 'GSE143524'), parentDir, recursive = TRUE)
foreach::registerDoSEQ()

metadata = fread(file.path(dataDir, 'metadata.csv'))

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
multiqcDir = file.path(outputDir, 'multiqc_output')

snapshot = function(xObs, path) {
  if (file.exists(path)) {
    xExp = qs::qread(path)
  } else {
    qs::qsave(xObs, path)
    xExp = xObs}
  return(xExp)}
