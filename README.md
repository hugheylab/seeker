# seeker

[![check-deploy](https://github.com/hugheylab/seeker/workflows/check-deploy/badge.svg)](https://github.com/hugheylab/seeker/actions)
[![codecov](https://codecov.io/gh/hugheylab/seeker/branch/master/graph/badge.svg)](https://codecov.io/gh/hugheylab/seeker)
[![Netlify Status](https://api.netlify.com/api/v1/badges/a3d002cf-ca5c-427f-9963-061d282b1d1b/deploy-status)](https://app.netlify.com/sites/hardcore-aryabhata-980673/deploys)

`seeker` is an R package for fetching and processing sequencing data, especially RNA-seq data, as well as microarray data. Hopefully it helps you get what you're after, before the day you die.

## Installation

### Docker image

`seeker` and its dependencies are available in a Docker image called [socker](https://github.com/hugheylab/socker), based on [rocker/rstudio](https://github.com/rocker-org/rocker-versioned2).

```sh
docker pull ghcr.io/hugheylab/socker
```

If you don't want to use Docker, you can follow the instructions below.

### R package

1. Install [`BiocManager`](https://cran.r-project.org/package=BiocManager).

    ```r
    if (!requireNamespace('BiocManager', quietly = TRUE))
      install.packages('BiocManager')
    ```

1. If you use RStudio, go to Tools → Global Options... → Packages → Add... (under Secondary repositories), then enter:

    - Name: hugheylab
    - Url: https://hugheylab.github.io/drat/

    You only have to do this once. Then you can install or update the package by entering:

    ```r
    BiocManager::install('seeker')
    ```

    Alternatively, you can install or update the package by entering:

    ```r
    BiocManager::install('seeker', site_repository = 'https://hugheylab.github.io/drat/')
    ```

### System dependencies

If not using the docker image, use [`seeker::installSysDeps()`](https://seeker.hugheylab.org/reference/installsysdeps) to conveniently install and configure the various programs required for `seeker` to fetch and process sequencing data.

## Usage

For an introduction to the package, read the [vignette](https://seeker.hugheylab.org/articles/introduction.html). For more details, check out the [reference documentation](https://seeker.hugheylab.org/reference/index.html).
