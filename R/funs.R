library(subprocess)

#' @importFrom cli cat_line
#' @importFrom crayon blue
handle_res <- function(res){
  if (res == "undefined"){
    res <- blue(res)
  }
  cat_line(res)
}

handle_reses <- function(reses){
  if (reses[length(reses)] != "... "){
    sapply(reses[-length(reses)], handle_res)
  }
  np <- gsub("> >", ">", reses[length(reses)])
  return(np)
}


#' NodeJS REPL
#'
#' @param node path to your node bin
#'
#' @return a NodeJS REPL
#' @export
node_repl <- function(
  bin = "/usr/local/bin/node"
){
  NodeREPL$new(bin)
}


