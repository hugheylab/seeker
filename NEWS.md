# seeker 1.1.3
* Updated test for fetching metadata again.

# seeker 1.1.2
* Updated test for fetching metadata.

# seeker 1.1.1
* Updated test expectations for altered column order in metadata from ENA.

# seeker 1.1.0
* Removed dependency on ArrayExpress package.

# seeker 1.0.14
* Fixed handling of whitespace in file paths while installing miniconda.

# seeker 1.0.13
* Updated for BioStudies API.

# seeker 1.0.12
* `fetchMetadata()` can now save the metadata to a text file.

# seeker 1.0.11
* Revised documentation.

# seeker 1.0.10
* Revised package for CRAN.

# seeker 1.0.9
* Revised "Description" text.y
* Skipped more tests on CRAN to avoid installation of packages.

# seeker 1.0.8
* Removed default install directories for dependencies in `installSysDeps()`.
* Replaced `options(warn=-1)` to use `suppressWarnings()`.
* Updated description text.
* Revised console printing.

# seeker 1.0.7
* Added support for more platforms.
* Added ability for `seekerArray()` to skip processing the expression data.

# seeker 1.0.6
* Added installation of snakemake by `installSysDeps()` for easier reproducible analyses.

# seeker 1.0.5
* Added argument to `installSysDeps()` to specify directory in which to create or modify .Rprofile.

# seeker 1.0.4
* Skipped "`getNaiveEsetAe()` supported" test on CRAN due to BioConductor issues.

# seeker 1.0.3
* Made `getProbeGeneMapping()` test check for version number of mapping package.
* Revised arguments for `seekerArray()` and updated tests and vignettes accordingly.

# seeker 1.0.2
* Set default parent directory for `seekerArray()`.
* Added custom CDF support for platform GPL17400.

# seeker 1.0.1
* Updated `seeker()` to save unmodified metadata file.

# seeker 1.0.0
* Updated `seeker()` to output info of SRA Toolkit-based dependencies.
* Revised tests and updated version number to prepare for a CRAN submission.

# seeker 0.0.0.9068
* Updated `run_seeker.sh` to use correct conda environment.
* Updated Reproducibility vignette to not require local installation of the R package. 

# seeker 0.0.0.9067
* Changed `species` to `organism` for consistency with NCBI and other packages.
* Added checking for parallel backend.

# seeker 0.0.0.9062
* Fixed syntax to adhere to lab code style.
