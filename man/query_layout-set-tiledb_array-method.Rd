% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\name{query_layout<-}
\alias{query_layout<-}
\alias{query_layout<-,tiledb_array-method}
\title{Set query_layout return values for the array}
\usage{
query_layout(x) <- value

\S4method{query_layout}{tiledb_array}(x) <- value
}
\arguments{
\item{x}{A \code{tiledb_array} object}

\item{value}{A character variable for the query layout. Permitted values
are \dQuote{ROW_MAJOR}, \dQuote{COL_MAJOR}, \dQuote{GLOBAL_ORDER}, or
\dQuote{UNORDERD}.}
}
\value{
The modified \code{tiledb_array} array object
}
\description{
A \code{tiledb_array} object can have an associated query with a specific
layout. This methods sets the selection value for \sQuote{query_layout}
from a  character value.
}
