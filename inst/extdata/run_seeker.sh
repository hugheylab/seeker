##########
# if refgenie genomes folder and salmon index available on host

docker run \
  --mount type=bind,src=/Users/jakehughey/projects,dst=/home/rstudio/projects \
  --mount type=bind,src=/Users/jakehughey/genomes,dst=/home/rstudio/genomes \
  -w /home/rstudio/projects \
  --rm \
  ghcr.io/hugheylab/socker \
  bash -c "Rscript run_seeker.R GSE113883.yml ." \
  &> progress.log

##########
# if refgenie genomes folder not available on host

docker run \
  --mount type=bind,src=/Users/jakehughey/projects,dst=/home/rstudio/projects \
  -w /home/rstudio/projects \
  --rm \
  ghcr.io/hugheylab/socker \
  bash -c \
    "source /home/rstudio/miniconda3/etc/profile.d/conda.sh \
      && conda activate \
      && refgenie pull mm10/salmon_partial_sa_index \
      && Rscript run_seeker.R GSE143524.yml ." \
  &> progress.log
