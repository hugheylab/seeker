#' @export
salmon = function(
  filepaths, samples, indexPath, outputDir = 'salmon_output', cmd = 'salmon',
  args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
           '-q --seqBias --gcBias --no-version-check')) {

  i = NULL
  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', args, '-i', indexPath)

  samplesUnique = sort(unique(samples))
  logPath = file.path(outputDir, 'progress.tsv')
  createLogFile(logPath, length(samplesUnique))

  feo = foreach(i = 1:length(samplesUnique), .combine = c,
                .options.future = list(scheduling = Inf))

  result = feo %do% {
    samp = samplesUnique[i]
    f = filepaths[samp == samples]
    args1 = c(argsBase, '-o', file.path(outputDir, samp))

    if (length(f[[1]]) > 1) {
      f1 = sapply(f, function(f) f[1])
      f2 = sapply(f, function(f) f[2])
      args2 = c('-1', f1, '-2', f2)
    } else {
      args2 = c('-r', unlist(f))}

    r = system2(path.expand(cmd), c(args1, args2))
    appendLogFile(logPath, samp, i, r)
    r}
  invisible(result)}


#' @export
getSalmonMetadata = function(
  outputDir = 'salmon_output', outputFilename = 'meta_info.csv') {

  filepaths = list.files(
    outputDir, 'meta_info.json', full.names = TRUE, recursive = TRUE)
  sampleNames = sapply(
    strsplit(filepaths, .Platform$file.sep), function(x) x[length(x) - 2L])

  metaList = lapply(filepaths, function(x) rjson::fromJSON(file = x))
  names(metaList) = sampleNames

  fieldNames = c('eq_class_properties', 'length_classes')
  metaSpecial = list()
  for (fieldName in fieldNames) {
    fieldSpecial = lapply(metaList, function(x) x[[fieldName]])
    if (!all(lapply(fieldSpecial, length) == 0)) {
      metaSpecial[[fieldName]] = lapply(metaList, function(x) x[[fieldName]])}}

  metaList = lapply(metaList, function(x) {
    idx = !(names(x) %in% c('quant_errors', fieldNames))
    x[idx]})
  metadata = data.table::rbindlist(metaList, fill = TRUE, idcol = 'sample_name')

  for (fieldName in names(metaSpecial)) {
    data.table::set(metadata, j = fieldName, value = metaSpecial[[fieldName]])}

  if (!is.null(outputFilename)) {
    data.table::fwrite(metadata, file.path(outputDir, outputFilename))}
  invisible(metadata)}
