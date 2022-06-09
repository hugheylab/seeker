## Important information about the package
This package is different from our previous submissions in many ways. The primary functions in this package are either wrappers to various CLIs used in the fetching and processing of RNA-Seq transcriptome data, or functions that handle fetching and processing of Microarray transcriptome data. Due to this, we have to skip many tests not only on cran, but in any environment in which the system dependencies cannot be found. We include functions that install and configure the system dependencies, as well as maintain a Docker image that can be used with the package. Due to these requirements, the majority of the package's functionality is limited to Linux and Mac operating systems.

Included below are the local checks (Mac) and rhub checks (Windows, Ubuntu, Mac). The local check is run with all system dependencies available and fully tests the package, as opposed to the rhub checks which simply skip the majority of tests. If you wish to see an online check and the results of a check, see the checks run on Windows, Ubuntu, and Mac using GitHub Actions [here](https://github.com/hugheylab/seeker/actions). Additionally, if you wish to see coverage reports of tests done in a Ubuntu environment, you can see the Codecov report [here](https://app.codecov.io/gh/hugheylab/seeker).

If you decide to reject the package for CRAN, please give us some feedback on what we would need to modify to make a CRAN release feasible (if that is possible).

## R CMD check results

### Local check
`devtools::check()` result:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### Online check
`devtools::check_rhub()` Windows result:

  > checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Jake Hughey <jakejhughey@gmail.com>'

  New submission

  Size of tarball: 9536357 bytes

  > checking for detritus in the temp directory ... NOTE
  Found the following files/directories:
    'lastMiKTeXException'

  0 errors ✓ | 0 warnings ✓ | 2 notes x
  

`devtools::check_rhub()` Ubuntu result:

  > checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Jake Hughey <jakejhughey@gmail.com>'

  New submission

  Size of tarball: 9536357 bytes

  0 errors ✓ | 0 warnings ✓ | 1 notes x
  

`devtools::check_rhub()` Mac result:

  0 errors ✓ | 0 warnings ✓ | 0 notes x

Online check notes:
  - The tarball is large (nearly 10MB) due to the amount of data required for adequate testing and use within the package. If this is found to be a problem, we can attempt to slim it down.
  - The "lastMiKTeXException" note in the windows environment only occurs on Windows rhub environments, and can be ignored.

You can also see the results of R CMD check on Windows, Linux, and MacOS by going to the GitHub Actions run labeled `check-deploy` [here](https://github.com/hugheylab/seeker/actions).

## Downstream dependencies
There are no downstream dependencies for seeker.