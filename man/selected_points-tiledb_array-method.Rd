% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\name{selected_points}
\alias{selected_points}
\alias{selected_points,tiledb_array-method}
\title{Retrieve selected_points values for the array}
\usage{
selected_points(object)

\S4method{selected_points}{tiledb_array}(object)
}
\arguments{
\item{object}{A \code{tiledb_array} object}
}
\value{
A list which can contain a vector for each dimension
}
\description{
A \code{tiledb_array} object can have a range selection for each dimension
attribute. This methods returns the selection value for
\sQuote{selected_points} and returns a list (with one element per dimension)
of vectors where each row describes one selected points. Alternatively, the
list can be named with the names providing the match to the
corresponding dimension.
}
