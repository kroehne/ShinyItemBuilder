## get_pool.R

#' @title Get example item pool
#' @description Get example item pool for demonstration purposes using items included in the ShinyItemBuilder package for demonstration purposes
#' @param name Name of the example item pool (currently: "demo01").
#' @return config object (list)
#' @export
#' @examples
#' # default
#' pool <- getDemoPool("demo01")

getDemoPool <- function(name="demo01"){

  f <- file.path(system.file("static", package = "ShinyItemBuilder"), "IBProjects/")
  s <- NULL

  if (name=="demo01"){
    s <- shinyassess_internal_get_pool_from_folder(path = file.path(f,name))
  } else if (name=="demo02"){
    s <- shinyassess_internal_get_pool_from_folder(path = file.path(f,name))
  } else if (name=="demo03"){
    s <- shinyassess_internal_get_pool_from_folder(path = file.path(f,name))
  } else {
    stop(paste0("A demo with the name '",name,"' is not available."))
  }

  s
}

#' @title Get item pool
#' @description Get item pool for an assessment with ShinyItemBuilder
#' @param path Path to a folder with CBA ItemBuilder project files.
#' @param files List of files (i.e., path and file names) of CBA ItemBuilder project files.
#' @param tasks List of tasks (need to have the same length as files).
#' @param scope Scope (either single string or list of the same length as files / tasks).
#' @return config object (list)
#' @export
#' @examples
#' # default
#' pool <- getPool(path="../")


getPool <- function(path=NULL,files=NULL,tasks=NULL,scope=NULL){
  if (is.null(path) && is.null(files)){
    stop("Path to a folder with CBA ItemBuilder project files or a vector of files is required.")
  }
  if (is.null(files)){
    s <- shinyassess_internal_get_pool_from_folder(path = path)
  } else {
    if (is.null(tasks)){
      s <- shinyassess_internal_get_pool_from_list_of_files(path=path, files=files)
    } else {
      s <- shinyassess_internal_get_pool_from_list_of_files_and_tasks(path=path, files=files, tasks=tasks, scope=scope)
    }
  }
}

#getpool(files=c("HighlightingExample.zip","IBHandsonVersion96_Section3_3_2.zip","HighlightingExample.zip"),
#           tasks=c("Task01","Task01","Task01"),
#           scope=c("A","A","B"),
#           path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")


#getpool(files=c("FSMTimerExample.zip", "HitdefinitionAndANDOr.zip"),
#            path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")

#getpool(files=c("FSMTimerExample.zip", "HitdefinitionAndANDOr.zip"),
#            path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")

#getpool("C:/work/gitlab/testentwicklung-mathematik/Umsetzung/MSK_Items/Batch_1/msk_b1_a/")


### Internal Functions ####


shinyassess_internal_get_pool_from_folder <- function(path, pool=NULL){
  files <- list.files(path = path, pattern = "*.zip")
  for (f in files){
    if (is.na(match("stimulus.json",unzip(file.path(path,f), list = T)$Name))){
      warning(paste0("File '", file.path(path,f), "' is not a valid CBA ItemBuilder project file."))
    } else {
      stimuls_json_in_project <- jsonlite::fromJSON(unz(file.path(path,f) , "stimulus.json"))
      pool <- rbind(pool, data.frame(Project = f,
                                             FullPath = file.path(path,f),
                                             Task = stimuls_json_in_project$tasks, Scope = "Default",
                                             runtimeCompatibilityVersion = stimuls_json_in_project$runtimeCompatibilityVersion,
                                             itemName = stimuls_json_in_project$itemName,
                                             itemWidth = stimuls_json_in_project$itemWidth,
                                             itemHeight = stimuls_json_in_project$itemHeight))
    }
  }
  pool
}

#shinyassess_internal_get_pool_from_folder("C:/work/gitlab/testentwicklung-mathematik/Umsetzung/MSK_Items/Batch_1/msk_b1_a/")
#shinyassess_internal_get_pool_from_folder("C:/work/github/CBAItemBuilderBook/ib/9_08/items/")

shinyassess_internal_get_pool_from_list_of_files <- function(files, path = NULL, pool=NULL){

  for (f in files){

    if (!is.null(path)){
      f <- file.path(path,f)
    }

    if (is.na(match("stimulus.json",unzip(f, list = T)$Name))){
      warning(paste0("File '", f, "' is not a valid CBA ItemBuilder project file."))
    } else {
      stimuls_json_in_project <- jsonlite::fromJSON(unz(f, "stimulus.json"))
      pool <- rbind(pool, data.frame(Project = basename(f),
                                             FullPath = f, Task = stimuls_json_in_project$tasks, Scope = "Default",
                                             runtimeCompatibilityVersion = stimuls_json_in_project$runtimeCompatibilityVersion,
                                             itemName = stimuls_json_in_project$itemName,
                                             itemWidth = stimuls_json_in_project$itemWidth,
                                             itemHeight = stimuls_json_in_project$itemHeight))
    }

  }
  pool
}

#shinyassess_internal_get_pool_from_list_of_files(c("C:/work/github/CBAItemBuilderBook/ib/9_08/items/FSMTimerExample.zip",
#                                                       "C:/work/github/CBAItemBuilderBook/ib/9_08/items/HitdefinitionAndANDOr.zip"))

#shinyassess_internal_get_pool_from_list_of_files(c("FSMTimerExample.zip", "HitdefinitionAndANDOr.zip"),
#                                                      path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")



shinyassess_internal_get_pool_from_list_of_files <- function(files, path = NULL, pool=NULL){

  for (f in files){

    if (!is.null(path)){
      f <- file.path(path,f)
    }

    if (is.na(match("stimulus.json",unzip(f, list = T)$Name))){
      warning(paste0("File '", f, "' is not a valid CBA ItemBuilder project file."))
    } else {
      stimuls_json_in_project <- jsonlite::fromJSON(unz(f, "stimulus.json"))
      pool <- rbind(pool, data.frame(Project = basename(f),
                                             FullPath = f, Task = stimuls_json_in_project$tasks, Scope = "Default",
                                             runtimeCompatibilityVersion = stimuls_json_in_project$runtimeCompatibilityVersion,
                                             itemName = stimuls_json_in_project$itemName,
                                             itemWidth = stimuls_json_in_project$itemWidth,
                                             itemHeight = stimuls_json_in_project$itemHeight))
    }

  }
  pool
}

shinyassess_internal_get_pool_from_list_of_files_and_tasks <- function(files, tasks, path = NULL, scope=NULL, pool=NULL){

  if (length(files) != length(tasks)){
    stop("List of files and list of tasks must be of equal length.")
  }

  if (!is.null(scope)){
    if (length(scope) != 1 && length(scope) != length(files)){
      stop("List of scope and list of files/tasks must be of equal length.")
    }
  } else {
    scope <- "Default"
  }

  s <- scope
  for (i in 1:length(files)){

    f <- files[i]
    if (!is.null(path)){
      f <- file.path(path,f)
    }

    if (length(scope)>1){
      s <- scope[i]
    }

    if (is.na(match("stimulus.json",unzip(f, list = T)$Name))){
      warning(paste0("File '", f, "' is not a valid CBA ItemBuilder project file"))
    } else {
      stimuls_json_in_project <- jsonlite::fromJSON(unz(f, "stimulus.json"))
      if (!is.na(match(tasks[i],stimuls_json_in_project$tasks))){
        pool <- rbind(pool, data.frame(Project = basename(f),
                                               FullPath = f, Task = tasks[i], Scope = s,
                                               runtimeCompatibilityVersion = stimuls_json_in_project$runtimeCompatibilityVersion,
                                               itemName = stimuls_json_in_project$itemName,
                                               itemWidth = stimuls_json_in_project$itemWidth,
                                               itemHeight = stimuls_json_in_project$itemHeight))
      } else {
        warning(paste0("Task '", tasks[i], "' not found in file '", f, "'."))
      }

    }

  }
  pool
}

#shinyassess_internal_get_pool_from_list_of_files_and_tasks(files=c("HighlightingExample.zip","IBHandsonVersion96_Section3_3_2.zip"),
#                                                               tasks=c("Task01","Task01"),
#                                                               path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")

#shinyassess_internal_get_pool_from_list_of_files_and_tasks(files=c("HighlightingExample.zip","IBHandsonVersion96_Section3_3_2.zip","HighlightingExample.zip"),
#                                                               tasks=c("Task01","Task01","Task01"),
#                                                               scope=c("A","A","B"),
#                                                               path = "C:/work/github/CBAItemBuilderBook/ib/9_08/items/")


