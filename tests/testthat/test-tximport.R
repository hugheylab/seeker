test_that("Test getTx2gene", {
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  tx2geneObs = do.call(getTx2gene, c(
    list(outputDir = outputDir), paramsNow$tx2gene))


  tx2geneControl = snapshot(tx2geneObs, 'test_data/tx2gene_output.qs')

  expect_equal(tx2geneObs, tx2geneControl, ignore_attr = TRUE)

})

test_that("Test tximport", {
  skip_on_os('windows', arch = NULL)
  step = 'tximport'
  paramsNow = params[[step]]

  paramsNow$run = NULL

  salmonControlDir = 'test_data/salmon_output_control'

  tx2gene = qread('test_data/tx2gene_output.qs')
  params[[step]]$tx2gene$version = attr(tx2gene, 'version') # for output yml
  paramsNow$tx2gene = NULL # for calling tximport

  tximportObs = do.call(tximport, c(
    list(inputDir = salmonControlDir, tx2gene = tx2gene,
         samples = metadata[[sampleColname]], outputDir = outputDir),
    paramsNow))

  tximportControl = snapshot(tximportObs, 'test_data/tximport_output.qs')

  # Check first and last 100 of abundance
  expect_equal(head(tximportObs$abundance, 100), head(tximportControl$abundance, 100))
  expect_equal(tail(tximportObs$abundance, 100), tail(tximportControl$abundance, 100))
  # Check first and last 100 of counts
  expect_equal(head(tximportObs$counts, 100), head(tximportControl$counts, 100))
  expect_equal(tail(tximportObs$counts, 100), tail(tximportControl$counts, 100))
  # Check first and last 100 of length
  expect_equal(head(tximportObs$length, 100), head(tximportControl$length, 100))
  expect_equal(tail(tximportObs$length, 100), tail(tximportControl$length, 100))
  # Check countsFromAbundance
  expect_equal(tximportObs$countsFromAbundance, tximportControl$countsFromAbundance)

})
