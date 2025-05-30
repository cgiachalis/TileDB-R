#  MIT License
#
#  Copyright (c) 2017-2022 TileDB Inc.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.

#' An S4 class for a TileDB domain
#'
#' @slot ptr External pointer to the underlying implementation
#' @exportClass tiledb_domain
setClass("tiledb_domain",
  slots = list(ptr = "externalptr")
)

tiledb_domain.from_ptr <- function(ptr) {
  stopifnot(`ptr must be a non-NULL externalptr to a tiledb_domain` = !missing(ptr) && is(ptr, "externalptr") && !is.null(ptr))
  return(new("tiledb_domain", ptr = ptr))
}

#' Constructs a `tiledb_domain` object
#'
#' All `tiledb_dim` must be of the same TileDB type.
#'
#' @param ctx tiledb_ctx (optional)
#' @param dims list() of tiledb_dim objects
#' @return tiledb_domain
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(
#'   tiledb_dim("d1", c(1L, 100L), type = "INT32"),
#'   tiledb_dim("d2", c(1L, 50L), type = "INT32")
#' ))
#' @importFrom methods slot
#' @importFrom methods new
#' @export tiledb_domain
tiledb_domain <- function(dims, ctx = tiledb_get_context()) {
  stopifnot(`Argument 'ctx' must be a tiledb_ctx object` = is(ctx, "tiledb_ctx"))
  is_dim <- function(obj) is(obj, "tiledb_dim")
  if (is_dim(dims)) { # if a dim object given:
    dims <- list(dims) # make it a vector so that lapply works below
  }
  if (missing(dims) || length(dims) == 0 || !all(vapply(dims, is_dim, logical(1)))) {
    stop("argument dims must be a list of one or more tileb_dim")
  }
  dims_ptrs <- lapply(dims, function(obj) slot(obj, "ptr"))
  ptr <- libtiledb_domain(ctx@ptr, dims_ptrs)
  return(new("tiledb_domain", ptr = ptr))
}

#' Raw display of a domain object
#'
#' This method used the display method provided by the underlying
#' library.
#'
#' @param object A domain object
#' @export
setMethod(
  "raw_dump",
  signature(object = "tiledb_domain"),
  definition = function(object) libtiledb_domain_dump(object@ptr)
)

# internal function returning text use here and in other higher-level show() methods
.as_text_domain <- function(object) {
  txt <- "tiledb_domain(c(\n"
  dims <- dimensions(object)
  nd <- length(dims)
  for (i in seq_len(nd)) {
    txt <- paste0(
      txt, "        ", .as_text_dimension(dims[[i]]),
      if (i == nd) "\n    ))" else ",\n"
    )
  }
  txt
}

#' Prints a domain object
#'
#' @param object A domain object
#' @export
setMethod(
  "show",
  "tiledb_domain",
  definition = function(object) {
    cat(.as_text_domain(object), "\n")
  }
)

#' Returns a list of the tiledb_domain dimension objects
#'
#'
#' @param object tiledb_domain
#' @return a list of tiledb_dim
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(
#'   tiledb_dim("d1", c(1L, 100L), type = "INT32"),
#'   tiledb_dim("d2", c(1L, 50L), type = "INT32")
#' ))
#' dimensions(dom)
#'
#' lapply(dimensions(dom), name)
#'
#' @export
setMethod(
  "dimensions",
  "tiledb_domain",
  function(object) {
    dim_ptrs <- libtiledb_domain_get_dimensions(object@ptr)
    return(lapply(dim_ptrs, tiledb_dim.from_ptr))
  }
)

#' Returns the tiledb_domain TileDB type string
#'
#' @param object tiledb_domain
#' @return tiledb_domain type string
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(1L, 100L), type = "INT32")))
#' datatype(dom)
#' dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(0.5, 100.0), type = "FLOAT64")))
#' datatype(dom)
#'
#' @export
setMethod(
  "datatype",
  "tiledb_domain",
  function(object) {
    ## return(libtiledb_domain_get_type(object@ptr))
    # generalize from   domaintype <- libtiledb_domain_get_type(dom@ptr)   to
    domaintype <- sapply(
      libtiledb_domain_get_dimensions(object@ptr),
      libtiledb_dim_get_datatype
    )
    return(domaintype)
  }
)

#' Returns the number of dimensions of the `tiledb_domain`
#'
#' @param object tiledb_domain
#' @return integer number of dimensions
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(0.5, 100.0), type = "FLOAT64")))
#' tiledb_ndim(dom)
#' dom <- tiledb_domain(dims = c(
#'   tiledb_dim("d1", c(0.5, 100.0), type = "FLOAT64"),
#'   tiledb_dim("d2", c(0.5, 100.0), type = "FLOAT64")
#' ))
#' tiledb_ndim(dom)
#'
#' @export
setMethod(
  "tiledb_ndim", 
  "tiledb_domain",
  function(object) {
    return(libtiledb_domain_get_ndim(object@ptr))
  }
)

#' @rdname generics
#' @export
setGeneric("is.integral", function(object) standardGeneric("is.integral"))

#' Returns TRUE is tiledb_domain is an integral (integer) domain
#'
#' @param object tiledb_domain
#' @return TRUE if the domain is an integral domain, else FALSE
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(1L, 100L), type = "INT32")))
#' is.integral(dom)
#' dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(0.5, 100.0), type = "FLOAT64")))
#' is.integral(dom)
#'
#' @export
setMethod(
  "is.integral",
  "tiledb_domain",
  function(object) {
    dtype <- datatype(object)
    res <- isTRUE(any(sapply(dtype, match, c("FLOAT32", "FLOAT32"))))
    return(!res)
  }
)

#' Retrieve the dimension (domain extent) of the domain
#'
#' Only valid for integral (integer) domains
#'
#' @param x tiledb_domain
#' @return dimension vector
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' dom <- tiledb_domain(dims = c(
#'   tiledb_dim("d1", c(1L, 100L), type = "INT32"),
#'   tiledb_dim("d2", c(1L, 100L), type = "INT32")
#' ))
#' dim(dom)
#'
#' @export
dim.tiledb_domain <- function(x) {
  dtype <- datatype(x)
  if (isTRUE(any(sapply(dtype, match, c("FLOAT32", "FLOAT64"))))) {
    stop("dim() is only defined for integral domains")
  }
  return(vapply(dimensions(x), dim, integer(1L)))
}

#' Returns a Dimension indicated by index for the given TileDB Domain
#'
#' @param domain TileDB Domain object
#' @param idx Integer index of the selected dimension
#' @return TileDB Dimension object
#' @export
tiledb_domain_get_dimension_from_index <- function(domain, idx) {
  stopifnot(
    `The 'domain' argument must be a tiledb_domain` = is(domain, "tiledb_domain"),
    `The 'idx' argument must be numeric` = is.numeric(idx)
  )
  return(new("tiledb_dim", ptr = libtiledb_domain_get_dimension_from_index(domain@ptr, idx)))
}

#' Returns a Dimension indicated by name for the given TileDB Domain
#'
#' @param domain TileDB Domain object
#' @param name A character variable with a dimension name
#' @return TileDB Dimension object
#' @export
tiledb_domain_get_dimension_from_name <- function(domain, name) {
  stopifnot(
    `The 'domain' argument must be a tiledb_domain` = is(domain, "tiledb_domain"),
    `The 'name' argument must be character` = is.character(name)
  )
  return(new("tiledb_dim", ptr = libtiledb_domain_get_dimension_from_name(domain@ptr, name)))
}

#' Check a domain for a given dimension name
#'
#' @param domain A domain of a TileDB Array schema
#' @param name A character variable with a dimension name
#' @return A boolean value indicating if the dimension exists in the domain
#' @export
tiledb_domain_has_dimension <- function(domain, name) {
  stopifnot(
    `The 'domain' argument must be a tiledb_domain` = is(domain, "tiledb_domain"),
    `The 'name' argument must be character` = is.character(name)
  )
  libtiledb_domain_has_dimension(domain@ptr, name)
}
