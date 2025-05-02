# get_variable_infos_from_ib_file.R

#' @title Extract and Parse Variable Information from CBA ItemBuilder Project Files
#' @description `get_variable_infos_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing variables defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param stimulus_json_filename Internal file name in CBA ItemBuilder projects (should be "stimulus.json")
#' @param variables_xml_file Internal file name in CBA ItemBuilder projects (should be "global.cbavariables")
#' @return data frame with property information
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_variable_infos_from_ib_file("ib/myproject.zip")
#' }

get_variable_infos_from_ib_file <-  function(zip_path, stimulus_json_filename = "stimulus.json", variables_xml_file = "global.cbavariables") {
  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  json_file <- file.path(tmp_dir, stimulus_json_filename)
  json_data <- jsonlite::fromJSON(json_file)

  runtimeCompatibilityVersion <- json_data$runtimeCompatibilityVersion

  var1 <- as.data.frame(json_data$variables, stringsAsFactors = FALSE)

  xml_file <- file.path(tmp_dir, variables_xml_file)
  xml <- xml2::read_xml(xml_file)

  variables_nodes <- xml2::xml_find_all(xml, ".//variables")

  var2 <- data.frame(
    name = xml2::xml_attr(variables_nodes, "name"),
    defaultValue = xml2::xml_attr(variables_nodes, "defaultValue"),
    stringsAsFactors = FALSE
  )

  var <- merge(var1,var2, by="name")
  return(var)

}
