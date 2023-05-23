# data_storage.R

#' Get (i.e., load / retrieve) a value for a particular test-taker
#'
#' @param session The shiny session object.
#' @param name Name of the value.
#' @param default Default value.
#' @param store Should the value be stored, if the default is used?
#' @return The value (if present) for the current test-taker (or the default value)
#' @examples
#' getValueForTestTaker(session, "FirstItem",1)
#' getValueForTestTaker(session, "FirstItem",1, T)

getValueForTestTaker <- function(session, name, default=NULL, store=T){
  shinyassess_internal_create_or_load_session(session)
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

#' Set (i.e., save, store) a value for a particular test-taker
#'
#' @param session The shiny session object.
#' @param name Name of the value.
#' @param value Value to store.
#' @examples
#' setValueForTestTaker(session, "FirstItem",1)
#' setValueForTestTaker(session, "FirstItem",2)

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
