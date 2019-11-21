rmd <- function(){
  attempt::stop_if_not(
    rstudioapi::isAvailable(),
    msg = "Can't run this function outside RStudio."
  )

  attempt::stop_if_not(
    rstudioapi::hasFun(
      c("getActiveDocumentContext",
        "insertText")
    ),
    msg = "Your RStudio version is too old to run this addin."
  )

  rstudioapi::insertText(
    location = rstudioapi::getActiveDocumentContext()$selection[[1]]$range,
    text = "```{node}\n  \n```\n"
  )
}
