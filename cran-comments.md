## R CMD check results

### Local

0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

The R-hub checks are not working due to R-hub not installing Bioconductor packages. This appears to be a known issue.

### GitHub Actions

The package is passing on Windows, Linux, and MacOS as shown [here](https://github.com/hugheylab/seeker/actions/runs/3285123317).

## Additional information

The recent issues with the seeker package seem to be due to EBI removing support for the ArrayExpress API. I have revised seeker's code to use the new BioStudies API. However, the seeker package is still dependent on the ArrayExpress package, which has not yet been updated to use the BioStudies API. Therefore, I added a tryCatch and disabled a few tests.
