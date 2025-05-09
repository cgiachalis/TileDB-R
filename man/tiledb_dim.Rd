% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Dim.R
\name{tiledb_dim}
\alias{tiledb_dim}
\title{Constructs a \code{tiledb_dim} object}
\usage{
tiledb_dim(
  name,
  domain,
  tile,
  type,
  filter_list = tiledb_filter_list(),
  ctx = tiledb_get_context()
)
}
\arguments{
\item{name}{The dimension name / label string.  This argument is required.}

\item{domain}{The dimension (inclusive) domain. The domain of a dimension
is defined by a (lower bound, upper bound) vector. For type \code{ASCII},
\code{NULL} is expected.}

\item{tile}{The tile dimension tile extent. For type
\code{ASCII}, \code{NULL} is expected.}

\item{type}{The dimension TileDB datatype string.}

\item{filter_list}{An optional \code{tiledb_filter_list} object, default
is no filter}

\item{ctx}{tiledb_ctx object (optional)}
}
\value{
A \code{tiledb_dim} object
}
\description{
Constructs a \code{tiledb_dim} object
}
\examples{
\dontshow{
ctx <- tiledb_ctx(limitTileDBCores())
}
tiledb_dim(name = "d1", domain = c(1L, 10L), tile = 5L, type = "INT32")

}
