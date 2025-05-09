% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\name{extended<-}
\alias{extended<-}
\alias{extended<-,tiledb_array-method}
\title{Set data.frame extended return columns toggle}
\usage{
extended(x) <- value

\S4method{extended}{tiledb_array}(x) <- value
}
\arguments{
\item{x}{A \code{tiledb_array} object}

\item{value}{A logical value with the selection}
}
\value{
The modified \code{tiledb_array} array object
}
\description{
A \code{tiledb_array} object can be returned as \code{data.frame}. This
methods set the selection value for \sQuote{extended} format including row
(and column, if present) indices.
}
