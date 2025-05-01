# get_external_resource_infos_from_ib_file.R

#' @title Extract and Parse Information about External Ressources from CBA ItemBuilder Project Files
#' @description `get_external_resource_infos_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing information about external Ressources defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param stimulus_json_filename Internal file name in CBA ItemBuilder projects (should be "stimulus.json")
#' @return data frame with property information
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_external_resource_infos_from_ib_file("ib/myproject.zip")
#' }


get_external_resource_infos_from_ib_file <-  function(zip_path, stimulus_json_filename = "stimulus.json") {
  tmp_dir <- tempdir()

  if (dir.exists(file.path(tmp_dir,"external-resources/"))){
    unlink(file.path(tmp_dir,"external-resources/"), recursive = TRUE)
  }

  unzip(zip_path, exdir = tmp_dir)

  json_file <- file.path(tmp_dir, stimulus_json_filename)
  json_data <- jsonlite::fromJSON(json_file)

  runtimeCompatibilityVersion <- json_data$runtimeCompatibilityVersion

  df1 <- as.data.frame(json_data$externalResources, stringsAsFactors = FALSE)

  files <- list.files(file.path(tmp_dir,"external-resources/"), recursive = T)
  df2 <- data.frame(pathInZip=files,size=-1,type="file")
  for (i in 1:length(files)){
    fi <- file.info(file.path(tmp_dir,"external-resources/",files[i]))
    df2[i,"size"]<-fi$size
  }

  rbind(df1,df2)

}
