# get_resource_infos_from_ib_file.R

#' @title Get Resource Info from CBA ItemBuilder Project File
#' @description `get_resource_infos_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing resource information defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param stimulus_json_filename Internal file name in CBA ItemBuilder projects (should be "stimulus.json")
#' @return data frame with resource information
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_resource_infos_from_ib_file("ib/myproject.zip")
#' }

get_resource_infos_from_ib_file <-  function(zip_path, stimulus_json_filename = "stimulus.json") {
  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  json_file <- file.path(tmp_dir, stimulus_json_filename)
  json_data <- jsonlite::fromJSON(json_file)

  runtimeCompatibilityVersion <- json_data$runtimeCompatibilityVersion

  as.data.frame(json_data$resources, stringsAsFactors = FALSE)

}
