% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ArraySchema.R
\name{allows_dups}
\alias{allows_dups}
\alias{allows_dups,tiledb_array_schema-method}
\alias{tiledb_array_schema_get_allows_dups}
\title{Returns logical value whether the array schema allows duplicate values or not.
This is only valid for sparse arrays.}
\usage{
allows_dups(x)

\S4method{allows_dups}{tiledb_array_schema}(x)

tiledb_array_schema_get_allows_dups(x)
}
\arguments{
\item{x}{A TileDB Schema object}
}
\value{
A logical value.
}
\description{
Returns logical value whether the array schema allows duplicate values or not.
This is only valid for sparse arrays.
}
