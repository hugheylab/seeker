## Resubmission Notes

This package was originally submitted as 1.0.1 on 2022/06/16, again as 1.0.3 on 2022/07/04, as 1.0.4 on 2022/07/06, as 1.0.5 on 2022/07/07, and most recently as 1.0.8 on 2022/07/19. We received the following feedback about v1.0.8:

"Please always explain all acronyms in the description text. -> 'RMA'; ...

Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'tximport'
Please note that package names are case sensitive.

Please write references in the description of the DESCRIPTION file in
the form
authors (year) <doi:...>
authors (year) <arXiv:...>
authors (year, ISBN:...)
or if those are not available: authors (year) <https:...>
with no space after 'doi:', 'arXiv:', 'https:' and angle brackets for
auto-linking.
(If you want to add a title as well please put it in quotes: "Title")

You are still setting options(warn=-1) in your function. This is not
allowed. (utils.R line 153)

Please do not install packages in your functions, examples or vignette.
This can make the functions,examples and cran-check very slow."

We have addressed the feedback in this message and now are submitting version 1.0.9 to CRAN.

## Important information about the package

The primary functions in this package are either wrappers to various CLIs used in the fetching and processing of RNA-Seq transcriptome data, or functions that handle fetching and processing of Microarray transcriptome data. Due to this, we have to skip many tests not only on cran, but in any environment in which the system dependencies cannot be found. We include functions that install and configure the system dependencies, as well as maintain a Docker image that can be used with the package. Due to these requirements, the majority of the package's functionality is limited to Linux and Mac operating systems.

Included below are the local checks (Mac) and rhub checks (Windows, Ubuntu, Mac). The local check is run with all system dependencies available and fully tests the package, as opposed to the rhub checks which simply skip the majority of tests. If you wish to see the results of a full online check, see the checks run on Windows, Ubuntu, and Mac using our GitHub Actions workflows [here](https://github.com/hugheylab/seeker/actions). Additionally, if you wish to see coverage reports of tests done in a Ubuntu environment, you can see the Codecov report [here](https://app.codecov.io/gh/hugheylab/seeker).

If you decide to reject the package for CRAN, please give us some feedback on what we would need to modify to make a CRAN release feasible (if that is possible).

## R CMD check results

### Local check
`devtools::check()` result:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### Online check

RHUB has disabled their windows and linux environments "due to a billing issue". Additionally, at the time of submission, the Mac M1 R-project builder website is having gateway issues. In lieu, `devtools::check_win_devel()` and `devtools::check_rhub(platforms = 'macos-m1-bigsur-release')` were run in addition to the local check (run on an Intel Macbook).

`devtools::check_win_devel()` Windows result:

  > Maintainer: 'Jake Hughey <jakejhughey@gmail.com>'

    New submission
    
    Possibly misspelled words in DESCRIPTION:
      Genomic (3:16)
      microarray (9:54)
    
    Found the following (possibly) invalid URLs:
      URL: https://www.ebi.ac.uk/arrayexpress/
        From: inst/doc/introduction.html
        Status: 400
        Message: Bad Request

  0 errors ✓ | 0 warnings ✓ | 1 note x
  
`devtools::check_rhub(platforms = 'macos-m1-bigsur-release')` Mac M1 result:


  0 errors ✓ | 0 warnings ✓ | 0 notes ✔
  

Online check notes:
  - The spellings and URL are all valid, so ignore this error.

You can also see the results of R CMD check on Windows, Linux, and MacOS by going to the GitHub Actions run labeled `check-deploy` [here](https://github.com/hugheylab/seeker/actions).

## Downstream dependencies
There are no downstream dependencies for seeker.