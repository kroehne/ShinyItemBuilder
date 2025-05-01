# get_stimulus_infos_from_ib_file.R

#' @title Read Stimuls Definition from CBA ItemBuilder Project File
#' @description `get_stimulus_infos_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing the stimulus information defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param scoring_json_filename Internal file name in CBA ItemBuilder projects (should be "stimulus.json")
#' @return data frame with stimulus information
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_stimulus_infos_from_ib_file("ib/myproject.zip")
#' }

get_stimulus_infos_from_ib_file <-  function(zip_path, scoring_json_filename = "stimulus.json") {
  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  json_file <- file.path(tmp_dir, scoring_json_filename)
  json_data <- jsonlite::fromJSON(json_file)

  runtimeCompatibilityVersion <- json_data$runtimeCompatibilityVersion
  itemName <- json_data$itemName
  itemWidth <- json_data$itemWidth
  itemHeight <- json_data$itemHeight
  tasks <- json_data$tasks

  data.frame(tasks=tasks,
             runtimeCompatibilityVersion=runtimeCompatibilityVersion,
             itemName=itemName,
             itemWidth=itemWidth,
             itemHeight=itemHeight)
}
