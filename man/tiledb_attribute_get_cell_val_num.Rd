% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Attribute.R
\name{cell_val_num}
\alias{cell_val_num}
\alias{cell_val_num,tiledb_attr-method}
\alias{tiledb_attribute_get_cell_val_num}
\title{Return the number of scalar values per attribute cell}
\usage{
cell_val_num(object)

\S4method{cell_val_num}{tiledb_attr}(object)

tiledb_attribute_get_cell_val_num(object)
}
\arguments{
\item{object}{\code{tiledb_attr} object}
}
\value{
integer number of cells
}
\description{
Return the number of scalar values per attribute cell
}
\examples{
\dontshow{
ctx <- tiledb_ctx(limitTileDBCores())
}
a1 <- tiledb_attr("a1", type = "FLOAT64", ncells = 1)
cell_val_num(a1)
}
