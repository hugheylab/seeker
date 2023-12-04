## R CMD check results

### Local

`devtools::check()`:

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

### R-hub

`devtools::check_rhub()`:

  0 errors ✓ | 0 warnings ✓ | 2 notes ✓
  
❯ checking for non-standard things in the check directory ... NOTE
  Found the following files/directories:
    ''NULL''

❯ checking for detritus in the temp directory ... NOTE
  Found the following files/directories:
    'lastMiKTeXException'

See results for [Windows](https://builder.r-hub.io/status/seeker_1.1.4.tar.gz-1fd21b320f264289820666012a924a8a), [Ubuntu](https://builder.r-hub.io/status/seeker_1.1.4.tar.gz-dd2ecaaf51d24135a360cee4e0b8a858), and [Fedora](https://builder.r-hub.io/status/seeker_1.1.4.tar.gz-6cfb237d17794ae5bd6fa302781fb7b0).

### GitHub Actions

  0 errors ✓ | 0 warnings ✓ | 0 notes ✓

See results for Mac, Windows, and Ubuntu [here]().

## Changes from current CRAN release

* Fixed processing of ArrayExpress data (thanks to @jacorvar).
* Removed deprecated argument from `biomaRt::listEnsemblArchives()`.
* Updated test standards.
