# get_scoring_info_from_ib_file.R

#' @title Parse Scoring Information in CBA ItemBuilder Project Files
#' @description `get_scoring_info_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing the scoring information defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param scoring_xml_filename Internal file name in CBA ItemBuilder projects (should be "global.cbaitemscore")
#' @return data frame with all classes and hits
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_scoring_info_from_ib_file("ib/myproject.zip")
#' }


get_scoring_info_from_ib_file <- function(zip_path, scoring_xml_filename = "global.cbaitemscore") {

  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  xml_file <- file.path(tmp_dir, scoring_xml_filename)
  xml <- xml2::read_xml(xml_file)

  item_nodes <- xml2::xml_find_all(xml, ".//itemScoreList")

  all_hit_data <- lapply(item_nodes, function(item_node) {
    task_name <- xml2::xml_attr(item_node, "name")
    hit_nodes <- xml2::xml_find_all(item_node, ".//hitList")

    data.frame(
      task = task_name,
      class = xml2::xml_attr(hit_nodes, "classProperty"),
      hit = xml2::xml_attr(hit_nodes, "name"),
      syntax = xml2::xml_attr(hit_nodes, "fileReference"),
      conditionStatus = xml2::xml_attr(hit_nodes, "conditionStatus"),
      resultText = xml2::xml_attr(hit_nodes, "resultText")
    )
  })

  result <-  dplyr::bind_rows(all_hit_data)

  all_class_data <- data.frame(lapply(item_nodes, function(item_node) {
    task_name <- xml2::xml_attr(item_node, "name")
    hit_nodes <- xml2::xml_find_all(item_node, ".//classList")

    data.frame(
      task = task_name,
      class = xml2::xml_attr(hit_nodes, "name"),
      comment = xml2::xml_attr(hit_nodes, "comment")
    )
  }))

  for (i in 1:dim(result)[1]){
    syntax_file <- file.path(tmp_dir, "scoringResources",result[i,"syntax"])
    result[i,"syntax"] <- paste0(readLines(syntax_file, warn = FALSE),collapse = "\n")
    result[i,"comment"] <- all_class_data[all_class_data$task == result[i,"task"] & all_class_data$class == result[i,"class"],"comment"]
  }

  return(result)
}
