% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\name{tiledb_array_get_non_empty_domain_from_index}
\alias{tiledb_array_get_non_empty_domain_from_index}
\title{Get the non-empty domain from a TileDB Array by index}
\usage{
tiledb_array_get_non_empty_domain_from_index(arr, idx)
}
\arguments{
\item{arr}{A TileDB Array}

\item{idx}{An integer index between one and the number of dimensions}
}
\value{
A two-element object is returned describing the domain of selected
dimension; it will either be a numeric vector in case of a fixed-sized
dimension or a character vector for a variable-sized one.
}
\description{
This functions works for both fixed- and variable-sized dimensions and
switches internally.
}
