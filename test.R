# mkdir seq_data/PRJNA237293
# cd seq_data/PRJNA237293

library('seeker')
doParallel::registerDoParallel(cores = min(parallel::detectCores() / 2, 24))

# add log tsv for getFastq, fastqc, fastqscreen
# revise how salmon and trimgalore handle missing files - require all files exist?

# after installing miniconda, setting up bioconda, and installing aspera connect
# conda install fastqc
# conda install multiqc
# conda install salmon
# conda install trim-galore
# conda install fastq-screen # installs dependencies, but itself not the latest version
# https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/fastq_screen_v0.13.0.tar.gz
# run fastq_screen --get_genomes

study = 'PRJNA237293'
fastqDir = 'fastq'
quantDir = 'salmon_output'

metadata = getMetadata(study)
metadata = metadata[1:2, , drop = FALSE]

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

fastqc(metadata$fastq_local)
fastqscreen(metadata$fastq_local)

salmon(metadata$fastq_local, metadata$run_accession, quantDir,
       indexPath = '~/transcriptomes/mus_musculus_transcripts')
tximport(file.path(quantDir, metadata$run_accession),
         ensemblDataset = 'mmusculus_gene_ensembl')

multiqc()
