# seeker
`seeker` is an R package for fetching and processing sequencing data, especially RNA-seq data. Hopefully it helps you get to what you're after before the day you die.

## Installation

1. Install miniconda, bioconda, and R using the instructions in Notion.

1. Download and install Aspera Connect for Linux (https://downloads.asperasoft.com/en/downloads/8?list). You will likely have to download a tar.gz file (`wget`), untar it (`tar -zxvf`), then run the resulting bash shell script.

1. Install the other command-line tools.
    ```bash
    conda install fastq-screen fastqc multiqc salmon trim-galore
    fastq_screen --get_genomes # optional, very slow
    ```

1. Build a salmon index for each relevant species. Below are examples for mouse and human. See https://useast.ensembl.org/info/data/ftp/index.html.
    ```bash
    mkdir transcriptomes
    cd transcriptomes
    wget -O Mus_musculus.GRCm38.rel99.cdna.all.fa.gz ftp://ftp.ensembl.org/pub/release-99/fasta/mus_musculus/cdna/Mus_musculus.GRCm38.cdna.all.fa.gz
    salmon index -t Mus_musculus.GRCm38.rel99.cdna.all.fa.gz -i mus_musculus_transcripts
    wget -O Homo_sapiens.GRCh38.rel97.cdna.all.fa.gz ftp://ftp.ensembl.org/pub/release-99/fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz
    salmon index -t Homo_sapiens.GRCh38.rel99.cdna.all.fa.gz -i homo_sapiens_transcripts
    ```

1. Install the `biomaRt` and `tximport` packages from Bioconductor.
    ```r
    install.packages('BiocManager')
    BiocManager::install(c('biomaRt', 'tximport'))
    ```

1. Clone the git repo, build the source package, then do something like
    ```r
    install.packages('seeker_0.0.0.9001.tar.gz', type = 'source', repos = NULL)
    ```
