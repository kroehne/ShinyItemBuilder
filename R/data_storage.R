# data_storage.R

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

setValueForTestTaker <- function(session, name, value){
  runtime.data[[session$userData$cbasession]][[name]] <<- value
}
