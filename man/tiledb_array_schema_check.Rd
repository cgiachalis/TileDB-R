% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ArraySchema.R
\name{schema_check}
\alias{schema_check}
\alias{schema_check,tiledb_array_schema-method}
\alias{check}
\alias{check,tiledb_array_schema-method}
\alias{tiledb_array_schema_check}
\title{Check the schema for correctness}
\usage{
schema_check(object)

\S4method{schema_check}{tiledb_array_schema}(object)

check(object)

\S4method{check}{tiledb_array_schema}(object)

tiledb_array_schema_check(object)
}
\arguments{
\item{object}{A TileDB Schema object}
}
\value{
The boolean value \code{TRUE} is returned for a correct
schema; for an incorrect schema an error condition is triggered.
}
\description{
Returns the \code{tiledb_array} schema for correctness
}
