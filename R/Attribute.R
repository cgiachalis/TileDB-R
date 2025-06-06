#  MIT License
#
#  Copyright (c) 2017-2023 TileDB Inc.
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

#' An S4 class for a TileDB attribute
#'
#' @slot ptr External pointer to the underlying implementation
#' @exportClass tiledb_attr
setClass("tiledb_attr",
  slots = list(ptr = "externalptr")
)

tiledb_attr.from_ptr <- function(ptr) {
  stopifnot(
    `The 'ptr' argument must be a non-NULL external pointer to an Attribute instance` =
      !missing(ptr) && is(ptr, "externalptr") && !is.null(ptr)
  )
  new("tiledb_attr", ptr = ptr)
}

#' Constructs a `tiledb_attr` object
#'
#' @param name The dimension name / label string; if missing default `""` is used.
#' @param type The tiledb_attr TileDB datatype string; if missing the user is alerted
#' that this is a _required_ parameter.
#' @param filter_list (default filter_list("NONE")) An optional tiledb_filter_list object
#' @param ncells (default 1) The number of cells, use \code{NA} to signal variable length
#' @param nullable (default FALSE) A logical switch whether the attribute can have missing
#' values
#' @param enumeration (default NULL) A character vector of dictionary values
#' @param ctx tiledb_ctx object (optional)
#' @return A `tiledb_attr` object
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' flt <- tiledb_filter_list(list(tiledb_filter("GZIP")))
#' attr <- tiledb_attr(
#'   name = "a1", type = "INT32",
#'   filter_list = flt
#' )
#' attr
#'
#' @importFrom methods new
#' @export
tiledb_attr <- function(
  name,
  type,
  filter_list = tiledb_filter_list(),
  ncells = 1,
  nullable = FALSE,
  enumeration = NULL,
  ctx = tiledb_get_context()
) {
  if (missing(name)) name <- ""
  if (is.na(ncells)) ncells <- NA_integer_ # the specific NA for ints (as basic NA is bool)
  stopifnot(
    "The 'name' argument must be a scalar string" = is.scalar(name, "character"),
    "The 'type' argument is mandatory" = !missing(type),
    "The 'ncells' argument must be numeric or NA" = is.numeric(ncells) || is.na(ncells),
    "The 'filter_list' argument must be a tiledb_filter_list instance" =
      is(filter_list, "tiledb_filter_list"),
    "The 'ctx' argument must be a tiledb_ctx" = is(ctx, "tiledb_ctx")
  )
  ptr <- libtiledb_attribute(ctx@ptr, name, type, filter_list@ptr, ncells, nullable)
  attr <- new("tiledb_attr", ptr = ptr)
  if (!is.null(enumeration)) {
    attr <- tiledb_attribute_set_enumeration_name(attr, name, ctx)
  }
  return(attr)
}

#' Raw display of an attribute object
#'
#' This method used the display method provided by the underlying
#' library.
#'
#' @param object An attribute object
#' @export
setMethod("raw_dump",
  signature(object = "tiledb_attr"),
  definition = function(object) libtiledb_attribute_dump(object@ptr)
)

# internal function returning text use here and in other higher-level show() methods
.as_text_attribute <- function(object, arrptr = NULL) {
  fl <- filter_list(object)
  ndct <- 0 # default
  dct <- character() # default
  ord <- FALSE # default
  if (!is.null(arrptr)) {
    if (!libtiledb_array_is_open_for_reading(arrptr)) arrptr <- libtiledb_array_open_with_ptr(arrptr, "READ")
    if (tiledb_attribute_has_enumeration(object)) {
      dct <- tiledb_attribute_get_enumeration_ptr(object, arrptr)
      ord <- tiledb_attribute_is_ordered_enumeration_ptr(object, arrptr)
      ndct <- length(dct)
    }
  }
  dictionary_txt <- if (ord) "ordered_dictionary" else "dictionary"
  txt <- paste0(
    "tiledb_attr(name=\"", name(object), "\", ",
    "type=\"", datatype(object), "\", ",
    "ncells=", cell_val_num(object), ", ",
    "nullable=", tiledb_attribute_get_nullable(object),
    if (nfilters(fl) > 0) paste0(", filter_list=", .as_text_filter_list(fl)),
    if (ndct > 0) paste0(", ", dictionary_txt, "=c(\"", paste(dct[seq(1, min(5, ndct))], collapse = "\",\""), if (ndct > 5) "\",...", "\")")
  )
  txt <- paste0(txt, ")")
  txt
}

#' Prints an attribute object
#'
#' @param object An attribute object
#' @export
setMethod("show",
  signature(object = "tiledb_attr"),
  definition = function(object) {
    cat(.as_text_attribute(object), "\n")
  }
)


#' @rdname generics
#' @export
setGeneric("name", function(object) standardGeneric("name"))

#' Return the `tiledb_attr` name
#'
#' @param object `tiledb_attr` object
#' @return string name, empty string if the attribute is anonymous
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' a1 <- tiledb_attr("a1", type = "INT32")
#' name(a1)
#'
#' a2 <- tiledb_attr(type = "INT32")
#' name(a2)
#'
#' @export
setMethod(
  "name", signature(object = "tiledb_attr"),
  function(object) {
    libtiledb_attribute_get_name(object@ptr)
  }
)

#' @rdname generics
#' @export
setGeneric("datatype", function(object) standardGeneric("datatype"))

#' Return the `tiledb_attr` datatype
#'
#' @param object `tiledb_attr` object
#' @return tiledb datatype string
#' @examples
#' a1 <- tiledb_attr("a1", type = "INT32")
#' datatype(a1)
#'
#' a2 <- tiledb_attr("a1", type = "FLOAT64")
#' datatype(a2)
#'
#' @export
setMethod(
  "datatype", signature(object = "tiledb_attr"),
  function(object) {
    libtiledb_attribute_get_type(object@ptr)
  }
)

## Generic in ArraySchema.R

#' Returns the TileDB Filter List object associated with the given TileDB Attribute
#'
#' @param object TileDB Attribute
#' @return a tiledb_filter_list object
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' attr <- tiledb_attr(
#'   type = "INT32",
#'   filter_list = tiledb_filter_list(list(tiledb_filter("ZSTD")))
#' )
#' filter_list(attr)
#'
#' @export
setMethod("filter_list", "tiledb_attr", function(object) {
  ptr <- libtiledb_attribute_get_filter_list(object@ptr)
  return(tiledb_filter_list.from_ptr(ptr))
})

## Generic in ArraySchema.R

#' Sets the TileDB Filter List for the TileDB Attribute object
#'
#' @param x TileDB Attribute
#' @param value TileDB Filter List
#' @return The modified TileDB Attribute object
#' @export
setReplaceMethod("filter_list", "tiledb_attr", function(x, value) {
  x@ptr <- libtiledb_attribute_set_filter_list(x@ptr, value@ptr)
  x
})


#' @rdname tiledb_attribute_get_cell_val_num
#' @export
setGeneric("cell_val_num", function(object) standardGeneric("cell_val_num"))

#' @rdname tiledb_attribute_get_cell_val_num
#' @export
setMethod(
  "cell_val_num",
  signature(object = "tiledb_attr"),
  definition = function(object) {
    libtiledb_attribute_get_cell_val_num(object@ptr)
  }
)

#' Return the number of scalar values per attribute cell
#'
#' @param object `tiledb_attr` object
#' @return integer number of cells
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' a1 <- tiledb_attr("a1", type = "FLOAT64", ncells = 1)
#' cell_val_num(a1)
#' @export
tiledb_attribute_get_cell_val_num <- function(object) {
  libtiledb_attribute_get_cell_val_num(object@ptr)
}



#' @rdname tiledb_attribute_set_cell_val_num
#' @export
setGeneric("cell_val_num<-", function(x, value) standardGeneric("cell_val_num<-"))

#' @rdname tiledb_attribute_set_cell_val_num
#' @export
setReplaceMethod(
  "cell_val_num",
  signature("tiledb_attr"),
  function(x, value) {
    libtiledb_attribute_set_cell_val_num(x@ptr, value)
    x
  }
)

#' Set the number of scalar values per attribute cell
#'
#' @param x A TileDB Attribute object
#' @param value An integer value of number of cells
#' @return The modified attribute is returned
#' @export
tiledb_attribute_set_cell_val_num <- function(x, value) {
  libtiledb_attribute_set_cell_val_num(x@ptr, value)
}


#' Returns TRUE if the tiledb_dim is anonymous
#'
#' A TileDB attribute is anonymous if no name/label is defined
#'
#' @param object `tiledb_attr` object
#' @return TRUE or FALSE
#' @examples
#' \dontshow{
#' ctx <- tiledb_ctx(limitTileDBCores())
#' }
#' a1 <- tiledb_attr("a1", type = "FLOAT64")
#' is.anonymous(a1)
#'
#' a2 <- tiledb_attr("", type = "FLOAT64")
#' is.anonymous(a2)
#'
#' @export
is.anonymous <- function(object) UseMethod("is.anonymous", object)

#' @rdname is.anonymous
#' @export
is.anonymous.tiledb_attr <- function(object) {
  name <- libtiledb_attribute_get_name(object@ptr)
  nchar(name) == 0
}


#' Get the fill value for a TileDB Attribute
#'
#' @param attr A TileDB Attribute object
#' @return The fill value for the attribute
#' @export
tiledb_attribute_get_fill_value <- function(attr) {
  stopifnot(attr_object = is(attr, "tiledb_attr"))
  libtiledb_attribute_get_fill_value(attr@ptr)
}

#' Set the fill value for a TileDB Attribute
#'
#' @param attr A TileDB Attribute object
#' @param value A fill value
#' @return \code{NULL} is returned invisibly
#' @export
tiledb_attribute_set_fill_value <- function(attr, value) {
  stopifnot(
    `The first argument must be an attribute` = is(attr, "tiledb_attr"),
    `The second argument must be int, numeric or char` = is.integer(value) || is.numeric(value) || is.character(value)
  )
  libtiledb_attribute_set_fill_value(attr@ptr, value)
  invisible()
}

#' Check whether TileDB Attribute is variable-sized
#'
#' @param attr A TileDB Attribute object
#' @return A boolean value indicating variable-size or not
#' @export
tiledb_attribute_is_variable_sized <- function(attr) {
  stopifnot(`The argument must be an attribute` = is(attr, "tiledb_attr"))
  libtiledb_attribute_is_variable_sized(attr@ptr)
}

#' Get the TileDB Attribute cell size
#'
#' @param attr A TileDB Attribute object
#' @return A numeric value with the cell size
#' @export
tiledb_attribute_get_cell_size <- function(attr) {
  stopifnot(`The argument must be an attribute` = is(attr, "tiledb_attr"))
  libtiledb_attribute_get_cell_size(attr@ptr)
}

#' Set the TileDB Attribute Nullable flags
#'
#' @param attr A TileDB Attribute object
#' @param flag A boolean flag to turn \sQuote{Nullable} on or off
#' @return Nothing is returned
#' @export
tiledb_attribute_set_nullable <- function(attr, flag) {
  stopifnot(
    `The first argument must be an attribute` = is(attr, "tiledb_attr"),
    `The second argument must be a logical` = is.logical(flag) && !is.na(flag)
  )
  libtiledb_attribute_set_nullable(attr@ptr, flag)
}

#' Get the TileDB Attribute Nullable flag value
#'
#' @param attr A TileDB Attribute object
#' @return A boolean value with the \sQuote{Nullable} status
#' @export
tiledb_attribute_get_nullable <- function(attr) {
  stopifnot(`The argument must be an attribute` = is(attr, "tiledb_attr"))
  libtiledb_attribute_get_nullable(attr@ptr)
}

#' Test if TileDB Attribute has an Enumeration
#'
#' @param attr A TileDB Attribute object
#' @param ctx A Tiledb Context object (optional)
#' @return A logical value indicating if the attribute has an enumeration
#' @export
tiledb_attribute_has_enumeration <- function(
  attr,
  ctx = tiledb_get_context()
) {
  stopifnot("The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"))
  libtiledb_attribute_has_enumeration(ctx@ptr, attr@ptr)
}

#' Get the TileDB Attribute Enumeration
#'
#' @param attr A TileDB Attribute object
#' @param arr A Tiledb Array object
#' @param ctx A Tiledb Context object (optional)
#' @return A character vector with the enumeration (of length zero if none)
#' @export
tiledb_attribute_get_enumeration <- function(
  attr,
  arr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arr' argument must be an array" = is(arr, "tiledb_array")
  )
  libtiledb_attribute_get_enumeration(ctx@ptr, attr@ptr, arr@ptr)
}

#' @rdname tiledb_attribute_get_enumeration
#' @param arrptr A Tiledb Array object pointer
#' @export
tiledb_attribute_get_enumeration_ptr <- function(
  attr,
  arrptr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arrptr' argument must be an external pointer" = is(arrptr, "externalptr")
  )
  libtiledb_attribute_get_enumeration(ctx@ptr, attr@ptr, arrptr)
}

#' Set a TileDB Attribute Enumeration Name
#'
#' @param attr A TileDB Attribute object
#' @param enum_name A character value with the enumeration value
#' @param ctx A Tiledb Context object (optional)
#' @return The modified TileDB Attribute object
#' @export
tiledb_attribute_set_enumeration_name <- function(
  attr,
  enum_name,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'enum_name' argument must be character" = is.character(enum_name)
  )
  attr@ptr <- libtiledb_attribute_set_enumeration(ctx@ptr, attr@ptr, enum_name)
  attr
}

#' Check if TileDB Attribute Enumeration is Ordered
#'
#' @param attr A Tiledb Array object
#' @param arrptr A Tiledb Array object pointer
#' @param ctx A Tiledb Context object (optional)
#' @return A character vector with the enumeration (of length zero if none)
#' @export
tiledb_attribute_is_ordered_enumeration_ptr <- function(
  attr,
  arrptr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arrptr' argument must be an external pointer" = is(arrptr, "externalptr")
  )
  libtiledb_attribute_is_ordered_enumeration(ctx@ptr, attr@ptr, arrptr)
}

# internal function to access enumeration data type
#' @noRd
tiledb_attribute_get_enumeration_type <- function(
  attr,
  arr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arr' argument must be an array" = is(arr, "tiledb_array")
  )
  libtiledb_attribute_get_enumeration_type(ctx@ptr, attr@ptr, arr@ptr)
}

# internal function to access enumeration data type
#' @noRd
tiledb_attribute_get_enumeration_type_ptr <- function(
  attr,
  arrptr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arrptr' argument must be an external pointer" = is(arrptr, "externalptr")
  )
  libtiledb_attribute_get_enumeration_type(ctx@ptr, attr@ptr, arrptr)
}

# internal function to get (non-string) enumeration vector
#' @noRd
tiledb_attribute_get_enumeration_vector_ptr <- function(
  attr,
  arrptr,
  ctx = tiledb_get_context()
) {
  stopifnot(
    "The 'attr' argument must be an attribute" = is(attr, "tiledb_attr"),
    "The 'arrptr' argument must be an external pointer" = is(arrptr, "externalptr")
  )
  libtiledb_attribute_get_enumeration_vector(ctx@ptr, attr@ptr, arrptr)
}
