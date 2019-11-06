library(bubble)
library(testthat)

n <- NodeSession$new( bin = Sys.which("nodejs") )

cli::cat_line("Check NodeSession class")
expect_is(n, "NodeSession")
expect_is(n, "R6")

cli::cat_line("Send things to node")
n$eval("var x = 12")
n$eval("var y = 17")
n$eval("x + ")
n$eval("y")

cli::cat_line("Retrieve values")
x <- n$get(x, y)

cli::cat_line("Check result")
expect_is(x, "integer")
expect_is(sum(x), "integer")

cli::cat_line("Check states")
expect_equal(n$state(), "running")
expect_true(n$terminate())
expect_equal(n$state(), "terminated")

n <- NodeSession$new( bin = Sys.which("nodejs"))

n$eval("const express = require('express');")
n$eval("app = express()", print = FALSE)

n$eval("app.get('/', function (req, res) {")
n$eval("  res.send('Hello R!')")
n$eval("})", print = FALSE)
n$eval("app.listen(3000)", print = FALSE)
x <- readLines("http://127.0.0.1:3000")
expect_equal(x, "Hello R!")
n$kill()
