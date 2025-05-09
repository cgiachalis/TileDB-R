% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Config.R
\name{tiledb_config_as_built_json}
\alias{tiledb_config_as_built_json}
\title{Return the 'AsBuilt' JSON string}
\usage{
tiledb_config_as_built_json()
}
\value{
The JSON string containing 'AsBuilt' information
}
\description{
Return the 'AsBuilt' JSON string
}
\examples{
if (tiledb_version(TRUE) > "2.17") {
  txt <- tiledb::tiledb_config_as_built_json()
}
## now eg either one of
##   sapply(jsonlite::fromJSON(txt)$as_built$parameters$storage_backends, \(x) x[[1]])
##   sapply(RcppSimdJson::fparse(txt)$as_built$parameters$storage_backends, \(x) x[[1]])
## will return a named vector such as
##   c(azure = FALSE, gcs = FALSE, hdfs = FALSE, s3 = TRUE)
}
