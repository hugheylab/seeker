addToProfile = function(line, type = 'OS') {
  paths = file.path('~', c('.zshrc', '.bashrc', '.profile'))
  paths = if (type == 'OS') {
    paths[file.exists(paths)]
  } else {
    file.path('~', '.Rprofile')}

  for (path in paths) {
    lines = if (file.exists(path)) readLines(path) else character()
    if (!(line %in% lines)) write(line, path, append = TRUE)}

  invisible()}


installSraToolkit = function(installDir, addToPath = TRUE) {
  sraPath = path.expand(file.path(installDir, 'sratoolkit', 'bin'))

  # Check if sratoolkit already exists at location
  if (dir.exists(sraPath)) {
    cat('SRA Toolkit already installed, skipping...\n')

  } else {
    cat('Installing SRA Toolkit...\n')
    # Change working directory
    withr::local_dir(installDir)

    # Determine latest available SRA Toolkit version
    url = 'https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/'
    raw = RCurl::getURL(url)
    x = strsplit(raw, '\\n')[[1L]]
    m = regexpr('[0-9]\\.[0-9]\\.[0-9]', x)
    sraVersion = max(regmatches(x, m))

    # Based on operating system, download correct version to correct path
    sraOsTar = if (Sys.info()[['sysname']] == 'Darwin') 'mac64' else 'ubuntu64'
    sraTar = glue('sratoolkit.{sraVersion}-{sraOsTar}.tar.gz')

    # Download based on version and OS, unzip, then rename directory
    withr::local_file(sraTar)
    download.file(glue('{url}{sraVersion}/{sraTar}'), sraTar, quiet = TRUE)
    utils::untar(sraTar)
    . = file.rename(sub('\\.tar\\.gz', '', sraTar), 'sratoolkit')}

  configPath = '~/.ncbi/user-settings.mkfg'
  if (!file.exists(configPath)) {
    if (!dir.exists(dirname(configPath))) dir.create(dirname(configPath))
    uuidPath = withr::local_tempfile(fileext = '.txt')
    download.file(
      'https://www.uuidgenerator.net/api/version4', uuidPath, quiet = TRUE)
    uuid = readLines(uuidPath, warn = FALSE)
    prePath = system.file('extdata', 'user-settings.mkfg', package = 'seeker')
    lines = sapply(
      readLines(prePath, warn = FALSE), glue_data,
      .x = list(uuid = uuid, home = Sys.getenv('HOME')))
    writeLines(lines, configPath)}

  if (addToPath) {
    # Add to OS path and .Rprofile path
    addToProfile(glue('export PATH="$PATH:{sraPath}"'))
    path = paste(Sys.getenv('PATH'), sraPath, sep = ':')
    addToProfile(glue('Sys.setenv(PATH = "{path}")'), type = 'R')
    Sys.setenv(PATH = path)}

  invisible()}


installMiniconda = function(installDir, minicondaEnv, setSeekerOption = TRUE) {
  # Determine paths for miniconda
  minicondaPath = path.expand(file.path(installDir, 'miniconda3'))
  minicondaEnvPath = if (minicondaEnv == 'base') {
    minicondaPath
  } else {
    file.path(minicondaPath, 'envs', minicondaEnv)}

  if (dir.exists(minicondaPath)) {
    cat('Miniconda already installed, skipping...\n')

  } else {
    cat('Installing Miniconda...\n')

    miniOsSh = if (Sys.info()[['sysname']] == 'Darwin') 'MacOSX' else 'Linux'
    miniSh = glue('Miniconda3-latest-{miniOsSh}-x86_64.sh')
    withr::local_file(miniSh)
    download.file(
      glue('https://repo.anaconda.com/miniconda/{miniSh}'), miniSh, quiet = TRUE)
    system2('sh', c(miniSh, '-b', '-p', file.path(installDir, 'miniconda3')))

    cat('Running conda init...\n')
    system(glue('{minicondaPath}/bin/conda init bash'))}

  # Create new environment if it doesn't exist
  if (minicondaEnv != 'base' && !dir.exists(minicondaEnvPath)) {
    cat('Creating conda environment...\n')
    yamlPath = system.file('extdata', 'conda_env.yml', package = 'seeker')
    envYaml = yaml::read_yaml(yamlPath)

    if (minicondaEnv != envYaml$name) {
      yamlPath = withr::local_tempfile(fileext = '.yml')
      envYaml$name = minicondaEnv
      yaml::write_yaml(envYaml, yamlPath)}

    system(glue('{minicondaPath}/bin/conda env create -f "{yamlPath}"'))}

  # Set the option
  if (setSeekerOption) {
    addToProfile(
      glue('options(seeker.miniconda = "{minicondaEnvPath}")'), type = 'R')
    options(seeker.miniconda = minicondaEnvPath)}

  cat('Installing conda packages via mamba...\n')
  mambaEnvPath = system.file('extdata', 'mamba_env.yml', package = 'seeker')
  mambaArgs = c('env', 'update', '-p', minicondaEnvPath, '--file', mambaEnvPath)
  system3('mamba', mambaArgs)

  invisible()}


setRefgenie = function(refgenieDir) {
  cat('Configuring refgenie...\n')
  if (!dir.exists(refgenieDir)) dir.create(refgenieDir)
  refgenieYamlPath = file.path(path.expand(refgenieDir), 'genome_config.yaml')
  if (!file.exists(refgenieYamlPath)) {
    system3('refgenie', c('init', '-c', refgenieYamlPath))}
  addToProfile(glue('export REFGENIE="{refgenieYamlPath}"'))
  addToProfile(glue('Sys.setenv(REFGENIE = "{refgenieYamlPath}")'), type = 'R')
  Sys.setenv(REFGENIE = refgenieYamlPath)
  invisible()}


getSalmonIndexes = function(salmonIndexes) {
  cat('Fetching salmon indexes...\n')
  for (salmonIndex in salmonIndexes) {
    rgArgs = c('pull', salmonIndex, '--genome-config', Sys.getenv('REFGENIE'))
    system3('refgenie', rgArgs)}
  invisible()}


#' Install seeker system dependencies for Mac and Ubuntu.
#'
#' @param sraToolkitDir Where to install the SRA Toolkit.
#' @param minicondaDir Where to install miniconda.
#' @param minicondaEnv The name of the miniconda environment. "base" will use the default base environment.
#' @param refgenieDir Where to add refgenie config files.
#' @param salmonIndexes Which salmon indexes to pull from refgenie.
#' @param fastqscreenDir Where to output the fastq_screen command.
#'
#' @return `invisible()`
#'
#' @export
installSysDeps = function(
    sraToolkitDir = '~', minicondaDir = '~', minicondaEnv = 'seeker',
    refgenieDir = '~/refgenie_genomes', salmonIndexes = NULL,
    fastqscreenDir = NULL) {

  assertString(sraToolkitDir, null.ok = TRUE)
  if (!is.null(sraToolkitDir)) assertDirectoryExists(sraToolkitDir)
  assertString(minicondaDir, null.ok = TRUE)
  if (!is.null(minicondaDir)) assertDirectoryExists(minicondaDir)
  assertString(minicondaEnv, pattern = '^\\S+$')
  assertString(refgenieDir, null.ok = is.null(minicondaDir))
  assertCharacter(salmonIndexes, any.missing = FALSE, null.ok = TRUE)
  assertString(fastqscreenDir, null.ok = TRUE)

  if (!is.null(sraToolkitDir)) {
    tryCatch(installSraToolkit(sraToolkitDir), error = warning)}

  if (!is.null(minicondaDir)) {
    tryCatch(installMiniconda(minicondaDir, minicondaEnv), error = warning)
    if (is.na(validateCommand('refgenie'))) {
      warning('refgenie not found, cannot be configured.')
    } else {
      tryCatch(setRefgenie(refgenieDir), error = warning)}}

  if (!is.null(salmonIndexes)) {
    if (is.na(validateCommand('refgenie'))) {
      warning('refgenie not found, salmon indexes cannot be fetched.')
    } else {
      tryCatch(getSalmonIndexes(salmonIndexes), error = warning)}}

  if (!is.null(fastqscreenDir)) {
    if (is.na(validateCommand('fastq_screen'))) {
      warning('fastq_screen not found, genomes cannot be fetched.')
    } else {
      cat('Fetching fastq_screen genomes...\n')
      if (!dir.exists(fastqscreenDir)) dir.create(fastqscreenDir)
      tryCatch(
        system3('fastq_screen', c('--get_genomes', '--outdir', fastqscreenDir)),
        error = warning)}}

  invisible()}
