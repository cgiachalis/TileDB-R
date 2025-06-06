% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Ctx.R
\name{tiledb_ctx_set_tag}
\alias{tiledb_ctx_set_tag}
\title{Sets a string:string "tag" on the Ctx}
\usage{
tiledb_ctx_set_tag(object, key, value)
}
\arguments{
\item{object}{\code{tiledb_ctx} object}

\item{key}{string}

\item{value}{string}
}
\description{
Sets a string:string "tag" on the Ctx
}
\examples{
\dontshow{
ctx <- tiledb_ctx(limitTileDBCores())
}
ctx <- tiledb_ctx(c("sm.tile_cache_size" = "10"))
cfg <- tiledb_ctx_set_tag(ctx, "tag", "value")

}
