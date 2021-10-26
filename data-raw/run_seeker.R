# zsh: Rscript data-raw/run_seeker.R data-raw/GSE143524.yml ~/Downloads &> ~/Downloads/GSE143524/progress.log

doParallel::registerDoParallel(cores = 4) # use doFuture instead?

cArgs = commandArgs(TRUE)
yamlPath = cArgs[1L]
parentDir = cArgs[2L]

params = yaml::read_yaml(yamlPath)
seeker::seeker(params, parentDir)
