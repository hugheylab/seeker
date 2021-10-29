# seeker

[![check-coverage-deploy](https://github.com/hugheylab/seeker/workflows/check-coverage-deploy/badge.svg)](https://github.com/hugheylab/seeker/actions)
[![codecov](https://codecov.io/gh/hugheylab/seeker/branch/master/graph/badge.svg)](https://codecov.io/gh/hugheylab/seeker)

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

These instructions are for Unix-based systems. If you're using Windows, you're doing it wrong.

1. Download and install [Aspera Connect](https://www.ibm.com/aspera/connect/). On Linux, you will likely have to download a tar.gz file (using `wget` or `curl`), untar it (using `tar -zxvf`), then run the resulting shell script. On macOS, you may have to install a browser extension first, then install Connect from a dmg file.

1. Install [Miniconda](https://conda.io/en/latest/miniconda.html). On Linux:
    
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

1. Install the other command-line tools. The code below will install the packages into the base conda environment; use `-n` to specify a different environment. When using `seeker`, you will need to ensure that R is running with the given conda environment.

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
    
    Then `source` the file and run `refgenie init`.

1. Optionally, use refgenie to fetch the salmon index files for the human and/or mouse transcriptomes.

    ```sh
    refgenie pull hg38/salmon_sa_index
    refgenie pull mm10/salmon_sa_index
    ```

1. Optionally, fetch the genomes for fastq-screen. This takes a long time, so don't bother unless you actually plan to run fastq-screen.

    ```sh
    fastq_screen --get_genomes
    ```
