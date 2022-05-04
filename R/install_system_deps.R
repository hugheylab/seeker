addToProfile = function(line, type = 'OS') {
  if (type == 'OS') {
    profilePaths = c('~/.bashrc', '~/.zshrc', '~/.profile')
    for (profilePath in profilePaths) {
      if (file.exists(profilePath)) {
        profileFile = readLines(profilePath)
        if (!(line %in% profileFile)) {
          profileFile = c(profileFile, line)
          writeLines(profileFile, profilePath)}}}
  } else {
    rProfilePath = path.expand(file.path('~', '.Rprofile'))
    rProfileFile = c()
    if (file.exists(rProfilePath)) rProfileFile = readLines(rProfilePath)
    if (!(line %in% rProfileFile)) {
      rProfileFile = c(rProfileFile, line)
      writeLines(rProfileFile, rProfilePath)}}
  return(invisible())}


installSRAToolkit = function(installDir = '~', addToPath = TRUE) {
  os = Sys.info()[['sysname']]
  sraPath = file.path(installDir, 'sratoolkit', 'bin')

  # Check if sratoolkit already exists at location.
  if (dir.exists(file.path(installDir, 'sratoolkit', 'bin'))) {
    print('SRA Toolkit already found at location, skipping...')
  } else {
    # Change directory and store current dir
    prevWd = getwd()
    setwd(installDir)

    # Determine latest available SRA Toolkit version
    url = 'https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/'
    raw = getURL(url)
    x = strsplit(raw, '\\n')[[1L]]
    pattern = '[0-9]\\.[0-9]\\.[0-9]'
    m = regexpr(glue('{pattern}'), x)
    sraVersion = max(regmatches(x, m))

    # Based on operating system, download correct version to correct path.
    sraOsTar = if (os == 'Darwin') 'mac64' else 'ubuntu64'
    sraTar = glue('sratoolkit.{sraVersion}-{sraOsTar}.tar.gz')
    # Download based on version and OS, unzip, then rename directory to `sratoolkit`
    system2(
      'curl',
      c('-O',
        glue('{url}{sraVersion}/{sraTar}')))
    system2('tar', c('-zxvf', sraTar))
    system2(
      'mv',
      c(sub('.tar.gz', '', sraTar, fixed = TRUE), 'sratoolkit'))
    system2('rm', c('sratoolkit*.tar.gz'))
    setwd(prevWd)}
  if (isTRUE(addToPath)) {
    # Add to OS path and .Rprofile path.
    addToProfile(paste0('export PATH="$PATH:', path.expand(sraPath), '"'))
    addToProfile(
      paste0('Sys.setenv(PATH = paste(Sys.getenv("PATH"), "',
             path.expand(sraPath),
             '", sep = ":"))'),
      type = 'R')
    Sys.setenv(
      PATH = paste(Sys.getenv('PATH'),
                   path.expand(sraPath), sep = ':'))}
  ncbiDir = file.path(path.expand('~'), '.ncbi')
  if (!dir.exists(ncbiDir)) {
    dir.create(ncbiDir)
    system(
      "printf '/LIBS/GUID = \"%s\"\n' `uuidgen` > ~/.ncbi/user-settings.mkfg")
    system(
      "printf '/libs/cloud/report_instance_identity = \"true\"\n' >> ~/.ncbi/user-settings.mkfg")
    # system2(
    #   '/bin/bash', args = c("-c", shQuote('vdb-config -i & read -t 3 ; kill $!')))
  }
  return(invisible())}


installMiniconda = function(installDir = '~', minicondaEnv = 'seeker', setSeekerOption = TRUE) {
  # Determine paths for miniconda
  minicondaPath = file.path(installDir, 'miniconda3')
  minicondaEnvPath = minicondaPath
  if (minicondaEnv != 'base') {
    minicondaEnvPath = file.path(minicondaEnvPath, 'envs', minicondaEnv)}

  if (dir.exists(file.path(minicondaPath))) {
    print('miniconda3 already installed, skipping install...')
  } else {
    print('Installing miniconda3...')
    os = Sys.info()[['sysname']]
    miniOsSh = if (os == 'Darwin') 'MacOSX' else 'Linux'
    miniSh = glue('Miniconda3-latest-{miniOsSh}-x86_64.sh')
    system2(
      'curl',
      c('-O',
        glue('https://repo.anaconda.com/miniconda/{miniSh}')))
    system2('sh', c(miniSh, '-b', '-p', file.path(installDir, 'miniconda3')))
    system2('rm', c('Miniconda3*.sh'))
    print('Running conda init...')
    system(paste0(minicondaPath, '/bin/conda init bash'))}

  # Create new environment if it doesnt exist.
  if (minicondaEnv != 'base' && !dir.exists(minicondaEnvPath)) {
    print('Creating new environment...')
    yamlPath = system.file('extdata', 'conda_env.yml', package = 'seeker')
    envYaml = yaml::read_yaml(yamlPath)
    if (minicondaEnv != envYaml$name) {
      yamlPath = file.path('.', 'conda_env.yml')
      envYaml$name = minicondaEnv
      yaml::write_yaml(envYaml, yamlPath)}
    print('Environment command:')
    print(paste0(
      path.expand(minicondaPath),
      '/bin/conda env create -f "',
      yamlPath, '"'))
    system(paste0(
      path.expand(minicondaPath),
      '/bin/conda env create -f "',
      yamlPath, '"'))}
  print(paste0('Setting seeker.miniconda option to "', minicondaEnvPath, '"'))
  options(seeker.miniconda = path.expand(minicondaEnvPath))
  Sys.setenv(
    PATH = paste(Sys.getenv('PATH'),
                 path.expand(file.path(minicondaPath, 'bin')), sep = ':'))
  # Set the option.
  if (setSeekerOption) {
    addToProfile(
      paste0("options(seeker.miniconda = '", path.expand(minicondaEnvPath), "')"),
      type = 'R')}
  return(invisible())}


#' Install seeker system dependencies for Mac and Ubuntu.
#'
#' @param sraToolkitPath Where to install the SRA Toolkit.
#' @param sraAddToPath Boolean to add the SRA toolkit to the system and R path files.
#' @param minicondaPath Where to install miniconda.
#' @param minicondaEnv The name of the miniconda environment. "base" will use the default base environment.
#' @param setSeekerOption Boolean to add the miniconda path as the "seeker.miniconda" option to the R profile.
#' @param refgenieDir Where to add refgenie config files.
#' @param salmonIndexes Which salmon indexes to pull from refgenie.
#' @param fastqDir Where to output the fastq_screen command.
#'
#' @return `invisible()`
#'
#' @export
installTools = function(sraToolkitPath = '~', sraAddToPath = TRUE,
                        minicondaPath = '~', minicondaEnv = 'seeker',
                        setSeekerOption = TRUE,
                        refgenieDir = '~/genomes',
                        salmonIndexes = NULL,
                        fastqDir = NULL) {
  if (!is.null(sraToolkitPath)) {
    if (dir.exists(file.path(sraToolkitPath, 'sratoolkit', 'bin'))) {
      print('SRA Toolkit already found at location, skipping...')
    } else {
      installSRAToolkit(sraToolkitPath, sraAddToPath)}}

  if (!is.null(minicondaPath)) {
    # Install miniconda
    installMiniconda(minicondaPath, minicondaEnv, setSeekerOption)
    system3(
      'mamba', c('env', 'update', '-p',
                 path.expand(file.path(minicondaPath, 'miniconda3', 'envs', minicondaEnv)),
                 '--file', system.file('extdata', 'mamba_env.yml', package = 'seeker')))}

  if (!is.null(refgenieDir)) {
    if (dir.exists(refgenieDir)) {
      print('Refgenie already exists at specified location, skipping...')
    } else {
      dir.create(refgenieDir)
      system3('refgenie', c('init', '-c', file.path(refgenieDir, 'genome_config.yaml')))
      addToProfile(paste0('export REFGENIE="', file.path(path.expand(refgenieDir), 'genome_config.yaml'), '"'))
      addToProfile(
        paste0("Sys.setenv(REFGENIE = '", file.path(path.expand(refgenieDir), 'genome_config.yaml'), "')"),
        type = 'R')
      Sys.setenv(
        REFGENIE = file.path(path.expand(refgenieDir), 'genome_config.yaml'))}}

  if (!is.null(salmonIndexes)) {
    if (length(salmonIndexes) == 0) {
      stop('If pulling salmon indexes, must provide at least one index to pull.')}
    for (salmonIndex in salmonIndexes) {
      print(salmonIndex)
      system3('refgenie', c('pull', salmonIndex, '--genome-config',
                            file.path(path.expand(refgenieDir), 'genome_config.yaml')))}}

  if (!is.null(fastqDir)) {
    system3('fastq_screen', c('--get_genomes', '--outdir', fastqDir))}
  return(invisible())}