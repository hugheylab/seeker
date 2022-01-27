library('data.table')
library('qs')
library('foreach')

snapshot = function(xObs, path) {
  if (file.exists(path)) {
    xExp = qread(path)
  } else {
    qsave(xObs, path)
    xExp = xObs}
  return(xExp)}

commandsExists = function(params, cmds = seeker:::checkDefaultCommands()) {
  exists = foreach(i = 1:nrow(cmds), .combine = rbind) %do% {
    cmdRow = cmds[i,]
    cmd = if (cmdRow$command == 'ascp') {
      params$fetch$ascpCmd
    } else if (cmdRow$command == 'trim_galore') {
      params$trimgalore$cmd
    } else if (cmdRow$command %in% names(params)) {
      params[[cmdRow$command]]$cmd
    } else {
      NULL}
    cmdExists = TRUE
    if (is.null(cmd)) {
      if (is.na(cmdRow$path)) {
        cmdExists = FALSE}
    } else {
      path = checkCommand(cmd)
      if (is.na(path)) {
        cmdExists = FALSE}}
    cmdRow[, exists := cmdExists]
  }
  return(exists)}

registerDoSEQ()
dataDir = 'data'
params = yaml::read_yaml(file.path(dataDir, 'GSE143524.yml'))
os = Sys.info()['sysname']

if (os == 'Darwin') {
  params$salmon$indexDir = gsub('/home/', '/Users/', params$salmon$indexDir)}
if (Sys.info()['user'] != 'runner') {
  params$salmon$indexDir = gsub('/runner/',
                                paste0('/', Sys.info()['user'], '/'),
                                params$salmon$indexDir)}

missingCommands = rbind(commandsExists(params), data.table(command = 'samlmon_index', path = params$salmon$indexDir, exists = file.exists(params$salmon$indexDir)), fill = TRUE)
anyMissing = any(!missingCommands[['exists']])


params$fetch$run = FALSE
parentDir = file.path(dataDir, 'staging')
dir.create(parentDir)
withr::local_file(parentDir, .local_envir = teardown_env())
file.copy(file.path(dataDir, 'GSE143524'), parentDir, recursive = TRUE)

metadata = qread(file.path(dataDir, 'metadata.qs'))

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
