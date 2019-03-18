% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Filter.R
\name{tiledb_filter_get_option}
\alias{tiledb_filter_get_option}
\title{Returns the filter's option}
\usage{
tiledb_filter_get_option(object, option)
}
\arguments{
\item{object}{tiledb_filter}
}
\value{
integer option
}
\description{
Returns the filter's option
}
\examples{
ctx <- tiledb_ctx()
c <- tiledb_filter(ctx, "ZSTD")
tiledb_filter_set_option(c,"COMPRESSION_LEVEL", 5)
tiledb_filter_get_option(c, "COMPRESSION_LEVEL")

}