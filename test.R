library('seeker')
doParallel::registerDoParallel(cores = min(parallel::detectCores() / 2, 24))

############################################################
# paired-end mouse

study = 'PRJNA237293'
fastqDir = file.path(study, 'fastq')
quantDir = file.path(study, 'salmon_output')

metadataSra = getMetadataSra(study)
readr::write_csv(metadataSra, 'metadata_sra.csv')

metadata = getMetadataEna(study)
readr::write_csv(metadata, 'metadata_ena.csv')
metadata = metadata[1:2, , drop = FALSE]

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

fastqc(metadata$fastq_local, file.path(study, 'fastqc_output'))
fastqscreen(metadata$fastq_local, file.path(study, 'fastqscreen_output'))

salmon(metadata$fastq_local, metadata$run_accession, quantDir,
       indexPath = '~/transcriptomes/mus_musculus_transcripts')
tx2gene = getTx2gene('mmusculus_gene_ensembl')
tximport(file.path(quantDir, metadata$run_accession), tx2gene,
         file.path(study, 'tximport_output.rds'))

multiqc(study, file.path(study, 'multiqc_output'))

############################################################
# single-end human

study = 'PRJNA436224'
fastqDir = file.path(study, 'fastq')
quantDir = file.path(study, 'salmon_output')

metadataSra = getMetadataSra(study)
readr::write_csv(metadataSra, 'metadata_sra.csv')

metadata = getMetadataEna(study)
metadata = metadata[1:2, , drop = FALSE]

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

fastqc(metadata$fastq_local, file.path(study, 'fastqc_output'))
fastqscreen(metadata$fastq_local, file.path(study, 'fastqscreen_output'))

salmon(metadata$fastq_local, metadata$run_accession, quantDir)
tx2gene = getTx2gene()
tximport(file.path(quantDir, metadata$run_accession), tx2gene,
         file.path(study, 'tximport_output.rds'))

multiqc(study, file.path(study, 'multiqc_output'))
