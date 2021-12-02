library(tinytest)
library(tiledb)

if (Sys.info()[["sysname"]] == "Windows") exit_file("Skip on Windows")
if (Sys.info()['sysname'] == "Darwin") exit_file("Skip on macOS")

ctx <- tiledb_ctx(limitTileDBCores())

if (tiledb_version(TRUE) < "2.4.0") exit_file("Needs TileDB 2.4.* or later")

uri <- tempfile()
fromDataFrame(mtcars, uri)              			# create an array
arr <- tiledb_array(uri, return_as="data.frame")
basepath <- file.path("/dev", "shm", "mtcars", "buffers", "data")
if (!dir.exists(basepath)) dir.create(basepath, recursive=TRUE)
arr@dumpbuffers <- "mtcars"             			# store buffers below mtcars
v1 <- arr[]
arr@dumpbuffers <- character()          			# turn buffer store off again
pathroot <- file.path("/", "dev", "shm", "mtcars", "buffers", "data")
arr@buffers <- sapply(colnames(v1), function(x) file.path(pathroot, x), simplify=FALSE)
v2 <- arr[]
expect_true(all.equal(v1, v2))

if (!requireNamespace("palmerpenguins", quietly=TRUE)) exit_file("remainder needs 'palmerpenguins'")
library(palmerpenguins)
uri <- tempfile()
fromDataFrame(penguins, uri)
arr <- tiledb_array(uri, return_as="data.frame")
arr@dumpbuffers <- "penguins"             			# store buffers below mtcars
v3 <- arr[]
arr@dumpbuffers <- character()          			# turn buffer store off again
pathroot <- file.path("/", "dev", "shm", "penguins", "buffers", "data")
arr@buffers <- sapply(colnames(v3), function(x) file.path(pathroot, x), simplify=FALSE)
v4 <- arr[]
expect_true(all.equal(v3, v4))