# seeker

[![check-deploy](https://github.com/hugheylab/seeker/workflows/check-deploy/badge.svg)](https://github.com/hugheylab/seeker/actions)
[![codecov](https://codecov.io/gh/hugheylab/seeker/branch/master/graph/badge.svg)](https://codecov.io/gh/hugheylab/seeker)
[![Netlify Status](https://api.netlify.com/api/v1/badges/a3d002cf-ca5c-427f-9963-061d282b1d1b/deploy-status)](https://app.netlify.com/sites/hardcore-aryabhata-980673/deploys)
[![CRAN Status](https://www.r-pkg.org/badges/version/seeker)](https://cran.r-project.org/package=seeker)
[![drat version](https://raw.githubusercontent.com/hugheylab/drat/gh-pages/badges/seeker_drat_badge.svg)](https://github.com/hugheylab/drat/tree/gh-pages/src/contrib)

`seeker` is an R package for fetching and processing sequencing data, especially RNA-seq data, as well as microarray data. Hopefully it helps you get what you're after, before the day you die. For more details, check out the [preprint](https://doi.org/10.1101/2022.08.30.505820).

## Installation

To use `seeker`, you can install `seeker` and its dependencies, or use a pre-built Docker image in which `seeker` and its dependencies are already installed.

### R package and dependencies

1. Install the `BiocManager` R package.

    ```r
    if (!requireNamespace('BiocManager', quietly = TRUE))
      install.packages('BiocManager')
    ```

1. Install the `seeker` R package, either from CRAN or from the Hughey Lab drat repository. We use `BiocManager::install()` in order to smoothly install `seeker`'s dependencies that are on Bioconductor.
    
    ```r
    BiocManager::install('seeker') # CRAN
    # BiocManager::install('seeker', site_repository = 'https://hugheylab.github.io/drat/') # drat
    ```

1. Install the system dependencies to fetch and process sequencing data. The simplest way to do this is to use the function [`installSysDeps()`](https://seeker.hugheylab.org/reference/installsysdeps). For example,

    ```r
    seeker::installSysDeps('~', '~', '~', '~')
    ```
    
    You can also use `installSysDeps()` to fetch genomes from refgenie, such as those required to quantify transcript abundances using salmon.

### Docker image

The Docker image is called [socker](https://github.com/hugheylab/socker) and is based on [rocker/rstudio](https://github.com/rocker-org/rocker-versioned2).

```sh
docker pull ghcr.io/hugheylab/socker
```

## Usage

For an introduction to the package, read the [vignette](https://seeker.hugheylab.org/articles/introduction.html). For more details, check out the [reference documentation](https://seeker.hugheylab.org/reference/index.html).
