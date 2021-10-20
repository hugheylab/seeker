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
  data.table::fwrite(d, path, sep = '\t', append = append, logical01 = TRUE)
  invisible(d)}


getFileList = function(fileVec) {
  if (is.list(fileVec)) return(fileVec)
  return(strsplit(fileVec, ';'))}


getFileVec = function(fileList) {
  return(sapply(fileList, function(f) paste0(f, collapse = ';')))}


# checkFilepaths = function(filepaths) {
#   if (!all(file.exists(unlist(filepaths)))) {
#     stop('Not all supplied file paths exist.')}
#   invisible(0)}


#' Get aspera command
#'
#' This function returns the default path to the aspera ascp command-line
#' interface, based on the operating system. Windows is not supported.
#'
#' @return A string.
#'
#' @seealso [getAsperaArgs()], [getFastq()]
#'
#' @export
getAsperaCmd = function() {
  cmd = switch(
    Sys.info()[['sysname']],
    Linux = '~/.aspera/connect/bin/ascp',
    Darwin = '~/Applications/Aspera Connect.app/Contents/Resources/ascp',
    Windows = NULL)
  return(cmd)}


#' Get aspera arguments
#'
#' This function returns the default arguments to pass to the aspera
#' command-line interface, based on the operating system. Windows is not
#' supported.
#'
#' @return A character vector.
#'
#' @seealso [getAsperaCmd()], [getFastq()]
#'
#' @export
getAsperaArgs = function() {
  a = c('-QT -l 300m -P33001', '-i')
  f = 'asperaweb_id_dsa.openssh'
  rgs = switch(
    Sys.info()[['sysname']],
    Linux = c(a, file.path('~/.aspera/connect/etc', f)),
    Darwin = c(a, file.path('~/Applications/Aspera\\ Connect.app/Contents/Resources', f)),
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
    cmd = if (d$cmd[i] == 'ascp') getAsperaCmd() else d$cmd[i]
    path = system2('command', c('-v', gsub(' ', '\\\\ ', cmd)), stdout = TRUE)
    if (length(path) == 0L) {
      path = NA_character_
      version = NA_character_
    } else {
      version = system2(path.expand(cmd), '--version', stdout = TRUE)[d$idx[i]]}
    data.table(command = d$cmd[i], path = path, version = version)}

  return(r)}
