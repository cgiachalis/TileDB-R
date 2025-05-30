<!--
%\VignetteIndexEntry{TileDB API Documentation}
%\VignetteEngine{simplermarkdown::mdweave_to_html}
%\VignetteEncoding{UTF-8}
-->
---
title: "TileDB API Documentation"
css: "water.css"
---

This document follows the [TileDB API usage examples](https://docs.tiledb.com/main/how-to).
A shorter [introductory vignette](introduction.html) is also available.

# Prelimaries

We will show two initial and basic examples for a dense and sparse array simply to create
array data on disk to refer to later in examples that follow.

```r
library(tiledb)

tdir <- tempdir()
uridense <- file.path(tdir, "dense")
uridensefix <- file.path(tdir, "densefix")
uridensevar <- file.path(tdir, "densevar")
uridensewkey <- file.path(tdir, "denseenc")

create_array <- function(array_name) {
    # Check if the array already exists.
    if (tiledb_object_type(array_name) == "ARRAY") {
        message("Array already exists.")
        return(invisible(NULL))
    }

    # The array will be 4x4 with dimensions "rows" and "cols", with domain [1,4].
    dom <- tiledb_domain(dims = c(tiledb_dim("rows", c(1L, 4L), 4L, "INT32"),
                                  tiledb_dim("cols", c(1L, 4L), 4L, "INT32")))

    # The array will be dense with a single attribute "a" so each (i,j) cell can store an integer.
    schema <- tiledb_array_schema(dom, attrs = tiledb_attr("a", type = "INT32"))

    # Create the (empty) array on disk, and return the path invisibly
    invisible(tiledb_array_create(array_name, schema))
}

write_array <- function(array_name) {
    data <- array(c(c(1L, 5L, 9L, 13L),
                    c(2L, 6L, 10L, 14L),
                    c(3L, 7L, 11L, 15L),
                    c(4L, 8L, 12L, 16L)), dim = c(4,4))
    # Open the array and write to it.
    A <- tiledb_array(uri = array_name)
    A[] <- data
}

create_array(uridense)
write_array(uridense)


urisparse <- file.path(tdir, "sparse")

create_array <- function(array_name) {
    # Check if the array already exists.
    if (tiledb_object_type(array_name) == "ARRAY") {
        message("Array already exists.")
        return(invisible(NULL))
    }

    # The array will be 4x4 with dimensions "rows" and "cols", with domain [1,4].
    dom <- tiledb_domain(dims = c(tiledb_dim("rows", c(1L, 4L), 4L, "INT32"),
                                  tiledb_dim("cols", c(1L, 4L), 4L, "INT32")))

    # The array will be dense with a single attribute "a" so each (i,j) cell can store an integer.
    schema = tiledb_array_schema(dom, attrs=tiledb_attr("a", type = "INT32"), sparse = TRUE)

    # Create the (empty) array on disk, and return the path invisibly.
    invisible(tiledb_array_create(array_name, schema))
}

write_array <- function(array_name) {
    I <- c(1, 2, 2)
    J <- c(1, 4, 3)
    data <- c(1L, 2L, 3L)
    # Open the array and write to it.
    A <- tiledb_array(uri = array_name)
    A[I, J] <- data
}

create_array(urisparse)
write_array(urisparse)

close_and_reopen <- function(arr, txt) {
  res <- tiledb:::libtiledb_array_close(arr@ptr)
  res <- tiledb:::libtiledb_array_open_with_ptr(arr@ptr, txt)
}
```

# API Usage

## Creating Arrays

### Creating Dimensions

```r
library(tiledb)

# Create dimension
dim <- tiledb_dim("dim1", c(1L, 4L), 2L, "INT32")

# String dimenions: no values for domain and extent
strdim <- tiledb_dim("dim2", NULL, NULL, "ASCII")
```



### Creating the Array Domain

```r
library(tiledb)

#  .. create dimensions `dim1`, `dim2`
dim1 <- tiledb_dim("dim1", c(1L, 4L), 2L, "INT32")
dim2 <- tiledb_dim("dim2", c(1L, 2L), 2L, "INT32")

# Create domain with two dimensions
# In C++: domain.add_dimensions(dim1).add_dimension(dim2)
dom <- tiledb_domain(dims = c(dim1, dim2))
```

### Creating Attributes

```r
# Create attribute
attr <- tiledb_attr("attr", type = "INT32")

# Create attribute
attr <- tiledb_attr("a1", type = "INT32")

# Access cell value via generic or functions
cell_val_num(attr)
tiledb_attribute_get_cell_val_num(attr)

## Attribute value counts can be set via a generic method and a direct method
cell_val_num(attr) <- 3
tiledb_attribute_set_cell_val_num(attr, 3)

## set char attribute to variable length which is encoded as a NA
cell_val_num(attr) <- NA
tiledb_attribute_set_cell_val_num(attr, NA)
```

#### Setting Fill Values

```r
# ... create int attribute attr
attr <- tiledb_attr("a1", type = "INT32")
# set fill value to 42L
tiledb_attribute_set_fill_value(attr, 42L)

# ... create variable-sized attributte attr
attr <- tiledb_attr("attr", type = "CHAR")
tiledb_attribute_set_cell_val_num(attr, 3)
# set fill value to "..."
tiledb_attribute_set_fill_value(attr, "...")
```

#### Setting a Compressor

```r
comp <- tiledb_filter("GZIP")
tiledb_filter_set_option(comp,"COMPRESSION_LEVEL", 10)

# Create a filter list with the compressor
filter_list <- tiledb_filter_list(comp)

# Create attribute with the filter list
attr <- tiledb_attr("attr", "INT32", filter_list = filter_list)
```


#### Setting Other Filters

```r
# Create filters
f1 <- tiledb_filter("BIT_WIDTH_REDUCTION")
f2 <- tiledb_filter("ZSTD")

# Create a filter list with the two filters
filter_list <- tiledb_filter_list(c(f1,f2))

# Create attribute with the filter list
attr <- tiledb_attr("attr", "INT32", filter_list = filter_list)
```

### Creating the Array Schema

```r
# ... create domain dom
attr1 <- tiledb_attr("attr1", "INT32", filter_list = filter_list)
attr2 <- tiledb_attr("attr2", "FLOAT64", filter_list = filter_list)

# Create a dense array
schema <- tiledb_array_schema(dom, c(attr1, attr2), sparse = FALSE)
# Or, create a sparse array
# schema <- tiledb_array_schema(dom, c(attr1, attr2), sparse = TRUE)
```

#### Setting the Tile and Cell Order

```r
# ... create domain dom
# ... create attributes attr1, attr2

# The tile and order can be "COL_MAJOR" or "ROW_MAJOR"
schema <- tiledb_array_schema(dom, c(attr1, attr2),
                              cell_order = "COL_MAJOR",
                              tile_order = "COL_MAJOR")
```

#### Setting the Data Tile Capacity

```r
# set capacity
capacity(schema) <- 100000
tiledb_array_schema_set_capacity(schema, 10000)

# get capacity
capacity(schema)
tiledb_array_schema_get_capacity(schema)

```

#### Allowing Duplicates

```r
sch <- schema(urisparse)

# get 'duplicates allowed?' status
allows_dups(sch)
tiledb_array_schema_get_allows_dups(sch)

# set 'duplicates allowed?' status
allows_dups(sch) <- TRUE
tiledb_array_schema_set_allows_dups(sch, TRUE)
```

#### Checking Correctness

```r
check(sch)
tiledb_array_schema_check(sch)
```

### Setting Filters

#### Creating a Filter List

```r
# create a "GZIP" compression filter
flt <- tiledb_filter("GZIP")
# set the option 'COMPRESSION_LEVEL' to 10
tiledb_filter_set_option(flt, "COMPRESSION_LEVEL", 10)

# create a filter list with this filter
fltlst <- tiledb_filter_list(flt)
```

#### Other Filters

```r
# create a filter list object with both
fltlst <- tiledb_filter_list(c(flt1, flt2))
```

#### Setting the Tile Chunk Size

```r
# ... create filter list
set_max_chunk_size(filter_list, 10000)
tiledb_filter_list_set_max_chunk_size(filter_list, 10000)

max_chunk_size(filter_list)
tiledb_filter_list_get_max_chunk_size(filter_list)
```

#### Setting a Filter List for an Attribute

```r
# create (or access) an attribute
attr <- tiledb_attr("a", "INT32")

# create a filter list
flt1 <- tiledb_filter("BIT_WIDTH_REDUCTION")
flt2 <- tiledb_filter("ZSTD")
fltlst <- tiledb_filter_list(c(flt1, flt2))

# set the filter list
filter_list(attr) <- fltlst
```

#### Setting a Filter List for a Dimension

```r
d <- tiledb_dim("d", c(1L, 10L), 1L, "INT32")

# create a filter list
flt1 <- tiledb_filter("BIT_WIDTH_REDUCTION")
flt2 <- tiledb_filter("ZSTD")
fltlst <- tiledb_filter_list(c(flt1, flt2))

# assign the filter list
filter_list(d) <- fltlst
```

#### Setting a Filter List for All Dimensions

```r
# ... create (or retrieve) array schema sch
# ... create filter list fl

# assign filter list to schema
tiledb_array_schema_set_coords_filter_list(sch, fl)

# Alternatively create the schema and set the coordinates filter list
sch <- tiledb_array_schema(dom, c(attr1, attr2), coords_filter_list = fl)
```

#### Setting a Filter List for Variable-Sized Value Offsets

```r
# ... create (or retrieve) array schema sch
# ... create filter list fl

# assign filter list to schema
tiledb_array_schema_set_offsets_filter_list(sch, fl)

# Create the schema setting the offsets filter list
sch <- tiledb_array_schema(dom, c(attr1, attr2), offsets_filter_list = fl)
```

#### Setting Coordinate and Offset Filters

```r
# ... create domain dom
# ... create attributes attr1, attr2
# ... create filter lists fl1, fl2, similar to attributes
f1 <- tiledb_filter("BIT_WIDTH_REDUCTION")
f2 <- tiledb_filter("ZSTD")
fl1 <- tiledb_filter_list(c(f1))
fl2 <- tiledb_filter_list(c(f2))

# Create the schema setting the coordinates and offsets filter lists
schema <- tiledb_array_schema(dom, c(attr1, attr2),
                              coords_filter_list = fl1,
                              offsets_filter_list = fl2)
```


### Creating the Array

```r
# ... create array schema

# Create the array
tiledb_array_create(uridense, schema)
```

### Creating Encrypted Arrays

```r
# assume previously created schema 'sch'
# use encryption key
encryption_key <- "0123456789abcdeF0123456789abcdeF"

# create encrypted array at 'uri' with schema 'sch'
tiledb_array_create(uridensewkey, sch, encryption_key)
```

## Writing Arrays

### Writing in Dense Subarrays

```r
## prepare a larger 5 x 5 to embed into
tmp <- tempfile()
d1  <- tiledb_dim("d1", domain = c(1L, 5L))
d2  <- tiledb_dim("d2", domain = c(1L, 5L))
dom <- tiledb_domain(c(d1, d2))
val <- tiledb_attr(name="val", type = "INT32")
sch <- tiledb_array_schema(dom, c(val))
tiledb_array_create(tmp, sch)

dat <- matrix(as.integer(rnorm(25)*100), 5, 5)
arr <- tiledb_array(tmp, return_as = "data.frame")
arr[] <- dat


# Prepare a 2x3 dense array
# Contrary to Python, R by default stores arrays in col-major order
data <-  array(c(1L, 4L, 2L, 5L, 3L, 6L), dim=c(2,3))

# Prepare the [1,2] x [2,4] subarray to write to
I <- c(1:2)
J <- c(2:4)

# Open the array and write the data to it
A <- tiledb_dense(uri = tmp)
A[I, J] <- data

unlink(tmp, recursive=TRUE)
```

#### Basic Writing using Low-Level Code

```r
ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridense, "WRITE")

## data: simple (integer sequence) of 1:16 times 10
vec <- 1:16 * 10L
subarr <- c(1L,4L, 1L,4L)

qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "WRITE")
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")
qryptr <- tiledb:::libtiledb_query_set_buffer(qryptr, "a", vec)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
res <- tiledb:::libtiledb_array_close(arrptr)
```


### Writing Sparse Cells

```r
tmp <- urisparse
unlink(tmp, recursive=TRUE)

d1  <- tiledb_dim("d1", domain = c(1L, 5L))
d2  <- tiledb_dim("d2", domain = c(1L, 5L))
dom <- tiledb_domain(c(d1, d2))
val <- tiledb_attr("val", type = "INT32")
sch <- tiledb_array_schema(dom, val, sparse=TRUE)
tiledb_array_create(tmp, sch)


# Prepare some data
data <- c(3L, 4L, 1L, 2L)

I <- c(3, 4, 1, 2)
J <- c(3, 4, 2, 1)

# Open the array and write the data to it
A <- tiledb_array(uri = tmp)
A[I, J] <- data
```

### Writing Encrypted Arrays

```r
# open for writing with corresponding encryption key
A <- tiledb_array(uridensewkey, encryption_key = encryption_key)
# access array as usual
```


### Fixed-length Attributes

```r
if (dir.exists(uridensefix)) unlink(uridensefix, recursive=TRUE)
d1  <- tiledb_dim("d1", domain = c(1L, 4L))
d2  <- tiledb_dim("d2", domain = c(1L, 4L))
dom <- tiledb_domain(c(d1, d2))

vec <- 1:32 * 10L
attr <- tiledb_attr("a", type = r_to_tiledb_type(vec))

## set to two values per cell
tiledb:::libtiledb_attribute_set_cell_val_num(attr@ptr, 2)
sch <- tiledb_array_schema(dom, attr)
tiledb_array_create(uridensefix, sch)

ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridensefix, "WRITE")
subarr <- c(1L,4L, 1L,4L)

qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "WRITE")
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")
qryptr <- tiledb:::libtiledb_query_set_buffer(qryptr, "a", vec)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
res <- tiledb:::libtiledb_array_close(arrptr)

#TODO Higher-level R support
```

### Var-length Attributes

```r
if (dir.exists(uridensevar)) unlink(uridensevar, recursive=TRUE)
## Define array
## The array will be 4x4 with dimensions "rows" and "cols", with domain [1,4].
dom <- tiledb_domain(dims = c(tiledb_dim("rows", c(1L, 4L), 4L, "INT32"),
                              tiledb_dim("cols", c(1L, 4L), 4L, "INT32")))


attr <- tiledb_attr("a1", type = "CHAR")
## set to variable length
tiledb:::libtiledb_attribute_set_cell_val_num(attr@ptr, NA)

## now set the schema
ctx <- tiledb_ctx()
schptr <- tiledb:::libtiledb_array_schema_create(ctx@ptr, "DENSE")
tiledb:::libtiledb_array_schema_set_domain(schptr, dom@ptr)
tiledb:::libtiledb_array_schema_set_cell_order(schptr, "COL_MAJOR")
tiledb:::libtiledb_array_schema_set_tile_order(schptr, "COL_MAJOR")
tiledb:::libtiledb_array_schema_add_attribute(schptr, attr@ptr)



## Create the (empty) array on disk.
tiledb:::libtiledb_array_create(uridensevar, schptr)

data <- "abbcccddeeefghhhijjjkklmnoop";
offsets <- c(0L, 1L, 3L, 6L, 8L, 11L, 12L, 13L, 16L, 17L, 20L, 22L, 23L, 24L, 25L, 27L)

ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridensevar, "WRITE")
qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "WRITE")
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")

bufptr <- tiledb:::libtiledb_query_buffer_var_char_create(offsets, data)
qryptr <- tiledb:::libtiledb_query_set_buffer_var_char(qryptr, "a1", bufptr)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
tiledb:::libtiledb_array_close(arrptr)

#TODO Higher-level R support
```

### Writing at a Timestamp

```r
# 'at' uses Sys.time() from R in seconds, and shifts back 10 minutes
at <- Sys.time() - 10*60

# 'arr' is an already created array, could also be encrypted and carry key
arr <- tiledb_array_open_at(arr, "WRITE", Sys.time() - 600)

# arr is now open for writing, any suitable content can be written the usual way
```


### Getting the Fragment Info

```r
# continuing from previous example on dense variable length array
# (but this works of course with any array after a write is needed

# Number of fragments
numfrag <- tiledb_query_get_fragment_num(qry)

# URI of given fragment, with 0 <= idx < numfrag
uri <- tiledb_query_get_fragment_uri(qry, idx)

# Timestamp range of given fragment, with 0 <= idx < numfrag
tsrange <- tiledb_query_get_fragment_timestamp_range(qry, idx)
```

## Reading Arrays

### Reading the Array Schema

#### Inspecting the array schema

```r
# get a schema directly from storage, uri holds a valid array URI
uri <- "<array_uri>"
sch <- schema(uri)

# get an encrypted scheme directory from storage, enc_key is the AES-256 key
sch <- schema(uri, enc_key)

# get a schema from an already openened array
# using a sparse array example, works the same for dense arrays
array_name <- urisparse
A <- tiledb_array(uri = array_name, is.sparse = TRUE)
sch <- schema(A)

# one can also open encrypted arrays with key for AES-256 encryption
# and all other options (for sparse arrays, data.frame objects...)
key <- "0123456789abcdeF0123456789abcdeF"
A <- tiledb_array(uri = array_name, encryption_key = key)
sch <- schema(A)
```



```r
# Get array schema, this shows the sparse accessor
# and it is similar for tiledb_dense()
A <- tiledb_array(uri = urisparse, is.sparse = TRUE)
schema <- schema(A)

# Get array type
sparse <- is.sparse(schema)

# Get tile capacity
t_capacity <- capacity(schema)

# Get tile order
t_order <- tile_order(schema)

# Get cell order
c_order <- cell_order(schema)

# Get coordinates and offset filter list
reslist <- filter_list(schema)

# Get the array domain
dom <- domain(schema)

# Get all attributes as list
attrs <- attrs(schema)

# Check if given attribute exists
has_attr <- has_attribute(schema, "attr")

# Get attribute from name
attr <- attrs(schema, "attr")

# Dump the array schema in ASCII format in the selected output
show(schema)
```


#### Inspecting Domain

```r
# ... get array schema
# ... get domain from schema

# Get the domain datatype (i.e., the datatype of all dimensions)
type <- datatype(dom)

# Get number of dimensions
dim_num <- dim(dom)

# Get all dimension
dims <- dimensions(dom)

# Get dimension by index (0 <= i < dim_num)
dim <- tiledb_domain_get_dimension_from_index(dom, 1)

# Get dimension by name
dim <- tiledb_domain_get_dimension_from_name(dom, "dimname")

# Check dimension for name
tiledb_domain_has_dimension(dom, "dimname")

# Dump the domain in ASCII format in the selected output
show(dom)
```

#### Inspecting Dimensions

```r
# ... get array schema
# ... get domain
# ... get dimension by index or name

# Get dimension name
dim_name <- name(dim)

# Get dimension datatype
dim_type <- datatype(dim)

# Get dimension domain
domain <- domain(dim)

# Get tile extent
tile_extent <- tile(dim)

# Dump the dimension in ASCII format in the selected output
show(dim)

```


#### Inspecting Attributes

```r
# ... get array schema
# ... get attribute by index or name

# Get attribute name
attr_name <- name(attr)

# Get attribute datatype
attr_type <- datatype(attr)

# Get filter list
filter_list <- filter_list(attr)

# Check if attribute is variable-length
is_var <- tiledb_attribute_is_variable_sized(attr)

# Get number of values per cell
num <- ncells(attr)

# Get cell size for this attribute
sz <- tiledb_attribute_get_cell_size(attr)

# Get the fill value (for both fixed and variable sized attributes)
tiledb_attribute_get_fill_value(attr)

# Dump the attribute in ASCII format in the selected output
show(attr)
```



#### Inspecting Filters

```r
# dim hold a previously created or load Dimension object
fltrlst <- filter_list(dim)
# or fltrlst <- filter_list(attr) for some attribute `attr`

# get number of filter
nb <- nfilters(fltrlst)

# get max chunk size
mxsz <- max_chunk_size(fltrlst)

# get filter by index from filter list (0 <= idx < num_filters)
idx <- i
fltr <- fltrlst[idx]

# get option (that is filter-dependent) from filter
tiledb_filter_get_option(fltr, "COMPRESSION_LEVEL")

# set option (that is filter-dependent) for filter
tiledb_filter_set_option(fltr, "COMPRESSION_LEVEL", 9)

# get filter type
tiledb_filter_type(fltr)
```

### Basic Reading

```r
# Open a dense array
A <- tiledb_array(uri = uridense)

# Or, open a sparse array
# A <- tiledb_sparse(uri = "<array-uri>", ctx=ctx)

# Slice only rows 1, 2 and cols 2, 3, 4
data <- A[1:2, 2:4]
show(data)
```

#### Basic Reading using Low-Level Code

```r
ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridense, "READ")
## subarray of rows 1,2 and cols 2,3,4
subarr <- c(1L,2L, 2L,4L)

qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "READ")
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")
v <- integer(6)  # reserve space
qryptr <- tiledb:::libtiledb_query_set_buffer(qryptr, "a", v)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
print(v)         # unformed array, no coordinates
res <- tiledb:::libtiledb_array_close(arrptr)
```

#### Variable-length Attributes

```r
ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridensevar, "READ")

subarr <- c(1L,4L, 1L,4L)
bufptr <- tiledb:::libtiledb_query_buffer_var_char_alloc(arrptr, subarr, "a1", 16, 100)

qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "READ")
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")

qryptr <- tiledb:::libtiledb_query_set_buffer_var_char(qryptr, "a1", bufptr)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
tiledb:::libtiledb_array_close(arrptr)

mat <- tiledb:::libtiledb_query_get_buffer_var_char(bufptr)
print(mat, quote=FALSE)
```

#### Getting the Non-empty Domain

```r
# example with one fixed- and one variable-sized domain
dom <- tiledb_domain(dims = c(tiledb_dim("d1", c(1L, 4L), 4L, "INT32"),
                              tiledb_dim("d2", NULL, NULL, "ASCII")))

# ... add attribute(s), write content, ...
# ... arr is the array opened

# retrieve non-empty domain for fixed-sized dimension
tiledb_array_get_non_empty_domain_from_index(arr, 1)
tiledb_array_get_non_empty_domain_from_name(arr, "d1")
# retrieve non-empty domain for variable-sized dimension
tiledb_array_get_non_empty_domain_from_index(arr, 2)
tiledb_array_get_non_empty_domain_from_name(arr, "d2")
```

#### Reopening Arrays

```r
# Arrays are reopened automatically for you based on
# read or write being performed. For direct pointer-based
# access you can also explicitly reopen
arr@ptr <- tiledb:::libtiledb_array_reopen(arr@ptr)
```


### Reading Encrypted Arrays

```r
# Open the array and read as a data.frame from it.
A <- tiledb_array(uri = array_name, return_as = "data.frame",
                  encryption_key = encryption_key)

# Slice rows 1 and 2, and cols 2, 3 and 4
A[1:2, 2:4]

# timestamps for TileDB are milliseconds since epoch, we use
# R Datime object to pass the value
tstamp <- as.POSIXct(1577955845.678, origin="1970-01-01")

# open the array for reading at the timestamp
A <- tiledb_array_open_at(A, "READ", tstamp)
```

### Multi-range Subarrays

```r
# create query, allocate result buffer, ...

# add two query range on the first dimension
qry <- tiledb_query_add_range(qry, schema, "d1", 2L, 4L)
qry <- tiledb_query_add_range(qry, schema, "d1", 6L, 8L)

# add a query range on the second dimension, using variable size
qry <- tiledb_query_add_range(qry, schema, "d2", "caaa", "gzzz")


# number of ranges given index
num <- tiledb_query_get_range_num(qry, idx)

# range start, end and stride for range i (1 <= i <= num)
rng <- tiledb_query_get_range(qry, idx, i)

# range start and end for variable-sized dimension for range i (1 <= i <= num)
strrng <- tiledb_query_get_range_var(qry, idx, i)
```

### Incomplete Queries

```r
ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open(ctx@ptr, uridense, "READ")
qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "READ")
subarr <- c(1L,4L, 1L,4L)
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
vec <- integer(4)  # reserve (insufficient) space
qryptr <- tiledb:::libtiledb_query_set_buffer(qryptr, "a", vec)
finished <- FALSE
while (!finished) {
  qryptr <- tiledb:::libtiledb_query_submit(qryptr)
  print(vec)
  finished <- tiledb:::libtiledb_query_status(qryptr) == "COMPLETE"
}
res <- tiledb:::libtiledb_array_close(arrptr)
```

### Result Estimation

```r
# ...create query object

# estimated size of a fixed-length attribute in sparse array
sz <- tiledb_query_get_est_result_size(qry, "a")

# estimated size of a variable-length attribute in dense or sparse array
sz <- tiledb_query_get_est_result_size_var(qry, "b")
```

### Time Traveling

```r
# time traveling is currently only accessible via the lower-level API
# we use the R Datetime type; internally TileDB uses milliseconds since epoch
tstamp <- Sys.time() - 60*60 # one hour ago

ctx <- tiledb_ctx()
arrptr <- tiledb:::libtiledb_array_open_at(ctx@ptr, uridense, "READ", tstamp)
subarr <- c(1L,2L, 2L,4L)
qryptr <- tiledb:::libtiledb_query(ctx@ptr, arrptr, "READ")
qryptr <- tiledb:::libtiledb_query_set_subarray(qryptr, subarr)
qryptr <- tiledb:::libtiledb_query_set_layout(qryptr, "COL_MAJOR")
a <- integer(6)  # reserve space
qryptr <- tiledb:::libtiledb_query_set_buffer(qryptr, "a", a)
qryptr <- tiledb:::libtiledb_query_submit(qryptr)
res <- tiledb:::libtiledb_array_close(arrptr)
a

# we can do the same with encrypted arrays
encryption_key <- "0123456789abcdeF0123456789abcdeF"
arrptr <- tiledb:::libtiledb_array_open_at_with_key(ctx@ptr, uridensewkey, "READ",
                                                    encryption_key, tstamp)
```

## Embedded SQL

## Asynchronous Queries

```r
#  ... create read or write query

# Instead of using tiledb_query_submit(), use tiledb_query_submit_async()
# There is an alternate form with a callback function which is not yet supported
tiledb_query_submit_async(qry)
```


## Configuration

#### Basic Usage

```r
# Create a configuration object
config <- tiledb_config()

# Set a configuration parameter
config["sm.tile_cache_size"] <- "5000"

# Get a configuration parameter
tile_cache_size <- config["sm.tile_cache_size"]

# Unset a configuration parameter
tiledb_config_unset(config, "sm.tile_cache_size")
```

#### Save and Load to File

```r
# Save to file
config <- tiledb_config()
config["sm.tile_cache_size"] <- 0;
file <- tempfile(pattern = "tiledb_config", fileext = ".txt")
tiledb_config_save(config, file)

# Load from file
config_loaded <- tiledb_config_load(file)
tile_cache_size = config_loaded["sm.tile_cache_size"]
```


#### Configuration Iterator

```r
# R has no native iterator but one loop over the config elements
# by retrieving the configuration as a vector

cfg <- as.vector(tiledb_config())

# print all non-empty config elements
for (n in names(cfg))
   if (cfg[n] != "")
      cat(n, ":", cfg[n], "\n")
```


## Array Metadata

#### Writing Array Metadata

```r
# 'array' can be a URI, or an array opened for writing
tiledb_put_metadata(array, "aaa", 100L)
tiledb_put_metadata(array, "bb", c(1.1, 2.2))
```

#### Reading Array Metadata

One can read by key:

```r
# 'array' can be a URI, or an array opened for reading
tiledb_get_metadata(array, "aaa")
```

Or one can retrieve all metadata at once:

```r
# 'array' can be a URI, or an array opened for reading
md <- tiledb_get_all_metadata(array)

# prints all keys and (formatted) values
print(md)
```

#### Deleting Array Metadata

```r
# 'array' can be a URI, or an array opened for writing
tiledb_delete_metadata(array, "aaa")
```

## Consolidating And Vacuuming

#### Fragments

```r
# An array URI
uri <- "<array_uri>"

# Consolidate with default configuration
array_consolidate(uri)

# Alteratively, create and pass a configuration object
cfg <- tiledb_config()
cfg["sm.consolidation.steps"] <- "3"
cfg["sm.consolidation.mode"] <- "fragments"
array_consolidate(uri, cfg)
```

#### Vacuuming

```r
# An array URI
uri <- "<array_uri>"

# Vacuum with default configuration
array_vacuum(uri)

# Alteratively, create and pass a configuration object
cfg <- tiledb_config()
cfg["sm.vacuum.mode"] <- "fragments"
array_vacuum(uri, cfg)
```

## Object Management

#### Creating TileDB Groups

```r
tiledb_group_create("/tmp/my_group")
```


#### Getting the Object Type

```r
type <- tiledb_object_type("<path>")
```

#### List the Object Hierarchy

```r
# List arrays (defaults to default "PREORDER" traversal)
tiledb_object_ls(uri)

# Walk arrays (with "POSTORDER" traversal) returning a data.frame
res <- tiledb_object_walk("<uri>", "POSTORDER")

# Show the content
print(res)
```

#### Move / Remove Object

```r
tiledb_object_mv("/tmp/my_group", "/tmp/my_group_2")

tiledb_object_rm("/tmp/my_group_2/dense_array")
```


## Virtual Filesystem

#### Writing

```r
# binary file to be written
uri <- tempfile(pattern = "tiledb_vfs", fileext = ".bin")
# open file
fhbuf <- tiledb_vfs_open(uri, "WRITE")

# create a binary payload from a serialized R object
payload <- as.integer(serialize(list(dbl=153, string="abcde"), NULL))
# write it and close file
tiledb_vfs_write(fhbuf, payload)
tiledb_vfs_close(fhbuf)

# write again overwriting previous write
fhbuf <- tiledb_vfs_open(uri, "WRITE")
payload <- as.integer(serialize(list(dbl=153.1, string="abcdef"), NULL))
tiledb_vfs_write(fhbuf, payload)
tiledb_vfs_close(fhbuf)

# append to existing file
fhbuf <- tiledb_vfs_open(uri, "APPEND")
payload <- as.integer(serialize(c(string="ghijkl"), NULL))
tiledb_vfs_write(fhbuf, payload)
tiledb_vfs_close(fhbuf)
```

#### Reading

```r
# open a binary file for reading
fhbuf <- tiledb_vfs_open(uri, "READ")
vec <- tiledb_vfs_read(fhbuf, as.integer64(0), as.integer64(488))
tiledb_vfs_close(fhbuf)
```

#### Managing

```r
# Creating a directory
if (!tiledb_vfs_is_dir("dir_A")) {
    tiledb_vfs_create_dir("dir_A")
    cat("Created 'dir_A'\n")
} else {
    cat("'dir_A' already exists\n")
}

# Creating an (empty) file
if (!tiledb_vfs_is_file("dir_A/file_A")) {
    tiledb_vfs_touch("dir_A/file_A")
    cat("Created empty file 'dir_A/file_A'\n")
} else {
    cat("File 'dir_A/file_A' already existed\n")
}

# Getting the file size
cat("Size of file 'dir_A/file_A': ",
    tiledb_vfs_file_size("dir_A/file_A"), "\n")

# Moving files (moving directories is similar)
tiledb_vfs_move_file("dir_A/file_A", "dir_A/file_B")

# Cleaning up
tiledb_vfs_remove_file("dir_A/file_B")
tiledb_vfs_remove_dir("dir_A")
```


#### S3

```r
tiledb_vfs_create_bucket("s3://my_bucket")

tiledb_vfs_remove_bucket("s3://my_bucket")
```


#### Configuring VFS

```r
ctx <- tiledb_get_context()

config <- tiledb_config()
config["vfs.file.max_parallel_ops"] <- 16

vfs <- tiledb_vfs(config, ctx)

# Or create the Config first and pass to the Ctx constructor
```


## Using Performance Statistics

```r
# Start collecting statistics
tiledb_stats_enable()

# ... create some query here

res <- A[1:4]

# Stop collecting statistics
tiledb_stats_disable()

# Show the statistics on the console
tiledb_stats_print()

# Save the statistics to a file
tiledb_stats_dump("my_file_name")

# You can also reset the stats as follows
tiledb_stats_reset()
```

## Catching Errors

```r
result <- tryCatch({
    # Create a group. The code below creates a group `my_group` and prints a
    # message because (normally) it will succeed.
    tiledb_group_create("/tmp/my_group")

    # Create the same group again. If we attempt to create the same group
    # `my_group` as shown below, TileDB will return an error.
    tiledb_group_create("/tmp.my_group")
}, warning = function(w) {
   cat(w)
}, error = function(e) {
    cat(e)
}, finally = {}
)
```
