#' NodeJS Session
#'
#' Launch a NodeJS Session
#'
#' @importFrom subprocess spawn_process process_read process_write PIPE_STDOUT process_kill process_state process_terminate
#' @importFrom utils savehistory loadhistory
#' @importFrom cli cat_rule cat_line
#' @importFrom rlang quo_name as_label enquo
#' @export
#' 
#' @field bin Path to NodeJs bin directory.
#' @field handle A handle as returned by \link[subprocess]{spawn_process}.
NodeSession <- R6::R6Class(
  "NodeSession",
  public = list(
    bin = NULL,
    handle = NULL,
#' @details
#' Initialise a NodeJs session
#' 
#' @param bin Path to NodeJs bin directory, if \code{NULL} then bubble 
#' attemtpts to find the directory with \code{\link{find_node}}. 
#' @param params Additional parameters to pass to the initialisation.
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$eval("17 + 29")
#' }
    initialize = function(
      bin = NULL,
      params = "-i"
    ){

      if (is.null(bin)){
        bin <- find_node()
      }
      self$bin <- bin
      self$handle <- spawn_process(self$bin, params)
      process_read(self$handle, PIPE_STDOUT, timeout = 5000)

      # declare node function to check if a module is available
      # will use to check if fs installed for assign method.
      self$eval(check_module_avail_node_function, print = FALSE)
      invisible(self)
    },
#' @details
#' Terminate a NodeJs session
    finalize = function(){
      self$kill()
    },
#' @details
#' Evaluate NodeJs code
#' 
#' @param code The code to evaluate.
#' @param wait Whether to re-attempt to evaluate if it first fails.
#' @param print Whether to print the result to the R console.
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$eval("17 + 29")
#' }
    eval = function(code, wait = TRUE, print = TRUE){
      process_write(self$handle, paste(code, "\n"))
      res <- process_read(self$handle, PIPE_STDOUT, timeout = 0)
      if (wait){
        while (length(res) == 0){
          Sys.sleep(0.1)
          res <- process_read(self$handle, PIPE_STDOUT, timeout = 0)
        }
        if (print){
          sapply(res[-length(res)], handle_res)
        }
        return(invisible(res[-length(res)]))
      }
    },
#' @details
#' Create NodeJs objects
#' 
#' @param name Name of variable to create.post
#' @param value Value to assign to variable.
#' @param type Type of variable to define.
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$assign(carz, cars)
#' n$get(carz)
#' }
    assign = function(name, value, type = c("var", "const")){

      if(missing(name))
        stop("Missing `name`", call. = FALSE)

      type <- match.arg(type)

      quo_name <- enquo(name)
      name <- as_label(quo_name)

      if(missing(value))
        stop("Missing `value`", call. = FALSE)

      # check if fs module available
      has_fs <- check_module_avail(self, "fs")

      if(has_fs){
        # import fs if not already done so
        if(!private$fs_imported){
          cat(
            crayon::blue(cli::symbol$info),
            "Importing fs module as", crayon::blue("fs"), "object\n"
          )
          self$eval("const fs = require('fs')", print = FALSE)
          private$fs_imported <- TRUE
        }

        json_fs <- as_json_file(name, value, type)
        self$eval(json_fs$call, print = FALSE)
        unlink(json_fs$tempfile)
      }

      # convert value to json array AND variable definition.
      json <- as_json_string(name, value, type)
      self$eval(json, print = FALSE)

      invisible(self)
    },
#' @details
#' Retrieve NodeJs objects
#' 
#' @param var Bare name of object to retrieve.
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$eval("var x = 12")
#' n$get(x)
#' }
    get = function(var){
      var <- enquo(var)
      var <- quo_name(var)

      stringify <- paste0("JSON.stringify(", var, ", null, 0);")
      node_object <- self$eval(stringify, print = FALSE)

      # remove surrounding single quotes
      node_object <- gsub("^'|'$", "", node_object)

      # catch error is object is JSON
      results <- tryCatch(
        jsonlite::fromJSON(node_object),
        error = function(e) e
      )

      return(results)
    },
#' @details
#' Retrieve NodeJs state
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$state()
#' n$kill()
#' n$state()
#' }
    state = function(){
      process_state(self$handle)
    },
#' @details
#' Kill NodeJs
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$kill()
#' n$state()
#' }
    kill = function(){
      if (self$state() != "terminated"){
        process_kill(self$handle)
      } else {
        cli::cat_line("Process not running:")
        self$state()
      }

    },
#' @details
#' Terminate NodeJs
#' 
#' @examples
#' \dontrun{
#' n <- NodeSession$new()
#' n$terminate()
#' n$state()
#' }
    terminate = function(){
      if (self$state() != "terminated"){
        process_terminate(self$handle)
      } else {
        cli::cat_line("Process not running:")
        self$state()
      }

    }
  ),
  private = list(
    fs_imported = FALSE
  )
)

NodeREPL <- R6::R6Class(
  "NodeREPL",
  inherit = NodeSession,
  public = list(
    np = NULL,
    initialize = function(
      bin = NULL
    ){
      super$initialize(
        bin,
        params = "-i"
      )
      self$np <- "node > "
      cat_rule("Welcome to node REPL")
      cat_line("Press ESC to quit")

      private$hist <- tempfile()
      file.create(private$hist)

      self$prompt(
        self$np
      )
    },
    prompt = function(
      prompt
    ){
      savehistory()
      on.exit(loadhistory())

      repeat {
        loadhistory(
          private$hist
        )
        x <- readline(self$np)
        write(x, private$hist, append = TRUE)
        process_write(self$handle, paste(x, "\n"))
        res <- process_read(self$handle, PIPE_STDOUT, timeout = 0)
        while (length(res) == 0){
          Sys.sleep(0.1)
          res <- process_read(self$handle, PIPE_STDOUT, timeout = 0)
        }
        np <- res[length(res)]
        bod <- res[-length(res)]
        np <- gsub("> >", ">", np)
        if (!grepl("\\.\\.\\.", np)){
          sapply(bod, handle_res)
          self$np <- paste("node", np)
        } else {
          self$np <- np
        }
      }
    }
  ),
  private = list(
    hist = NULL
  )

)


#' Node Package Manager
#' 
#' Create and interact with npm. 
#' 
#' @field bin Path to npm bin directory.
#' @export
Npm <- R6::R6Class(
  "Npm",
  public = list(
    bin = NULL,
#' @details
#' Initialise npm
#' 
#' @param bin Path to npm bin directory.
#' 
#' @examples
#' \dontrun{Npm$new()}
    initialize = function(bin = NULL){
      if (is.null(bin)){
        bin <- find_npm()
      }
      self$bin <- bin

      init <- system2(self$bin, "init -y", stdout = TRUE)

      cat(
        crayon::green(cli::symbol$pointer), " Add `", crayon::blue("node_modules"), "` to .gitignore\n",
        sep = ""
      )

    },
#' @details
#' Execute command
#' 
#' @param command Command to execute.
#' @param ... Additional arguments and flags.
#' 
#' @examples
#' \dontrun{Npm$new()$cmd("ls")}
    cmd = function(command, ...){
      args <- paste(command, ..., collapse = " ")
      system2(
        command = self$bin,
        args = args,
        stdout = TRUE
      ) 
    },
#' @details
#' Install packages
#' 
#' @param package Name of npm package to install. If \code{NULL}
#' install dependencies from lock file.
#' @param global Whether to install globally.
#' 
#' @examples
#' \dontrun{Npm$new()$install("browserify")}
    install = function(package = NULL, global = FALSE){

      # install globally or locally
      option <- ifelse(global, "-g", "--save")
      args <- paste("install", option, package)

      install <- system2(self$bin, args, stdout = TRUE)
      
      invisible(self)
    },
#' @details
#' Uninstall packages
#' 
#' @param package Name of npm package to install. If \code{NULL}
#' install dependencies from lock file.
#' @param global Whether to install globally.
#' 
#' @examples
#' \dontrun{Npm$new()$install("browserify")}
    uninstall = function(package = NULL, global = FALSE){

      # install globally or locally
      option <- ifelse(global, "-g", "--save")
      args <- paste("uninstall", option, package)

      install <- system2(self$bin, args, stdout = TRUE)
      
      invisible(self)
    }
  )
)