cArgs = commandArgs(TRUE)
if (length(cArgs) == 2) {
  params = yaml::read_yaml(cArgs[1L])
  study = params$study
  geneIdType = params$geneIdType
  platform = params$platform
  parentDir = cArgs[2L]
} else if (length(cArgs) == 3) {
  study = cArgs[1L]
  geneIdType = cArgs[2L]
  platform = NULL
  parentDir = cArgs[3L]
} else {
  study = cArgs[1L]
  geneIdType = cArgs[2L]
  platform = cArgs[3L]
  parentDir = cArgs[4L]
}

seeker::seekerArray(study, geneIdType, platform, parentDir)