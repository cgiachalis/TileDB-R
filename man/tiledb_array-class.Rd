% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TileDBArray.R
\docType{class}
\name{tiledb_array-class}
\alias{tiledb_array-class}
\title{An S4 class for a TileDB Array}
\description{
This class replaces the earlier (and now removed) \code{tiledb_dense}
and \code{tiledb_sparse} and provides equivalent functionality
based on a refactored implementation utilising newer TileDB features.
}
\section{Slots}{

\describe{
\item{\code{ctx}}{A TileDB context object}

\item{\code{uri}}{A character despription with the array URI}

\item{\code{is.sparse}}{A logical value whether the array is sparse or not}

\item{\code{attrs}}{A character vector to select particular column
\sQuote{attributes}; default is an empty character vector implying
\sQuote{all} columns, the special value \code{NA_character_} has the opposite
effect and selects \sQuote{none}.}

\item{\code{extended}}{A logical value, defaults to \code{TRUE}, indicating whether
index columns are returned as well.}

\item{\code{selected_ranges}}{An optional list with matrices where each matrix i
describes the (min,max) pair of ranges for dimension i}

\item{\code{selected_points}}{An optional list with vectors where each vector i
describes the selected points for dimension i}

\item{\code{query_layout}}{An optional character value}

\item{\code{datetimes_as_int64}}{A logical value}

\item{\code{encryption_key}}{A character value}

\item{\code{query_condition}}{A Query Condition object}

\item{\code{timestamp_start}}{A POSIXct datetime variable for the inclusive
interval start}

\item{\code{timestamp_end}}{A POSIXct datetime variable for the inclusive
interval start}

\item{\code{return_as}}{A character value with the desired \code{tiledb_array}
conversion, permitted values are \sQuote{asis} (default, returning a list
of columns), \sQuote{array}, \sQuote{matrix},\sQuote{data.frame},
\sQuote{data.table} \sQuote{tibble}, \sQuote{arrow_table} or \sQuote{arrow}
(where the last two are synomyms); note that \sQuote{data.table},
\sQuote{tibble} and \sQuote{arrow} require the respective packages
to be installed.}

\item{\code{query_statistics}}{A logical value, defaults to \sQuote{FALSE}; if
\sQuote{TRUE} the query statistics are returned (as a JSON string) via the
attribute \sQuote{query_statistics} of the return object.}

\item{\code{sil}}{An optional and internal list object with schema information, used
for parsing queries.}

\item{\code{dumpbuffers}}{An optional character variable with a directory name
(relative to \code{/dev/shm}) for writing out results buffers (for internal
use / testing)}

\item{\code{buffers}}{An optional list with full pathnames of shared memory buffers
to read data from}

\item{\code{strings_as_factors}}{An optional logical to convert character columns to
factor type}

\item{\code{keep_open}}{An optional logical to not close after read or write}

\item{\code{ptr}}{External pointer to the underlying implementation}
}}

