## R CMD check results

### Local

`devtools::check()`:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

`devtools::check_rhub()`:
  
  ❯ checking for detritus in the temp directory ... NOTE
    Found the following files/directories:
      'lastMiKTeXException'

The URL noted above is valid.

See results for [Windows](https://builder.r-hub.io/status/seeker_1.1.0.tar.gz-0c794b51ae724e0c987c11a18f91f705).

### GitHub Actions

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

See results for Mac, Windows, and Ubuntu [here](https://github.com/hugheylab/seeker/actions/runs/4093123590).

## Changes from current CRAN release

* Fixed handling of whitespace in file paths while installing miniconda.
* Updated test snapshots for latest version of org.Mm.eg.db.
* Moved ArrayExpress package from Imports to Suggests and updated code accordingly.
