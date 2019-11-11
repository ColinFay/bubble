#' Knitr engine for NodeJS
#'
#' @param bin path to bin
#' @export
set_node_engine <- function(
  bin = find_node()
){
  knitr::opts_chunk$set(
    node = bubble::NodeSession$new()
  )
  knitr::knit_engines$set(node = function(
    options
  ) {
    if (options$eval) {
      out <- c()
      for (i in options$code){
        out <- c(out, options$node$eval(i))
      }
    }
    knitr::engine_output(options, options$code, out)
  })
}
