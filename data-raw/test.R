library('data.table')
library('doFuture')
library('seeker')

registerDoFuture()
nCores = round(availableCores() * 0.5)
plan(multisession, workers = nCores)

study = 'PRJNA297287'
dir.create(study)
fastqDir = file.path(study, 'fastq')
quantDir = file.path(study, 'salmon_output')

metadata = setDT(getMetadata(study))
fwrite(metadata, file.path(study, 'metadata_ena.csv'))

# has to be downloaded manually
# metadataSra = setDT(readr::read_tsv(file.path(study, 'SraRunTable.txt')))
metadataSra = fread(file.path(study, 'SraRunTable.txt'))

metadata = merge(
  metadata, metadataSra,
  by.x = c('sample_accession', 'secondary_sample_accession',
           'experiment_accession', 'run_accession'),
  by.y = c('BioSample', 'SRA_Sample', 'Experiment', 'Run'))

metadata = metadata[feeding == 'Ad Libitum' & genotype == 'Wild type']

fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

# fastqc(metadata$fastq_local, file.path(study, 'fastqc_output'))

salmon(metadata$fastq_local, metadata$secondary_sample_accession, quantDir,
       indexPath = '~/transcriptomes/mus_musculus_transcripts')

tx2gene = getTx2gene('mmusculus_gene_ensembl')
tximport(file.path(quantDir, sort(unique(metadata$secondary_sample_accession))),
         tx2gene, file.path(study, 'tximport_output.rds'))

# multiqc(study, file.path(study, 'multiqc_output'))





fastqResult = getFastq(metadata$fastq_aspera, fastqDir)
metadata$fastq_local = fastqResult$localFilepaths

remoteFilepaths = metadata$fastq_aspera[fastqResult$statuses != 0]

while (length(remoteFilepaths) > 0) {
  fastqResult = getFastq(remoteFilepaths, fastqDir)
  remoteFilepaths = remoteFilepaths[fastqResult$statuses != 0]
}
