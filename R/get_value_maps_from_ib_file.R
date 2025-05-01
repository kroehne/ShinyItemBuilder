# get_value_maps_from_ib_file.R

#' @title Extract and Parse Value Map Information from CBA ItemBuilder Project Files
#' @description `get_value_maps_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing information for value maps defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param valuemap_xml_filename Internal file name in CBA ItemBuilder projects (should be "global.cbavaluemap")
#' @return data frame with defined value maps
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_value_maps_from_ib_file("ib/myproject.zip")
#' }


get_value_maps_from_ib_file <- function(zip_path, valuemap_xml_filename = "global.cbavaluemap") {

  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  xml_file <- file.path(tmp_dir, valuemap_xml_filename)
  xml <- xml2::read_xml(xml_file)

  # Find all valueMaps
  value_maps <- xml2::xml_find_all(xml, ".//valueMaps")

  # Parse all <entries> per valueMap
  result <- purrr::map_df(value_maps, function(map_node) {
    map_name <- xml2::xml_attr(map_node, "name")
    entries <- xml2::xml_find_all(map_node, ".//entries")

    map_df(entries, function(entry) {
      attrs <- xml2::xml_attrs(entry)
      # Convert named attributes to a one-row data frame
      df <- as.data.frame(as.list(attrs), stringsAsFactors = FALSE)
      df$valueMapName <- map_name
      df
    })
  })

  return(result)
}
