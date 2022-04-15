getLogPath = function(outputDir, filename = 'progress.tsv') {
  return(file.path(outputDir, filename))}


writeLogFile = function(path, task, idx, status, n = NULL) {
  d = data.table(datetime = Sys.time())
  append = TRUE
  if (is.null(n)) {
    d = data.table(d, task = task, idx = idx, status = status)
  } else {
    if (n > 0) {
      x = 'started'
      append = FALSE
    } else {
      x = 'finished'}
    d = data.table(d, task = glue('{x} {abs(n)} tasks'), idx = 0, status = 0)}
  fwrite(d, path, sep = '\t', append = append, logical01 = TRUE)
  invisible(d)}


getFileList = function(fileVec) {
  if (is.list(fileVec)) return(fileVec)
  return(strsplit(fileVec, ';'))}


getFileVec = function(fileList) {
  return(sapply(fileList, function(f) paste0(f, collapse = ';')))}


# #' Get ascp command
# #'
# #' This function returns the default path to the aspera ascp command-line
# #' interface, based on the operating system. Windows is not supported.
# #'
# #' @return A string.
# #'
# #' @seealso [getAscpArgs()], [fetch()]
# #'
# #' @export
# getAscpCmd = function() {
#   os = Sys.info()[['sysname']]
#   cmd = if (os == 'Linux') {
#     '~/.aspera/connect/bin/ascp'
#   } else if (os == 'Darwin') {
#     appDir = '~/Applications/Aspera Connect.app/Contents/Resources'
#     if (!dir.exists(appDir)) appDir = gsub('~', '', appDir)
#     file.path(appDir, 'ascp')
#   } else {
#     NULL}
#   return(cmd)}


# #' Get ascp arguments
# #'
# #' This function returns the default arguments to pass to the aspera ascp
# #' command-line interface, based on the operating system. Windows is not
# #' supported.
# #'
# #' @return A character vector.
# #'
# #' @seealso [getAscpCmd()], [fetch()]
# #'
# #' @export
# getAscpArgs = function() {
#   a = c('-QT -l 300m -P33001 -i')
#   f = 'asperaweb_id_dsa.openssh'
#   os = Sys.info()[['sysname']]
#   rgs = if (os == 'Linux') {
#     c(a, safe(file.path('~/.aspera/connect/etc', f)))
#   } else if (os == 'Darwin') {
#     appDir = '~/Applications/Aspera Connect.app/Contents/Resources'
#     if (!dir.exists(appDir)) appDir = gsub('~', '', appDir)
#     c(a, safe(file.path(appDir, f)))
#   } else {
#     NULL}
#   return(rgs)}


getTrimmedFilenames = function(x) {
  # for one read or one pair of reads at a time
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L574
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L866
  # https://github.com/FelixKrueger/TrimGalore/blob/master/trim_galore#L1744

  y = x
  for (i in seq_len(length(y))) {
    pat = if (grepl('\\.fastq$', x[i])) {
      '\\.fastq$'
    } else if (grepl('\\.fastq\\.gz$', x[i])) {
      '\\.fastq\\.gz$'
    } else if (grepl('\\.fq$', x[i])) {
      '\\.fq$'
    } else if (grepl('\\.fq\\.gz$', x[i])) {
      '\\.fq\\.gz$'
    } else {
      '$'}
    # trim_galore stopped being able to gzip files if the paths contain spaces
    # y[i] = gsub(pat, '_trimmed.fq.gz', x[i])
    y[i] = gsub(pat, '_trimmed.fq', x[i])

    if (length(y) > 1) {
      y[i] = gsub('trimmed\\.fq', glue('val_{i}.fq'), y[i])}}
  # y[i] = gsub('trimmed\\.fq\\.gz', glue('val_{i}.fq.gz'), y[i])}}

  return(y)}


getFastqcFilenames = function(fastqFilepaths) {
  x = basename(unlist(getFileList(fastqFilepaths)))
  y = gsub('\\.(f(ast)?q(\\.gz)?)$', '', x, ignore.case = TRUE)
  z = c(paste0(y, '_fastqc.html'), paste0(y, '_fastqc.zip'))
  return(z)}


getRCondaInfo = function(outputDir = '.') {
  sessioninfo::session_info(
    info = c('platform', 'packages'),
    to_file = file.path(outputDir, 'session.log'))

  mc = getOption('seeker.miniconda')
  if (is.null(mc)) {
    envName = 'base'
    condaPre = '~/miniconda3'
  } else if (basename(dirname(mc)) == 'envs') {
    envName = basename(mc)
    condaPre = dirname(dirname(mc))
  } else {
    envName = 'base'
    condaPre = mc}
  condaCmd = file.path(condaPre, 'condabin', 'conda')

  args = c('env', 'export', '--name', safe(envName), '>',
           safe(file.path(outputDir, 'environment.yml')))
  system2(path.expand(condaCmd), args)
  invisible()}


system3 = function(...) {
  mc = getOption('seeker.miniconda', '~/miniconda3')
  p = path.expand(file.path(mc, c('bin/scripts', 'bin')))
  withr::local_path(p)
  system2(...)}


safe = function(x) {
  y = glue("'{path.expand(x)}'")
  return(y)}


checkCommand = function(cmd) {
  # if cmd doesn't exist, system2('command', ...) seems to
  # give warning on mac and error on linux
  old = getOption('warn')
  options(warn = -1)
  path = tryCatch({system3('command', c('-v', safe(cmd)), stdout = TRUE)},
                  error = function(e) NA_character_)
  options(warn = old)
  if (length(path) == 0) path = NA_character_
  return(path)}


#' Check for presence of command-line interfaces
#'
#' This function checks whether the command-line tools used by seeker are
#' accessible in the expected places.
#'
#' @return A data.table with columns for command, path, and version.
#'
#' @export
checkDefaultCommands = function() {
  d = data.table(
    # cmd = c('ascp', 'wget', 'fastqc', 'fastq_screen', 'trim_galore', 'cutadapt',
    #         'multiqc', 'salmon'),
    # idx = c(2, 1, 1, 1, 4, 1, 1, 1))
    cmd = c('prefetch', 'fasterq-dump', 'pigz', 'fastqc', 'fastq_screen',
            'trim_galore', 'cutadapt', 'multiqc', 'salmon'),
    idx = c(2, 2, 1, 1, 1, 4, 1, 1, 1))

  i = NULL
  r = foreach(i = seq_len(nrow(d)), .combine = rbind) %do% {
    # cmd = if (d$cmd[i] == 'ascp') getAscpCmd() else d$cmd[i]
    cmd = d$cmd[i]
    path = checkCommand(cmd)
    version = if (is.na(path)) NA_character_ else
      system3(path.expand(cmd), '--version', stdout = TRUE)[d$idx[i]]
    data.table(command = d$cmd[i], path = path, version = version)}

  return(r)}


assertCommand = function(cmd, cmdName, defaultPath) {
  if (is.null(cmd)) {
    if (is.na(defaultPath)) {
      stop(glue('{cmdName} is not available at the default location.'))}
  } else {
    path = checkCommand(cmd)
    if (is.na(path)) {
      stop(glue("'{cmd}' is not a valid command."))}}
  invisible()}

addToProfile = function(line) {
  profilePath = if (Sys.info()[['sysname']] == 'Darwin') '~/.zshrc' else '~/.bashrc'
  profileFile = readLines(profilePath)
  if (!(line %in% profileFile)) {
    profileFile = c(profileFile, line)
    writeLines(profileFile, profilePath)
  }
}

trimSlashes = function(dirToTrim) {
  if (endsWith(dirToTrim, '/')) dirToTrim = substring(dirToTrim, 1, nchar(dirToTrim) - 1)
  return(dirToTrim)}

installSRAToolkit = function(sraVersion = '3.0.0', installDir = '.', addToPath = TRUE, os = Sys.info()[['sysname']]) {
  installDir = trimSlashes(installDir)
  prevWd = getwd()
  setwd(installDir)
  sraOsTar = if (os == 'Darwin') 'mac64' else 'ubuntu64'
  sraTar = glue('sratoolkit.{sraVersion}-{sraOsTar}.tar.gz')
  sraPath = file.path(installDir, sub('.tar.gz', '', sraTar, fixed = TRUE), 'bin')
  system2(
    'curl',
    c('-O',
      glue('https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/{sraVersion}/{sraTar}')))
  system2('tar', c('-zxvf', glue('{sraTar}')))
  system2('rm', c('sratoolkit*.tar.gz'))
  setwd(prevWd)
  if (addToPath) {
    addToProfile(paste0('export PATH="$PATH:', path.expand(sraPath), '"'))
    Sys.setenv(
      PATH = paste(Sys.getenv('PATH'),
                   path.expand(sraPath), sep = ':'))}
}

installMiniconda = function(installDir = '~', setSeekerOption = TRUE, os = Sys.info()[['sysname']]) {
  installDir = trimSlashes(installDir)
  miniOsSh = if (os == 'Darwin') 'MacOSX' else 'Linux'
  miniSh = glue('Miniconda3-latest-{miniOsSh}-x86_64.sh')
  system2(
    'curl',
    c('-O',
      glue('https://repo.anaconda.com/miniconda/{miniSh}')))
  system2('sh', c(miniSh, '-b', '-p', file.path(installDir, 'miniconda3')))
  system2('rm', c('Miniconda3*.sh'))
  system(paste0(file.path(installDir, 'miniconda3'), '/bin/conda init bash'))
  if (setSeekerOption) {
    options(seeker.miniconda = file.path(installDir, 'miniconda3'))}
}

installTools = function(steps = 'all',
                        sraVersion = '3.0.0', sraDir = '.', sraAddToPath = TRUE,
                        minicondaDir = '~', setSeekerOption = TRUE,
                        mambaPkgs = c('fastq-screen',
                                      'fastqc',
                                      'multiqc',
                                      'pigz',
                                      'refgenie',
                                      'salmon',
                                      'trim-galore'),
                        refgenieDir = '~/genomes',
                        salmonIndexes = NULL, fetchGenomes = FALSE) {
  os = Sys.info()[['sysname']]
  if (steps == 'all') steps = c('SRA Toolkit',
                                'Miniconda',
                                'bioconda',
                                'mamba',
                                'Install mamba packages',
                                'refgenie',
                                'salmon index',
                                'fastq_screen get genomes')
  if ('SRA Toolkit' %in% steps) {
    installSRAToolkit(sraVersion, sraDir, os)}

  if ('Miniconda' %in% steps) {
    installMiniconda(minicondaDir, setSeekerOption, os)
  }

  if ('bioconda' %in% steps) {
    system3('conda', c('config', '--add', 'channels', 'defaults'))
    system3('conda', c('config', '--add', 'channels', 'bioconda'))
    system3('conda', c('config', '--add', 'channels', 'conda-forge'))
  }

  if ('mamba' %in% steps) {
    system3('conda', c('install', '--yes', 'mamba', '-c', 'conda-forge'))
  }

  if ('Install mamba packages' %in% steps && length(mambaPkgs) > 0) {
    system3('mamba', c('install', '--yes', mambaPkgs))
  }

  if ('refgenie' %in% steps) {
    if(!dir.exists(refgenieDir)) dir.create(refgenieDir)
    system3('refgenie', c('init', '-c', file.path(refgenieDir, 'genome_config.yaml')))
    addToProfile(paste0('export REFGENIE="', file.path(refgenieDir, 'genome_config.yaml'), '"'))
  }

  if ('salmon index' %in% steps) {
    if (is.null(salmonIndexes) || length(salmonIndexes) == 0) {
      stop('If pulling salmon indexes, must provide at least one index to pull.')}
    for (salmonIndex in salmonIndexes) {
      system3('refgenie', c('pull', '-c', salmonIndex))
    }
  }

  if ('fastq_screen get genomes' %in% steps) {
    system3('fastq_screen', c('--get_genomes'))
  }

}
