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

try_get_node <- function(){
  x <- Sys.which("nodejs")
  if (x == ""){
    x <- Sys.which("node")
  }
  if (x == ""){
    stop("Couldn't find NodeJS.\nPlease provide its path manually.")
    return(NULL)
  } else {
    return(x)
  }
}


#' NodeJS REPL
#'
#' @param bin path to your node bin
#'
#' @return a NodeJS REPL
#' @export
node_repl <- function(
  bin = try_get_node()
){
  NodeREPL$new(bin)
}


