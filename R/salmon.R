#' Run Salmon
#'
#' This function calls
#' [salmon](https://combine-lab.github.io/salmon/)
#' using [system2()]. To run in parallel, register a parallel backend using
#' [doFuture::registerDoFuture()] or [doParallel::registerDoParallel()].
#'
#' @param filepaths Paths to fastq files. For single-end reads, each element
#'   should be a single filepath. For paired-end reads, each element should be
#'   two filepaths separated by ";".
#' @param samples Corresponding sample names for fastq files.
#' @param indexDir Directory that contains salmon index.
#' @param outputDir Directory in which to store output. Will be created if it
#'   doesn't exist.
#' @param cmd Name or path of the command-line interface.
#' @param args Additional arguments to pass to the command-line interface.
#'
#' @return A vector of exit codes, invisibly.
#'
#' @export
salmon = function(
  filepaths, samples, indexDir, outputDir = 'salmon_output', cmd = 'salmon',
  args = c('-l', 'A', '-p', foreach::getDoParWorkers(),
           '-q --seqBias --gcBias --no-version-check')) {

  i = NULL
  filepaths = getFileList(filepaths)
  checkFilepaths(filepaths)
  dir.create(outputDir, recursive = TRUE)
  argsBase = c('quant', args, '-i', indexDir)

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


#' Aggregrate metadata from salmon quantifications
#'
#' @param outputDir Directory that contains output from salmon.
#' @param outputFilename Name of file, which will be saved in `outputDir`. If
#'   `NULL`, no file is saved.
#'
#' @return A data.table, invisibly.
#'
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
