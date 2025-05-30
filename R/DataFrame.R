#  MIT License
#
#  Copyright (c) 2017-2024 TileDB Inc.
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


## helper functions for data frame, roughly modeled on what python has

##' Create a TileDB dense or sparse array from a given \code{data.frame} Object
##'
##' The supplied \code{data.frame} object is (currently) limited to integer,
##' numeric, or character. In addition, three datetime columns are supported
##' with the R representations of \code{Date}, \code{POSIXct} and \code{nanotime}.
##'
##' The created (dense or sparse) array will have as many attributes as there
##' are columns in the \code{data.frame}.  Each attribute will be a single column.
##' For a sparse array, one or more columns have to be designated as dimensions.
##'
##' At present, factor variable are converted to character.
##'
##' @param obj A \code{data.frame} object.
##' @param uri A character variable with an Array URI.
##' @param col_index An optional column index, either numeric with a column index,
##' or character with a column name, designating an index column; default is NULL
##' implying an index column is added when the array is created
##' @param sparse A logical switch to select sparse (the default) or dense
##' @param allows_dups A logical switch to select if duplicate values
##' are allowed or not, default is the same value as \sQuote{sparse}.
##' @param cell_order A character variable with one of the TileDB cell order values,
##' default is \dQuote{COL_MAJOR}.
##' @param tile_order A character variable with one of the TileDB tile order values,
##' default is \dQuote{COL_MAJOR}.
##' @param filter A character variable vector, defaults to \sQuote{ZSTD}, for
##' one or more filters to be applied to each attribute;
##' @param capacity A integer value with the schema capacity, default is 10000.
##' @param tile_domain An integer vector or list or \code{NULL}. If an integer vector
##' of size two it specifies the integer domain of the row dimension; if a list then a named
##' element is used for the dimension of the same name; or if \code{NULL} the row
##' dimension of the \code{obj} is used.
##' @param tile_extent An integer value for the tile extent of the row dimensions;
##' if \code{NULL} the row dimension of the \code{obj} is used. Note that the \code{tile_extent}
##' cannot exceed the tile domain.
##' @param mode A character variable with possible values \sQuote{ingest} (for schema creation and
##' data ingestion, the default behavior), \sQuote{schema_only} (to create the array schema without
##' writing to the newly-created array) and \sQuote{append} (to only append to an already existing
##' array).
##' @param filter_list A named list specifying filter choices per column, default is an empty
##' \code{list} object. This argument applies for all named arguments and the matchin dimensions
##' or attributes. The \code{filter} argument still applies for all unnamed arguments.
##' @param coords_filters A character vector with filters for coordinates, default is \code{ZSTD}.
##' @param offsets_filters A character vector with filters for coordinates, default is \code{ZSTD}.
##' @param validity_filters A character vector with filters for coordinates, default is \code{RLE}.
##' @param debug Logical flag to select additional output.
##' @param timestamps Vector with up to two \code{POSIXct} variables denoting open intervals; default
##' is length zero where start and end are set (implicitly) to current time; in case of one value it
##' is used as the interval end, and in case of two values they are taken as start and end. This
##' applies to write and append modes only and not to schema creation.
##' @return Null, invisibly.
##' @examples
##' \dontshow{ctx <- tiledb_ctx(limitTileDBCores())}
##' uri <- tempfile()
##' fromDataFrame(iris, uri)
##' arr <- tiledb_array(uri, return_as="data.frame", extended=FALSE)
##' newdf <- arr[]
##' all.equal(iris, newdf, check.attributes=FALSE)  # extra attribute on query in newdf
##' all.equal(as.matrix(iris), as.matrix(newdf))	# also strips attribute
##' @export
fromDataFrame <- function(
  obj, 
  uri, 
  col_index = NULL, 
  sparse = TRUE, 
  allows_dups = sparse,
  cell_order = "COL_MAJOR",
  tile_order = "COL_MAJOR",
  filter = "ZSTD",
  capacity = 10000L, 
  tile_domain = NULL, 
  tile_extent = NULL,
  mode = c("ingest", "schema_only", "append"),
  filter_list = NULL,
  coords_filters = "ZSTD",
  offsets_filters = "ZSTD",
  validity_filters = "RLE",
  debug = FALSE,
  timestamps = as.POSIXct(double(), origin = "1970-01-01")
) {
  stopifnot(
    "Argument 'obj' should be a 'data.frame' (or a related object)" = inherits(obj, "data.frame"),
    "Argument 'uri' should be a character variable" = is.character(uri),
    "Argument 'timestamps' must be a POSIXct vector" = inherits(timestamps, "POSIXct"),
    "Argument 'timestamps' must be 0, 1 or 2 values" = length(timestamps) %in% c(0L, 1L, 2L)
  )
  if (!is.null(col_index) && is.character(col_index)) col_index <- match(col_index, colnames(obj))
  dims <- dim(obj)
  mode <- match.arg(mode)

  if (class(obj)[1] != "data.frame") obj <- as.data.frame(obj)

  ## turn factor columns in char columns
  ## TODO: add an option
  if (tiledb_version(TRUE) < "2.17.0") {
    factcols <- grep("factor", sapply(obj, class))
    if (length(factcols) > 0) {
      for (i in factcols) obj[, i] <- as.character(obj[, i])
    }
  }

  ## Create default filter_list from filter vector, 'NONE' and 'ZSTD' is default
  default_filter_list <- tiledb_filter_list(sapply(filter, tiledb_filter))

  if (is.null(col_index)) {
    if (missing(tile_domain)) tile_domain <- c(1L, dims[1])
    if (missing(tile_extent)) tile_extent <- dims[1]

    dom <- tiledb_domain(dims = tiledb_dim(
      name = "__tiledb_rows",
      domain = tile_domain,
      tile = tile_extent,
      type = "INT32"
    ))
    useobj <- obj
  } else {
    dimobj <- obj[, col_index, drop = FALSE]
    atrobj <- obj[, -col_index, drop = FALSE]
    useobj <- cbind(dimobj, atrobj)

    if (any(is.na(dimobj))) {
      stop("Nullable columns are not supported as dimension columns.", call. = FALSE)
    }

    makeDim <- function(ind) {
      idxcol <- dimobj[, ind]
      idxnam <- colnames(dimobj)[ind]
      if (inherits(idxcol, "factor")) idxcol <- as.character(idxcol)
      col_domain <- if (is.null(tile_domain)) { # default case
        c(min(idxcol), max(idxcol)) #   use range
      } else if (is.list(tile_domain)) { # but if list
        if (idxnam %in% names(tile_domain)) { #   and name exists
          tile_domain[[idxnam]] #   use element
        } else {
          c(min(idxcol), max(idxcol)) #   else fallback
        }
      } else { # else
        tile_domain #   use non-list value
      }
      col_extent <- if (is.null(tile_extent)) dims[1] else tile_extent
      if (!inherits(idxcol, "character")) {
        dom_range <- diff(as.numeric(range(col_domain))) + 1
        col_extent <- min(dom_range, col_extent)
      }
      dtype <- "INT32" # default
      if (inherits(idxcol, "POSIXt")) {
        dtype <- "DATETIME_US"
        col_domain <- as.numeric(col_domain) * 1e6 # int64 used
      } else if (inherits(idxcol, "Date")) {
        dtype <- "DATETIME_DAY"
        col_extent <- as.numeric(col_extent) # to not trigger INT32 test
      } else if (inherits(idxcol, "numeric")) {
        dtype <- "FLOAT64"
        col_extent <- as.numeric(col_extent)
      } else if (inherits(idxcol, "nanotime")) {
        dtype <- "DATETIME_NS"
        col_domain <- c(min(idxcol) - 1e10, max(idxcol) + 1e10)
      } else if (inherits(idxcol, "integer64")) {
        dtype <- "INT64"
        col_extent <- bit64::as.integer64(col_extent)
      } else if (inherits(idxcol, "character")) {
        dtype <- "ASCII"
        col_extent <- NULL
        col_domain <- c(NULL, NULL)
      } else if (dtype == "INT32") {
        col_extent <- as.integer(col_extent)
      }

      if (debug) {
        cat(sprintf(
          "Setting domain name %s type %s domain (%s,%s) extent %s\n", idxnam, dtype,
          ifelse(is.null(col_domain[1]), "null", format(col_domain[1])),
          ifelse(is.null(col_domain[2]), "null", format(col_domain[2])),
          ifelse(is.null(col_extent), "null", format(col_extent))
        ))
      }

      d <- tiledb_dim(
        name = idxnam,
        domain = col_domain,
        tile = col_extent,
        type = dtype
      )

      if (idxnam %in% names(filter_list)) {
        filter_list(d) <- tiledb_filter_list(sapply(filter_list[[idxnam]], tiledb_filter))
      }

      d
    }
    dimensions <- sapply(seq_len(ncol(dimobj)), makeDim)

    dom <- tiledb_domain(dims = dimensions)
  }

  ## the simple helper function used create attribute_i given index i
  ## we now make it a little bit more powerful yet clumsy but returning a
  ## three element list at each element where the list contains the attribute
  ## along with the optional factor levels vector (and the corresponding column name)
  makeAttr <- function(ind) {
    col <- obj[, ind]
    colname <- colnames(obj)[ind]
    lvls <- NULL # by default no factor levels
    ordrd <- FALSE
    if (inherits(col, "AsIs")) {
      ## we just look at the first list column, others have to have same type and length
      cl <- class(obj[, ind][[1]])
      nc <- length(obj[, ind][[1]])
    } else {
      cl <- class(col)[1]
      nc <- 1
    }
    if (cl == "integer") {
      tp <- "INT32"
    } else if (cl == "numeric") {
      tp <- "FLOAT64"
    } else if (cl == "character") {
      tp <- "ASCII"
    } else if (cl == "Date") {
      tp <- "DATETIME_DAY"
    } else if (cl == "POSIXct" || cl == "POSIXlt") {
      tp <- "DATETIME_MS"
    } else if (cl == "nanotime") {
      tp <- "DATETIME_NS"
    } else if (cl == "integer64") {
      tp <- "INT64"
    } else if (cl == "logical") {
      tp <- if (tiledb_version(TRUE) >= "2.10.0") "BOOL" else "INT32"
    } else if (cl == "factor" || cl == "ordered") {
      lvls <- levels(col) # extract factor levels
      if (length(lvls) > .Machine$integer.max) {
        stop("Cannot represent this many levels for ", colname, call. = FALSE)
      }
      attr(lvls, "ordered") <- cl == "ordered"
      tp <- "INT32"
    } else {
      stop("Currently unsupported type: ", cl)
    }

    filters <- if (colname %in% names(filter_list)) {
      tiledb_filter_list(sapply(filter_list[[colname]], tiledb_filter))
    } else {
      default_filter_list
    }
    if (debug) {
      cat(sprintf("Setting attribute name %s type %s\n", colname, tp))
    }
    attr <- tiledb_attr(colname,
      type = tp,
      ncells = if (tp %in% c("CHAR", "ASCII")) NA_integer_ else nc,
      filter_list = filters,
      nullable = any(is.na(col)),
      enumeration = lvls
    )
    list(attr = attr, lvls = lvls, name = colname) # return a list of three with levels and names
  }
  cols <- seq_len(dims[2])
  if (!is.null(col_index)) cols <- cols[-col_index]
  attributes <- enumerations <- list() # fallback
  if (length(cols) > 0) {
    a_e <- lapply(cols, makeAttr)
    attributes <- lapply(a_e, "[[", 1) # get attributes from list
    enumerations <- lapply(a_e, "[[", 2) # get enumeration levels (with 'ordered' attribute)
    colnames <- lapply(a_e, "[[", 3) # get column names
    names(enumerations) <- colnames
  }
  schema <- tiledb_array_schema(dom,
    attrs = attributes,
    cell_order = cell_order,
    tile_order = tile_order,
    sparse = sparse,
    coords_filter_list = tiledb_filter_list(sapply(coords_filters, tiledb_filter)),
    offsets_filter_list = tiledb_filter_list(sapply(offsets_filters, tiledb_filter)),
    validity_filter_list = tiledb_filter_list(sapply(validity_filters, tiledb_filter)),
    capacity = capacity,
    enumerations = if (length(enumerations) > 0) enumerations else NULL
  )
  allows_dups(schema) <- allows_dups

  if (mode != "append") {
    tiledb_array_create(uri, schema)
  }

  if (mode != "schema_only") {
    df <- switch(length(timestamps) + 1, # switch takes ints starting at one
      tiledb_array(uri, query_type = "WRITE"),
      tiledb_array(uri, query_type = "WRITE", timestamp_end = timestamps[1]),
      tiledb_array(uri, query_type = "WRITE", timestamp_start = timestamps[1], timestamp_end = timestamps[2])
    )
    ## when setting an index when likely want 'sparse write to dense array
    if (!is.null(col_index) && !sparse) {
      query_layout(df) <- "UNORDERED"
    }
    if (is.null(col_index) && sparse) {
      useobj <- cbind(data.frame(`__tiledb_rows` = seq(1, dims[1]), check.names = FALSE), useobj)
    }
    df[] <- useobj
  }
  invisible(NULL)
}

.testFromDataFrame <- function(obj, uri) {
  if (dir.exists(uri)) unlink(uri, recursive = TRUE)
  fromDataFrame(obj, uri)

  df <- tiledb_array(uri, return_as = "data.frame")
  df[]
}

.testWithDate <- function(df, uri) {
  bkdf <- within(df, {
    Closing.Date <- as.Date(Closing.Date, "%d-%b-%y")
    Updated.Date <- as.Date(Updated.Date, "%d-%b-%y")
  })

  fromDataFrame(bkdf, uri)
}

.testWithDatetime <- function(df, uri) {
  ## one example data set can be created / read via
  ##   banklist <- read.csv("~/git/tiledb-data/csv-pandas/banklist.csv", stringsAsFactors = FALSE)
  ## pprovided one has those files
  bkdf <- within(df, {
    Closing.Date <- as.POSIXct(as.Date(Closing.Date, "%d-%b-%y"))
    Updated.Date <- as.POSIXct(as.Date(Updated.Date, "%d-%b-%y"))
  })
  if (dir.exists(uri)) {
    message("Removing existing directory ", uri)
    unlink(uri, recursive = TRUE)
  }
  fromDataFrame(bkdf, uri)

  arr <- tiledb_array(uri, return_as = "data.frame")
  newdf <- arr[]
  invisible(newdf)
}

.testWithNanotime <- function(df, uri) {
  if (dir.exists(uri)) {
    message("Removing existing directory ", uri)
    unlink(uri, recursive = TRUE)
  }
  fromDataFrame(df, uri)
  cat("Data written\n")

  arr <- tiledb_array(uri, return_as = "data.frame")
  newdf <- arr[]
  invisible(newdf)
}
