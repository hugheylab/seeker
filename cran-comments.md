## R CMD check results

### Local

`devtools::check()`:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

R-hub builds are giving errors because "Bioconductor does not yet build and check packages for R version 4.4".

See results for [Windows](https://builder.r-hub.io/status/seeker_1.1.3.tar.gz-7dd2f5c93e324fceb89b5451f55325ec), [Ubuntu](https://builder.r-hub.io/status/seeker_1.1.3.tar.gz-e086fb7a85834001b34f4a6111838921), and [Fedora](https://builder.r-hub.io/status/seeker_1.1.3.tar.gz-c75d4dfc8fd74825b4fbac365d27c862).

### GitHub Actions

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

See results for Mac, Windows, and Ubuntu [here]().

## Changes from current CRAN release

* Updated test for fetching metadata, this time to make it less sensitive to arbitrary changes on the remote resource.
* `fetchMetadata()` now orders its result.
