% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\name{array_consolidate}
\alias{array_consolidate}
\title{Consolidate fragments of a TileDB Array}
\usage{
array_consolidate(
  uri,
  cfg = NULL,
  start_time,
  end_time,
  ctx = tiledb_get_context()
)
}
\arguments{
\item{uri}{A character value with the URI of a TileDB Array}

\item{cfg}{An optional TileDB Configuration object}

\item{start_time}{An optional timestamp value, if missing config
default is used}

\item{end_time}{An optional timestamp value, if missing config default is used}

\item{ctx}{An option TileDB Context object}
}
\value{
NULL is returned invisibly
}
\description{
This function invokes a consolidation operation. Parameters affecting the
operation can be set via an optional configuration object. Start and end
timestamps can also be set directly.
}
