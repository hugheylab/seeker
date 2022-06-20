#!/bin/sh

docker run \
  --mount type=bind,src=`pwd`,dst=/home/rstudio/projects \
  -w /home/rstudio/projects \
  --rm \
  ghcr.io/hugheylab/socker \
  bash -c "Rscript -e "'"'"seeker::seekerArray('GSE25585', 'ensembl', parentDir = '.')"'"' \
  &> GSE25585_progress.log
