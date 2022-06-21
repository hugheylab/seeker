cArgs = commandArgs(TRUE)
study = cArgs[1L]
geneIdType = cArgs[2L]
platform = NULL
parentDir = cArgs[3L]
if (length(cArgs) > 3) {
  platform = cArgs[3L]
  parentDir = cArgs[4L]
}

seeker::seekerArray(study, geneIdType, platform, parentDir)