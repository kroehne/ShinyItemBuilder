# ui_assessmentOutput.R

assessmentOutput <- function(pool = NULL,config = NULL, overwrite=F){

  if (is.null(pool) || is.null(config)){
    stop("pool object and config object required.")
  }

  if (!overwrite && dir.exists("www")){
    stop("Directory 'www' exist. Provide 'overwrite=T' if the content should be overwritten.")
  }

  shinyassess_internal_initialize_storage()

  assessment_env$eesource = file.path(system.file("static", package = "ShinyItemBuilder"), "EE_App_Output/")
  assessment_env$jssource = file.path(system.file("static", package = "ShinyItemBuilder"), "ShinyAssessJS/")
  assessment_env$ibsource = file.path(system.file("static", package = "ShinyItemBuilder"), "IBProjects/")

  assessment_env$pool = pool
  assessment_env$config = config

  extended_pool <- shinyassess_internal_get_pool_from_folder(path = assessment_env$ibsource, pool)

  shinyassess_internal_prepare_www_folder(extended_pool)
  shinyassess_internal_prepare_execution_environment(extended_pool)

  addResourcePath("www", "./")

  fluidPage(

    tags$head(HTML(paste0("<title>", assessment_env$config$WindowTitle , "</title>"))),

    htmlOutput("frame")  ,

    tags$script(HTML( "window.addEventListener('message', (e) => {
    Shiny.onInputChange('ibevents', e.data, {priority: 'event'});
   });")) ,

    tags$script(
      "Shiny.addCustomMessageHandler('shinyassess_navigate_to', function(params) {
      let iframe = document.getElementById('myiframe');
      iframe.contentWindow.postMessage(params, window.location.origin);
    });
    Shiny.addCustomMessageHandler('shinyassess_iframe_visibility', function(params) {
      let iframe = document.getElementById('myiframe');
      iframe.style.display = params;
    });
    Shiny.addCustomMessageHandler('shinyassess_restart', function(params) {
       let iframe = document.getElementById('myiframe');
       document.cookie = '';
       localStorage.setItem( 'session', '');
       sessionStorage.setItem('session','');
       iframe.contentWindow.location.reload();
    });
    Shiny.addCustomMessageHandler('shinyassess_redirect', function(message) {
      window.location = message;
    });
    ")


  )

}


shinyassess_internal_prepare_execution_environment <- function (pool){

  if (assessment_env$config$verbose){
    cat(paste0("Start preparing execution environment.\n"))
  }

  #fn <- list.files(assessment_env$jssource)
  #for (f in fn){
  #  file.copy(file.path(assessment_env$jssource,f), "www", recursive=TRUE)
  #}

  fn <- list.files(assessment_env$eesource)
  for (f in fn){
    file.copy(file.path(assessment_env$eesource,f), "www", recursive=TRUE)
  }

  if (assessment_env$config$verbose){
    cat(paste0("Write configuration file.\n"))
  }

  if(!dir.exists(file.path("www","assessments"))){
    dir.create(file.path("www","assessments"))
  }

  fileConn<-file("www/assessments/config.json")
  writeLines(paste0('{"tasks": [', paste0('{"item": "', pool$itemName, '", "task":"', pool$Task, '", "scope":"' , pool$Scope, '"}', collapse = ",") , '] }'), fileConn)
  close(fileConn)

  if (assessment_env$config$verbose){
    cat(paste0("Preparation completed.\n"))
  }
}

shinyassess_internal_prepare_www_folder <- function(pool){

  if(!dir.exists("www")){
    dir.create("www")
  }
  if(!dir.exists(file.path("www","items"))){
    dir.create(file.path("www","items"))
  }

  for (i in 1:dim(pool)[1]){
    if(!dir.exists(file.path("www","items",pool[i,"itemName"]))){
      dir.create(file.path("www","items",pool[i,"itemName"]))
    }

    unzip(pool[i,"FullPath"],exdir=file.path("www","items",pool[i,"itemName"]),files=c("config.json","internal.json","stimulus.json"))

    fn <- unzip(pool[i,"FullPath"],list=T)

    if (length(fn[startsWith(fn$Name, "resources/"),"Name"])>0){
      unzip(pool[i,"FullPath"],exdir=file.path("www","items",pool[i,"itemName"]),files=fn[startsWith(fn$Name, "resources/"),"Name"])
    }

    if (length(fn[startsWith(fn$Name, "external-resources/"),"Name"])>0){
      unzip(pool[i,"FullPath"],exdir=file.path("www","items",pool[i,"itemName"]),files=fn[startsWith(fn$Name, "external-resources/"),"Name"])
    }

    if (!file.exists(file.path("www","items",pool[i,"itemName"],"config.json"))){
      cat(paste0("File 'config.json' not found in item '", pool[i,"Project"], "' not found.\n"))
      stop()
    } else if (!file.exists(file.path("www","items",pool[i,"itemName"],"internal.json"))){
      cat(paste0("File 'internal.json' not found in item '", pool[i,"Project"], "' not found.\n"))
      stop()
    } else if(!file.exists(file.path("www","items",pool[i,"itemName"],"stimulus.json"))){
      cat(paste0("File 'stimulus.json' not found in item '", pool[i,"Project"], "' not found.\n"))
      stop()
    }

    if (assessment_env$config$verbose){
      cat(paste0("Prepared CBA ItemBuilder Project File '",pool[i,"Project"], "'.\n"))
    }

  }

}
