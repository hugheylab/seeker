createLogFile = function(path, n) {
  d = data.table(
    datetime = Sys.time(), task = sprintf('started %d tasks', n), idx = 0, status = 0)
  data.table::fwrite(d, path, sep = '\t', logical01 = TRUE)
  invisible(d)}


appendLogFile = function(path, task, idx, status) {
  d = data.table(datetime = Sys.time(), task = task, idx = idx, status = status)
  data.table::fwrite(d, path, sep = '\t', append = TRUE, logical01 = TRUE)
  invisible(d)}


# writeLogFile = function(path, task, idx, status, n = NULL) {
#   d = data.table(datetime = Sys.time())
#   if (is.null(n)) {
#     d = data.table(d, task = task, idx = idx, status = status)
#     append = TRUE
#   } else {
#     d = data.table(d, task = sprintf('started %d tasks', n), idx = 0, status = 0)
#     append = FALSE}
#   data.table::fwrite(d, path, sep = '\t', append = append, logical01 = TRUE)
#   invisible(d)}


getFileList = function(fileVec) {
  if (is.list(fileVec)) {
    return(fileVec)}
  return(strsplit(fileVec, ';'))}


getFileVec = function(fileList) {
  return(sapply(fileList, function(f) paste0(f, collapse = ';')))}


checkFilepaths = function(filepaths) {
  if (!all(file.exists(unlist(filepaths)))) {
    stop('Not all supplied file paths exist.')}
  invisible(0)}
