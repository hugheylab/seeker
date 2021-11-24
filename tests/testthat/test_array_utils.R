test_that('getPlatforms', {
  d = getPlatforms('cdf')
  expect_s3_class(d, 'data.table')
  cols = c('platform', 'custom_cdf_prefix', 'ae_accession', 'ensembl', 'entrez')
  expect_names(colnames(d), permutation.of = cols, what = 'colnames')

  d = getPlatforms('mapping')
  expect_s3_class(d, 'data.table')
  cols = c('platform', 'mappingFunction', 'dbName', 'interName',
           'geneColname', 'splitColumn', 'species')
  expect_names(colnames(d), permutation.of = cols, what = 'colnames')

  expect_error(getPlatforms('platt'))
})


test_that('getCdfname', {
  platform = 'GPL6246'
  expect_identical(getCdfname(platform, 'ensembl'), 'mogene10stmmensgcdf')
  expect_identical(getCdfname(platform, 'entrez'), 'mogene10stmmentrezgcdf')
  expect_length(getCdfname('GPL0', 'ensembl'), 0)
})


test_that('installCustomCdfPackages', {
  urls = installCustomCdfPackages('mogene10stmmensgcdf', dryRun = TRUE)
  expect_string(urls)
  expect_warning(installCustomCdfPackages('mogenesmoproblems', dryRun = TRUE))
})

# getNaiveEsetGeo

# getNaiveEsetAe


test_that('getNaiveEsetLocal', {
  result = getNaiveEsetLocal('LOCAL01', 'GPL1261')
  expect_list(result)
  expect_names(names(result), permutation.of = c('eset', 'rmaOk'))
  expect_s4_class(result$eset, 'Eset')
  expect_true(result$rmaOk)
  expect_character(getNaiveEsetLocal('LOCAL01', 'GPL0'))
})


test_that('getAeMetadata', {
  study = 'E-MEXP-3780'
  expers = seeker:::getAeMetadata(study, type = 'experiments')
  expect_s3_class(expers, 'data.frame')
  expect_equal(nrow(expers), 1L)

  files = seeker:::getAeMetadata(study, type = 'files')
  expect_s3_class(files, 'data.frame')
})


test_that('stripFileExt', {
  x = c('S1.cel', 'S2.cel.gz', 'S3', 'S4.CEL')
  y = stripFileExt(x)
  expect_identical(y, paste0('S', 1:length(x)))
})


test_that('getNewEmatColnames', {
  newExp = paste0('GSM', 8:12)
  old = paste0(newExp, '_lush', '.cel.gz')
  expect_identical(getNewEmatColnames(old, 'geo'), newExp)
  expect_identical(getNewEmatColnames(old, 'ae'), paste0(newExp, '_lush'))
})


test_that('getEntrezEnsemblMapping', {
  m = getEntrezEnsemblMapping('Mm')
  expect_s3_class(m, 'data.table')
  expect_names(
    colnames(m), permutation.of = c('entrez', 'ensembl'), what = 'colnames')
})


test_that('getEmatGene', {
  ematProbe = matrix(
    as.numeric(1:8), nrow = 4L,
    dimnames = list(paste0('probe', 1:4), paste0('sample', 1:2)))
  mapping = data.table(probe_set = paste0('probe', 4:1),
                       gene_id = paste0('gene', c(1, 1, 2, 3)))
  ematGeneObs = seeker:::getEmatGene(ematProbe, mapping)
  ematGeneExp = matrix(
    c(3.5, 2, 1, 7.5, 6, 5), nrow = 3L,
    dimnames = list(paste0('gene', 1:3), paste0('sample', 1:2)))
  expect_equal(ematGeneObs, ematGeneExp)
})





