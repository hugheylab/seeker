## R CMD check results

### Local

`devtools::check()` result:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

The R-hub checks are not working due to R-hub not installing Bioconductor packages. This appears to be a known issue.

### GitHub Actions

Results for Windows, Linux, and MacOS are [here](https://github.com/hugheylab/seeker/actions/workflows/check-deploy.yaml).

## Additional information

One of the tests was failing due to apparent unavailability of an internet resource. The corresponding function in the `seeker` package calls a function in the `ArrayExpress` package, which handles such cases by not throwing an error and instead printing console messages about which files it was able to download and which files not. Because the `ArrayExpress` function determines which files to try to download in the first place, the function in the `seeker` package would have to capture and parse the console messages in order to know the expected output of the test. In addition, upon further inspection, the problem was not that the internet file was unavailable, but that the download of the file was timing out. 

I have revised the package as follows:

- Within the relevant function, increase the timeout option as appropriate to the approximate expected file size. The exported function `seekerArray()`, which calls the function whose test was failing, already does this.
- On CRAN, the test now simply checks that the function runs without error. If not on CRAN, the test works as before.
- The test now attemps to download smaller files, to reduce test runtime.
