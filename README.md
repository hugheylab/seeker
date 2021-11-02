# seeker

[![check-deploy](https://github.com/hugheylab/seeker/workflows/check-deploy/badge.svg)](https://github.com/hugheylab/seeker/actions)
[![codecov](https://codecov.io/gh/hugheylab/seeker/branch/master/graph/badge.svg)](https://codecov.io/gh/hugheylab/seeker)
[![Netlify Status](https://api.netlify.com/api/v1/badges/a3d002cf-ca5c-427f-9963-061d282b1d1b/deploy-status)](https://app.netlify.com/sites/hardcore-aryabhata-980673/deploys)

`seeker` is an R package for fetching and processing sequencing data, especially RNA-seq data. Hopefully it helps you get what you're after, before the day you die.

## Installation

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

These instructions are for Unix-based systems, primarily Linux and macOS. If you're using Windows, you're doing it wrong.

1. Download and install [Aspera Connect](https://www.ibm.com/aspera/connect/). On Linux, you will likely have to download a tar.gz file (using `wget` or `curl`), untar it (using `tar -zxvf`), then run the resulting shell script. On macOS, you may have to install a browser extension first, then install Connect from a dmg file.

1. Install [Miniconda](https://conda.io/en/latest/miniconda.html). Use the default install location (~/miniconda3).
    
    On Linux:
    
    ```sh
    curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sh Miniconda3-latest-Linux-x86_64.sh
    ```

    On macOS:
    
    ```sh
    curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    sh Miniconda3-latest-MacOSX-x86_64.sh
    ```

1. Set up conda channels, including [bioconda](https://bioconda.github.io/user/install.html).

    ```sh
    conda config --add channels defaults
    conda config --add channels bioconda
    conda config --add channels conda-forge
    ```

1. Install the [mamba package manager](https://github.com/mamba-org/mamba).

    ```sh
    conda install mamba -c conda-forge
    ```

1. Install the other command-line tools. The code below will install the packages into the base conda environment. If you use an environment other than base, please see the last step of this readme.

    ```sh
    mamba install refgenie trim-galore fastqc fastq-screen salmon multiqc
    ```

1. Optionally, configure [refgenie](http://refgenie.databio.org/en/latest/install). For example:

    ```sh
    mkdir -p ${HOME}/genomes
    refgenie init -c ${HOME}/genomes/genome_config.yaml
    ```
    
    Then you can add the following line to ~/.bashrc, ~/.bash_profile, or ~/.zshrc, depending on your OS and shell.
    
    ```sh
    export REFGENIE="${HOME}/genomes/genome_config.yaml"
    ```
    
    Then `source` the file.

1. Optionally, use refgenie to fetch the salmon index files for the human and/or mouse transcriptomes.

    ```sh
    refgenie pull hg38/salmon_sa_index
    refgenie pull mm10/salmon_sa_index
    ```

1. Optionally, fetch the genomes for fastq-screen. This takes a long time, so don't bother unless you actually plan to run fastq-screen.

    ```sh
    fastq_screen --get_genomes
    ```

1. If you install Miniconda at a non-default location or install the system dependencies to a conda environment other than base, you will need to set a global option in each R session so `seeker` knows where to look. For example, if the dependencies are in an environment called "seeker" that `conda env list` says is located at ~/miniconda3/envs/seeker, then you should do the following:

    ```r
    options(seeker.miniconda = '~/miniconda3/envs/seeker')
    ```
