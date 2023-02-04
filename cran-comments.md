## R CMD check results

### Local

`devtools::check()`:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

`devtools::check_rhub(env_vars = c('_R_CHECK_FORCE_SUGGESTS_' = 'false'))`:

  ❯ checking CRAN incoming feasibility ... [68s] NOTE
    Maintainer: 'Jake Hughey <jakejhughey@gmail.com>'
    
    Suggests or Enhances not in mainstream repositories:
      ArrayExpress
    
    Found the following (possibly) invalid URLs:
      URL: https://www.ncbi.nlm.nih.gov/geo/
        From: inst/doc/introduction.html
        Status: 404
        Message: Not Found
  
  ❯ checking package dependencies ... NOTE
    Package suggested but not available for checking: 'ArrayExpress'
  
  ❯ checking Rd cross-references ... NOTE
    Package unavailable to check Rd xrefs: 'ArrayExpress'
  
  ❯ checking for detritus in the temp directory ... NOTE
    Found the following files/directories:
      'lastMiKTeXException'

The URL noted above is valid.

See results for [Windows](https://builder.r-hub.io/status/seeker_1.1.0.tar.gz-cbec013e7dbb4d5b9c6f629a3b584afc), [Ubuntu](https://builder.r-hub.io/status/seeker_1.1.0.tar.gz-3d4605d9684e4806b5aff4fe1e0243ad), and [Fedora](https://builder.r-hub.io/status/seeker_1.1.0.tar.gz-80f24404244741a591e9acc1dd37a4da).

### GitHub Actions

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

See results for Mac, Windows, and Ubuntu [here](https://github.com/hugheylab/seeker/actions/runs/4093123590).

## Changes from current CRAN release

* Fixed handling of whitespace in file paths while installing miniconda.
* Updated test snapshots for latest version of org.Mm.eg.db.
* Removed dependency on ArrayExpress package
