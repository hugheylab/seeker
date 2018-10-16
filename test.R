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
