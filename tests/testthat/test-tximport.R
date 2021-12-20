test_that("Test getTx2gene", {
  skip("Skipping until solution to get around ensembl server issues is found.")
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  tx2geneObs = do.call(getTx2gene, c(
    list(outputDir = outputDir), paramsNow$tx2gene))


  tx2geneControl = snapshot(tx2geneObs, file.path(testDir, 'tx2gene_output.qs'))

  expect_equal(tx2geneObs, tx2geneControl, ignore_attr = TRUE)

})

test_that("Test tximport", {
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  salmonControlDir = file.path(testDir, 'salmon_output_control')

  tx2gene = qread(file.path(testDir, 'tx2gene_output.qs'))
  params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
  paramsNow$tx2gene = NULL # for calling tximport

  tximportObs = do.call(tximport, c(
    list(inputDir = salmonControlDir, tx2gene = tx2gene,
         samples = metadata[[sampleColname]], outputDir = outputDir),
    paramsNow))

  tximportControl = snapshot(tximportObs, file.path(testDir, 'tximport_output.qs'))

  expect_equal(tximportObs$abundance, tximportControl$abundance)
  expect_equal(tximportObs$counts, tximportControl$counts)
  expect_equal(tximportObs$length, tximportControl$length)
  expect_equal(tximportObs$countsFromAbundance, tximportControl$countsFromAbundance)

})
