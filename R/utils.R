getLogPath = function(outputDir, filename = 'progress.tsv') {
  return(file.path(outputDir, filename))}


writeLogFile = function(path, task, idx, status, n = NULL) {
  d = data.table(datetime = Sys.time())
  append = TRUE
  if (is.null(n)) {
    d = data.table(d, task = task, idx = idx, status = status)
  } else {
    if (n > 0) {
      x = 'started'
      append = FALSE
    } else {
      x = 'finished'}
    d = data.table(d, task = sprintf('%s %d tasks', x, abs(n)), idx = 0, status = 0)}
  fwrite(d, path, sep = '\t', append = append, logical01 = TRUE)
  invisible(d)}


getFileList = function(fileVec) {
  if (is.list(fileVec)) return(fileVec)
  return(strsplit(fileVec, ';'))}


getFileVec = function(fileList) {
  return(sapply(fileList, function(f) paste0(f, collapse = ';')))}


#' Get ascp command
#'
#' This function returns the default path to the aspera ascp command-line
#' interface, based on the operating system. Windows is not supported.
#'
#' @return A string.
#'
#' @seealso [getAscpArgs()], [fetch()]
#'
#' @export
getAscpCmd = function() {
  cmd = switch(
    Sys.info()[['sysname']],
    Linux = '~/.aspera/connect/bin/ascp',
    Darwin = '~/Applications/Aspera Connect.app/Contents/Resources/ascp',
    Windows = NULL)
  return(cmd)}


#' Get ascp arguments
#'
#' This function returns the default arguments to pass to the aspera ascp
#' command-line interface, based on the operating system. Windows is not
#' supported.
#'
#' @return A character vector.
#'
#' @seealso [getAscpCmd()], [fetch()]
#'
#' @export
getAscpArgs = function() {
  a = c('-QT -l 300m -P33001 -i')
  f = 'asperaweb_id_dsa.openssh'
  rgs = switch(
    Sys.info()[['sysname']],
    Linux = c(a, safe(file.path('~/.aspera/connect/etc', f))),
    Darwin = c(a, safe(file.path('~/Applications/Aspera Connect.app/Contents/Resources', f))),
    Windows = NULL)
  return(rgs)}


getTrimmedFilenames = function(x) {
  # for one read or one pair of reads at a time
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L574
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L866
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L1744

  y = x
  for (i in 1:length(y)) {
    pat = if (grepl('\\.fastq$', x[i])) {
      '\\.fastq$'
    } else if (grepl('\\.fastq\\.gz$', x[i])) {
      '\\.fastq\\.gz$'
    } else if (grepl('\\.fq$', x[i])) {
      '\\.fq$'
    } else if (grepl('\\.fq\\.gz$', x[i])) {
      '\\.fq\\.gz$'
    } else {
      '$'}
    y[i] = gsub(pat, '_trimmed.fq.gz', x[i])

    if (length(y) > 1) {
      y[i] = gsub('trimmed\\.fq\\.gz', sprintf('val_%d.fq.gz', i), y[i])}}

  return(y)}


getFastqcFilenames = function(fastqFilepaths) {
  x = basename(unlist(getFileList(fastqFilepaths)))
  y = gsub('\\.(f(ast)?q(\\.gz)?)$', '', x, ignore.case = TRUE)
  z = c(paste0(y, '_fastqc.html'), paste0(y, '_fastqc.zip'))
  return(z)}


system3 = function(...) {
  mc = getOption('seeker.miniconda', '~/miniconda3')
  p = path.expand(file.path(mc, c('bin/scripts', 'bin')))
  withr::local_path(p)
  system2(...)}


safe = function(x) {
  y = sapply(x, function(a) sprintf("'%s'", path.expand(a)), USE.NAMES = FALSE)
  return(y)}


checkCommand = function(cmd) {
  # if cmd doesn't exist, system2('command', ...) seems to
  # give warning on mac and error on linux
  old = getOption('warn')
  options(warn = -1)
  path = tryCatch({system3('command', c('-v', safe(cmd)), stdout = TRUE)},
                  error = function(e) NA_character_)
  options(warn = old)
  if (length(path) == 0) path = NA_character_
  return(path)}


#' Check for presence of command-line interfaces
#'
#' This function checks whether the command-line tools used by seeker are
#' accessible in the expected places.
#'
#' @return A data.table with columns for command, path, and version.
#'
#' @export
checkDefaultCommands = function() {
  d = data.table(
    cmd = c('ascp', 'wget', 'fastqc', 'fastq_screen', 'trim_galore', 'cutadapt',
            'multiqc', 'salmon'),
    idx = c(2, 1, 1, 1, 4, 1, 1, 1))

  i = NULL
  r = foreach(i = 1:nrow(d), .combine = rbind) %do% {
    cmd = if (d$cmd[i] == 'ascp') getAscpCmd() else d$cmd[i]
    path = checkCommand(cmd)
    version = if (is.na(path)) NA_character_ else
      system3(path.expand(cmd), '--version', stdout = TRUE)[d$idx[i]]
    data.table(command = d$cmd[i], path = path, version = version)}

  return(r)}
