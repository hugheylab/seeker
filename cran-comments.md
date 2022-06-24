## Resubmission Notes

This package was originally submitted as 1.0.1 on 2022/06/16. There were errors on win builder as can be found here (if files aren't gone now): https://win-builder.r-project.org/incoming_pretest/seeker_1.0.1_20220617_021039/

The problems were found to be the following:

1. The Debian build was failing because it is running the R-devel (4.3) version of R, and Bioconductor isn't available for R 4.3 yet. Since this is out of our control and is (I assume) affecting other packages as well, I don't believe we should take any action.
2. The NOTE concerning the "possibly" invalid URL is wrong. The URL is fine and can be accessed.
3. The ERROR on Windows due to test failures has been resolved. The test was using a package that contains gene mappings for organisms, so if the version of the package present while running the test didn't match the exact version used to generate the snapshot, the test would fail. Conditions were added to the test to skip if it isn't the same version, and produce a warning if a new version of the mapping package is available.

This should cover all issues brought up with the original submission.

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