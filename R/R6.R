#' NodeJS Session
#'
#' Launch a NodeJS Session
#'
#' @importFrom subprocess spawn_process process_read process_write PIPE_STDOUT process_kill process_state process_terminate
#' @importFrom utils savehistory loadhistory
#' @importFrom cli cat_rule cat_line
#' @importFrom rlang enquos quo_name
#' @export
NodeSession <- R6::R6Class(
  "NodeSession",
  public = list(
    bin = NULL,
    handle = NULL,
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
    },
    finalize = function(){
      self$kill()
    },
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
    get = function(...){
      var <- enquos(...)
      var <- vapply(
        var,
        quo_name,
        FUN.VALUE = character(1)
      )
      var <- sprintf(
        "[%s]",
        paste(var, collapse = ", ")
      )
      jsonlite::fromJSON(
        self$eval(
          var,
          print = FALSE
        )
      )
    },
    state = function(){
      process_state(self$handle)
    },
    kill = function(){
      if (self$state() != "terminated"){
        process_kill(self$handle)
      } else {
        cli::cat_line("Process not running:")
        self$state()
      }

    },
    terminate = function(){
      if (self$state() != "terminated"){
        process_terminate(self$handle)
      } else {
        cli::cat_line("Process not running:")
        self$state()
      }

    }
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
#' @export
NpmSession <- R6::R6Class(
  "NpmSession",
  public = list(
    bin = NULL,
    initialize = function(bin = NULL){
      if (is.null(bin)){
        bin <- find_npm()
      }
      self$bin <- bin

      init <- system2(self$bin, "init -y", stdout = TRUE)

      # ignore all on rbuildignore
      # keep package.json in git for easy project share
      git_ignore <- c("node_modules")
      build_ignore <- c("package.json", "package-lock.json", git_ignore)
      
      # might not be a package
      build_ignore_out <- tryCatch(
        usethis::use_build_ignore(build_ignore), 
        error = function(e) e
      )
      git_ignore_out <- tryCatch(
        usethis::use_git_ignore(git_ignore), 
        error = function(e) e
      )

    },
    install = function(package = NULL, global = FALSE){

      # install globally or locally
      option <- ifelse(global, "-g", "--save")
      
      # install npm repo
      if(is.null(package)){
        args <- paste("install", option)
        install <- system2(self$bin, args, stdout = TRUE)
        return(self)
      }

      args <- paste("install", option, package)
      install <- system2(self$bin, args, stdout = TRUE)
      
      invisible(self)
    }
  )
)