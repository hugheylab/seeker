# mkdir seq_data/PRJNA237293
# cd seq_data/PRJNA237293

library('seeker')
doParallel::registerDoParallel(cores = min(parallel::detectCores() / 2, 24))

# add log tsv for getFastq, runFastqc, runFastqscreen

study = 'PRJNA237293'
fastqDir = 'raw'
quantDir = 'salmon_output'

metadata = getMetadata(study)
metadata = metadata[1:2, , drop = FALSE]
getFastq(metadata, fastqDir)
runFastqc(fastqDir)
runFastqscreen(fastqDir)
runSalmon(metadata, fastqDir, quantDir,
          indexPath = '~/transcriptomes/mus_musculus_transcripts')
runTximport(quantDir, paste0(study, '.rds'),
            ensemblDataset = 'mmusculus_gene_ensembl')
runMultiqc()

# run trim_galore
