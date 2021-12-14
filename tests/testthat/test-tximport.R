test_that("Test getTx2gene", {
  skip("Skipping until done.")
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  if (is.list(paramsNow$tx2gene)) {
    tx2gene = do.call(getTx2gene, c(
      list(outputDir = outputDir), paramsNow$tx2gene))
    params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
    paramsNow$tx2gene = NULL # for calling tximport
  } else {
    tx2gene = NULL}
})

test_that("Test tximport", {
  skip("Skipping until done.")
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  if (is.list(paramsNow$tx2gene)) {
    tx2gene = do.call(getTx2gene, c(
      list(outputDir = outputDir), paramsNow$tx2gene))
    params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
    paramsNow$tx2gene = NULL # for calling tximport
  } else {
    tx2gene = NULL}

  # samples don't have to be unique here
  result = do.call(tximport, c(
    list(inputDir = salmonDir, tx2gene = tx2gene,
         samples = metadata[[sampleColname]], outputDir = outputDir),
    paramsNow))
})
