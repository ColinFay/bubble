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
#' @param type Variable type.
#' 
#' @name json_conversion
#' @keywords internal 
as_json_string <- function(name, value, type){
  value <- jsonlite::toJSON(value, auto_unbox = TRUE, pretty = FALSE, force = TRUE)
  paste0(type, ' ', name, ' = JSON.parse(\'', value, '\');', collapse = '')
}

#' @rdname json_conversion
#' @keywords internal 
as_json_file <- function(name, value, type){
  
  # temporary storage
  tempfile <- tempfile(fileext = ".json")
  jsonlite::write_json(value, path = tempfile, auto_unbox = TRUE, pretty = FALSE, force = TRUE)

  call <- paste0(
    "let raw_bubbly_data = fs.readFileSync('", tempfile, "');\n", # use variable name unlikely to be used
    type, " ", name, " = JSON.parse(raw_bubbly_data);\n"
  )
  
  # return temp file so it can be unlinked.
  list(
    call = call,
    tempfile = tempfile
  )
}

#' Check Module Availability.
#' 
#' @keywords internal
check_module_avail <- function(self, module){
  if(missing(module))
    stop("Missing module", call. = FALSE)
  call <- paste0("isModuleAvalailableToBubble('", module, "')")
  response <- self$eval(call, print = FALSE)
  as.logical(toupper(response))
}

check_module_avail_node_function <- 
  "function isModuleAvalailableToBubble(name) {
    try {
        require.resolve(name);
        return true;
    } catch(e){}
    return false;
  }"
