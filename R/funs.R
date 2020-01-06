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


#' Try to get the path to the NodeJS bin
#' @export
find_node <- function(){
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
  bin = find_node()
){
  NodeREPL$new(bin)
}

#' Find Node Package Manager
#' @export 
find_npm <- function(){
  x <- Sys.which("npm")
  if (x == ""){
    stop("Couldn't find npm.\nPlease provide its path manually.")
    return(NULL)
  } else {
    return(x)
  }
}

#' Convert to json
#' 
#' @param name Name of variable.
#' @param value Value to convert.
#' 
#' @name json_conversion
#' @keywords internal 
as_json <- function(name, value){
  value <- jsonlite::toJSON(value, auto_unbox = TRUE, pretty = FALSE, force = TRUE)
  paste0('var ', name, ' = JSON.parse(\'', value, '\');', collapse = '')
}