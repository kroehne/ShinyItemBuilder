# ui_assessmentOutput.R

#' @title Create assessment output
#' @description Function to be passed as argument to 'shinyApp(ui=...)'
#' @param pool Pool
#' @param config Config
#' @param overwrite T/F
#' @return code to be used as argument to the function 'shinyApp(ui=...)'
#' @import shiny
#' @import base64enc
#' @export
#' @examples
#' \dontrun{
#' shinyApp(assessmentOutput(pool = getDemoPool("demo01"),
#'    config = getConfig(), overwrite=T), renderAssessment)
#' }

assessmentOutput <- function(pool = NULL,config = NULL, overwrite=F){

  if (is.null(pool) || is.null(config)){
    stop("pool object and config object required.")
  }

  shinyassess_internal_initialize_storage()

  assessment_env$eesource = file.path(system.file("ee", package = "ShinyItemBuilder"), "/")
  assessment_env$jssource = file.path(system.file("js", package = "ShinyItemBuilder"), "/")
  assessment_env$ibsource = file.path(system.file("ib", package = "ShinyItemBuilder"), "/")
  assessment_env$pool = pool
  assessment_env$config = config

  if (!overwrite && dir.exists(assessment_env$config$WWWfolder)){
    stop(paste0("Directory '", assessment_env$config$WWWfolder, "' (configured as www folder) exist . Provide 'overwrite=T' if the content should be overwritten."))
  }

  if (!dir.exists(assessment_env$config$WWWfolder)){
    dir.create(assessment_env$config$WWWfolder)
  }

  if (!is.na(match(assessment_env$config$WWWfolder,shiny::resourcePaths()))){
    shiny::removeResourcePath(assessment_env$config$WWWfolder)
  }

  if (!dir.exists(assessment_env$config$Datafolder))
    dir.create(assessment_env$config$Datafolder)

  extended_pool <- shinyassess_internal_get_pool_from_folder(path = assessment_env$ibsource, pool)

  shinyassess_internal_prepare_www_folder(extended_pool,config)
  shinyassess_internal_prepare_execution_environment(extended_pool,config)

  shiny::addResourcePath(paste0(getwd(),"/",assessment_env$config$WWWfolder), prefix = "ee")

  shiny::fluidPage(

    tags$head(HTML(paste0("<title>", assessment_env$config$WindowTitle , "</title>"))),

    htmlOutput("frame")  ,

    tags$script(HTML("
      window.addEventListener('message', (e) => {
         Shiny.onInputChange('ibevents', e.data, {priority: 'event'});
      });
    ")) ,

    tags$script("
      Shiny.addCustomMessageHandler('shinyassess_navigate_to', function(params) {
        let iframe = document.getElementById('myiframe');
        iframe.contentWindow.postMessage({type: 'navigate_to', request: params}, window.location.origin);
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
      Shiny.addCustomMessageHandler('shinyassess_load_state', function(params) {
        let iframe = document.getElementById('myiframe');
        iframe.contentWindow.postMessage({type: 'preload_state', request: params}, window.location.origin);
      });
      Shiny.addCustomMessageHandler('shinyassess_process_response', function(params) {
        let iframe = document.getElementById('myiframe').contentDocument.querySelector('iframe');
        iframe.contentDocument.querySelector('iframe').contentWindow.postMessage({type: 'shiny_response', response: params}, '*');
      });
    ")

  )

}

### Internal Functions ####


shinyassess_internal_prepare_execution_environment <- function (pool,config){

  if (config$verbose){
    cat(paste0("Start preparing execution environment.\n"))
  }

  #fn <- list.files(assessment_env$jssource)
  #for (f in fn){
  #  file.copy(file.path(assessment_env$jssource,f), config$WWWfolder, recursive=TRUE)
  #}

  fn <- list.files(assessment_env$eesource)
  for (f in fn){
    file.copy(file.path(assessment_env$eesource,f), config$WWWfolder, recursive=TRUE)
  }

  if (config$verbose){
    cat(paste0("Write configuration file.\n"))
  }

  if(!dir.exists(file.path(config$WWWfolder,"assessments"))){
    dir.create(file.path(config$WWWfolder,"assessments"))
  }

  fileConn<-file(paste0(config$WWWfolder,"/assessments/config.json"))
  writeLines(paste0('{"tasks": [', paste0('{"item": "', pool$itemName, '", "task":"', pool$Task, '", "scope":"' , pool$Scope, '"}', collapse = ",") , '] }'), fileConn)
  close(fileConn)

  if(!dir.exists(file.path(config$WWWfolder,"controller"))){
    dir.create(file.path(config$WWWfolder,"controller"))
  }

  fileConn<-file(paste0(config$WWWfolder,"/controller/config.json"))
  writeLines(paste0('{ "mathJaxCdnUrl": "math-jax unknown", "itemSize": { "height": ', max(pool$itemHeight), ', "width": ', max(pool$itemWidth), ' }, "players": [ { "playerId": "A", "runtimeVersion": "9.9.0", "frameContentFile": "frameContent_9_9_0.html" } ], "showPlayerInfo": false }'), fileConn)
  close(fileConn)

  if (config$verbose){
    cat(paste0("Preparation completed.\n"))
  }
}

#' @importFrom utils unzip

shinyassess_internal_prepare_www_folder <- function(pool,config){

  if(!dir.exists(config$WWWfolder)){
    dir.create(config$WWWfolder)
  }
  if(!dir.exists(file.path(config$WWWfolder,"items"))){
    dir.create(file.path(config$WWWfolder,"items"))
  }

  uniqueProjects <- unique(pool[,c("FullPath","itemName","Project")])

  for (i in 1:dim(uniqueProjects)[1]){
    if(!dir.exists(file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"]))){
      dir.create(file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"]))
    }

    unzip(uniqueProjects[i,"FullPath"],exdir=file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"]),files=c("config.json","internal.json","stimulus.json"))

    fn <- unzip(uniqueProjects[i,"FullPath"],list=T)

    if (length(fn[startsWith(fn$Name, "resources/"),"Name"])>0){
      unzip(uniqueProjects[i,"FullPath"],exdir=file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"]),files=fn[startsWith(fn$Name, "resources/"),"Name"])
    }

    if (length(fn[startsWith(fn$Name, "external-resources/"),"Name"])>0){
      unzip(uniqueProjects[i,"FullPath"],exdir=file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"]),files=fn[startsWith(fn$Name, "external-resources/"),"Name"])
    }

    if (!file.exists(file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"],"config.json"))){
      cat(paste0("File 'config.json' not found in item '", uniqueProjects[i,"Project"], "' not found.\n"))
      stop()
    } else if (!file.exists(file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"],"internal.json"))){
      cat(paste0("File 'internal.json' not found in item '", uniqueProjects[i,"Project"], "' not found.\n"))
      stop()
    } else if(!file.exists(file.path(config$WWWfolder,"items",uniqueProjects[i,"itemName"],"stimulus.json"))){
      cat(paste0("File 'stimulus.json' not found in item '", uniqueProjects[i,"Project"], "' not found.\n"))
      stop()
    }

    if (config$verbose){
      cat(paste0("Prepared CBA ItemBuilder Project File '",uniqueProjects[i,"Project"], "'.\n"))
    }

  }

}
