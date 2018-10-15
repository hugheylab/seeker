# add log tsv for getFastq, fastqc, fastqscreen
# after installing miniconda, setting up bioconda, and installing aspera connect
# conda install fastqc
# conda install multiqc
# conda install salmon
# conda install trim-galore
# conda install fastq-screen # installs dependencies, but itself not the latest version
# https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/fastq_screen_v0.13.0.tar.gz
# run fastq_screen --get_genomes

library('seeker')
doParallel::registerDoParallel(cores = min(parallel::detectCores() / 2, 24))

############################################################
# paired-end mouse

study = 'PRJNA237293'
fastqDir = file.path(study, 'fastq')
quantDir = file.path(study, 'salmon_output')

metadata = getMetadata(study)
metadata = metadata[1:2, , drop = FALSE]

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

fastqc(metadata$fastq_local, file.path(study, 'fastqc_output'))
fastqscreen(metadata$fastq_local, file.path(study, 'fastqscreen_output'))

salmon(metadata$fastq_local, metadata$run_accession, quantDir,
       indexPath = '~/transcriptomes/mus_musculus_transcripts')
tximport(file.path(quantDir, metadata$run_accession),
         file.path(study, 'tximport_output.rds'),
         ensemblDataset = 'mmusculus_gene_ensembl')

multiqc(study, file.path(study, 'multiqc_output'))

############################################################
# single-end human

study = 'PRJNA436224'
fastqDir = file.path(study, 'fastq')
quantDir = file.path(study, 'salmon_output')

metadata = getMetadata(study)
metadata = metadata[1:2, , drop = FALSE]

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

fastqc(metadata$fastq_local, file.path(study, 'fastqc_output'))
fastqscreen(metadata$fastq_local, file.path(study, 'fastqscreen_output'))

salmon(metadata$fastq_local, metadata$run_accession, quantDir)
tximport(file.path(quantDir, metadata$run_accession),
         file.path(study, 'tximport_output.rds'))

multiqc(study, file.path(study, 'multiqc_output'))
