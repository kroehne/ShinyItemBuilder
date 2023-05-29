# data_storage.R

#' @title Get (i.e., load / retrieve) a value for a particular test-taker
#' @description `getValueForTestTaker` can be used in a custom navigation
#'              function to load data for the current session.
#' @param session The shiny session object.
#' @param name Name of the value.
#' @param default Default value.
#' @param store Should the value be stored, if the default is used?
#' @return The value (if present) for the current test-taker (or the default value)
#' @export
#' @examples
#' \dontrun{
#'   value <- getValueForTestTaker(session, "current-item")
#' }

getValueForTestTaker <- function(session, name, default=NULL, store=T){

  if (exists(name, runtime.data[[session$userData$cbasession]])){
    runtime.data[[session$userData$cbasession]][[name]]
  }
  else
  {
    if (store)
      runtime.data[[session$userData$cbasession]][[name]] <<- default
    default
  }
}

#' @title Set (i.e., save, store) a value for a particular test-taker
#' @description `getValueForTestTaker` can be used in a custom navigation
#'              function to store data for the current session.
#' @param session The shiny session object.
#' @param name Name of the value.
#' @param value Value to store.
#' @return The value (if present) for the current test-taker (or the default value)
#' @export
#' @examples
#' \dontrun{
#'   setValueForTestTaker(session, "current-item",1)
#' }

setValueForTestTaker <- function(session, name, value){
  runtime.data[[session$userData$cbasession]][[name]] <<- value
}

### Internal Functions ####

shinyassess_internal_initialize_storage <- function()
{
  assessment_env <<- base::new.env(parent = base::emptyenv())

  if (!exists("runtime.data"))
    runtime.data <<- list()

}

shinyassess_internal_create_or_load_session <- function (session){
  if (!exists(session$userData$cbasession, runtime.data)){

    if (file.exists(paste0(assessment_env$config$Datafolder, "/",session$userData$cbasession,".RDS" ))){

      runtime.data[[session$userData$cbasession]] <<- readRDS(file=file.path(assessment_env$config$Datafolder,paste0(session$userData$cbasession,".RDS")))
      if (assessment_env$config$verbose)
        print(paste0("Info: Session - loaded from file (cbasession=", session$userData$cbasession, ")"))

    } else {

      runtime.data[[session$userData$cbasession]] <<- list()

      if (assessment_env$config$verbose)
        print(paste0("Info: Session - created (cbasession=", session$userData$cbasession,")"))

        shinyassess_internal_save_session(session)

    }

  } else {
    if (assessment_env$config$verbose)
       print(paste0("Info: Session - in memory (cbasession=",session$userData$cbasession, ")"))
  }
}

shinyassess_internal_save_session <- function(session){
  saveRDS(runtime.data[[session$userData$cbasession]], file=file.path(assessment_env$config$Datafolder,paste0(session$userData$cbasession,".RDS")))
}
