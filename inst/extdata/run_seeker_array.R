cArgs = commandArgs(TRUE)
yamlPath = cArgs[1L]
parentDir = cArgs[2L]

params = yaml::read_yaml(yamlPath)
seeker::seekerArray(params, parentDir)
