# get_metadata_from_ib_file.R

#' @title Read Metadata in CBA ItemBuilder Project Files
#' @description `get_metadata_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing the metadata information defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param metadata_xml_filename Internal file name in CBA ItemBuilder projects (should be "metadata.xml")
#' @return data frame with all defined metadata
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_metadata_from_ib_file("ib/myproject.zip")
#' }

get_metadata_from_ib_file <- function(zip_path, metadata_xml_filename = "metadata.xml") {

  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  xml_file <- file.path(tmp_dir, metadata_xml_filename)
  xml <- xml2::read_xml(xml_file)

  dc_nodes <- xml2::xml_children(xml)

  dc_names <- xml2::xml_name(dc_nodes)
  dc_values <- xml2::xml_text(dc_nodes)

  result <- data.frame(
    field = dc_names,
    value = dc_values,
    stringsAsFactors = FALSE
  )

  return(result)
}


