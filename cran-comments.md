## Resubmission Notes

This package was originally submitted as 1.0.1 on 2022/06/16, then again as 1.0.3 on 2022/07/04. There were errors on the win builder pre-checks, and the following notes pertain to the 2nd submission.

The problems were found to be the following:

1. The builds were failing because the R-devel (4.3) version of R is being used, and Bioconductor isn't available for R 4.3 yet. This package will install gene mapping packages from BioConductor if they aren't found, which was causing some test failures. The related tests are now skipped on CRAN, but the results can still be seen at the below links for test results.
2. The NOTE concerning the "possibly" invalid URL is wrong. The URL is fine and can be accessed.

This should cover all issues brought up with the first resubmission.

## Important information about the package

The primary functions in this package are either wrappers to various CLIs used in the fetching and processing of RNA-Seq transcriptome data, or functions that handle fetching and processing of Microarray transcriptome data. Due to this, we have to skip many tests not only on cran, but in any environment in which the system dependencies cannot be found. We include functions that install and configure the system dependencies, as well as maintain a Docker image that can be used with the package. Due to these requirements, the majority of the package's functionality is limited to Linux and Mac operating systems.

Included below are the local checks (Mac) and rhub checks (Windows, Ubuntu, Mac). The local check is run with all system dependencies available and fully tests the package, as opposed to the rhub checks which simply skip the majority of tests. If you wish to see the results of a full online check, see the checks run on Windows, Ubuntu, and Mac using our GitHub Actions workflows [here](https://github.com/hugheylab/seeker/actions). Additionally, if you wish to see coverage reports of tests done in a Ubuntu environment, you can see the Codecov report [here](https://app.codecov.io/gh/hugheylab/seeker).

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

  > checking for detritus in the temp directory ... NOTE
  Found the following files/directories:
    'lastMiKTeXException'

  0 errors ✓ | 0 warnings ✓ | 2 notes x
  

`devtools::check_rhub()` Ubuntu result:

  > checking CRAN incoming feasibility ... NOTE
  Maintainer: ‘Jake Hughey <jakejhughey@gmail.com>’
  
  New submission

  0 errors ✓ | 0 warnings ✓ | 1 notes x
  

`devtools::check_rhub()` Mac M1 result:

  0 errors ✓ | 0 warnings ✓ | 0 notes x

Online check notes:
  - The "lastMiKTeXException" note in the windows environment only occurs on Windows rhub environments, and can be ignored.

You can also see the results of R CMD check on Windows, Linux, and MacOS by going to the GitHub Actions run labeled `check-deploy` [here](https://github.com/hugheylab/seeker/actions).

## Downstream dependencies
There are no downstream dependencies for seeker.