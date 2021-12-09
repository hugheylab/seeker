library('data.table')
params = yaml::read_yaml('test_data/GSE143524.yml')
if(Sys.info()['sysname'] == "Darwin") params$salmon$indexDir = gsub('/home/', '/Users/', params$salmon$indexDir)
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