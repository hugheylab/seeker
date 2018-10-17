# seeker
`seeker` is an R package for processing sequencing data, especially RNA-seq data. Hopefully it helps you get to what you're after before the day you die.

## Installation

1. Install miniconda, bioconda, and R using the instructions in the reference repo.

1. Download and install Aspera Connect for Linux (https://downloads.asperasoft.com/en/downloads/8?list). You will likely have to download a tar.gz file, untar it, then run the resulting bash shell script.

1. Install the other command-line tools.
    ```bash
    conda install fastqc
    conda install multiqc
    conda install salmon
    conda install trim-galore
    conda install fastq-screen # installs dependencies, but itself not the latest version
    wget https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/fastq_screen_v0.13.0.tar.gz
    tar -zxvf fastq_screen_v0.13.0.tar.gz
    ~/fastq_screen_v0.13.0/fastq_screen --get_genomes
    ```

1. Install the `biomaRt` and `tximport` packages from Bioconductor.

1. Clone the git repo, build the source package, then do something like
    ```r
    install.packages('seeker_0.0.0.9001.tar.gz', type = 'source', repos = NULL)
    ```
