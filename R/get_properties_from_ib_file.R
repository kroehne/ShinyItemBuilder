# get_properties_from_ib_file.R

#' @title Extract and Parse Property Information from CBA ItemBuilder Project Files
#' @description `get_properties_from_ib_file` inspects a single CBA ItemBuilder project file
#' @details The returned object is a data.frame containing properties defined in a CBA ItemBuilder project file
#' @param zip_path Reference to the CBA ItemBuilder project file (relative path of the ZIP archive including the file name)
#' @param properties_filename Internal file name in CBA ItemBuilder projects (should be "project.properties")
#' @return data frame with property information
#' @export
#' @examples
#' \dontrun{
#'  demo <- get_properties_from_ib_file("ib/myproject.zip")
#' }


get_properties_from_ib_file <- function(zip_path, properties_filename = "project.properties") {

  tmp_dir <- tempdir()
  unzip(zip_path, exdir = tmp_dir)

  txt_file <- file.path(tmp_dir, properties_filename)
  lines <- readLines(txt_file, warn = FALSE)

  lines <- lines[grepl("^[^#].*=.*", lines)]

  key_values <- strsplit(lines, "=", fixed = TRUE)

  result <- do.call(rbind, lapply(key_values, function(kv) {
    key <- trimws(kv[1])
    value <- paste(kv[-1], collapse = "=")  # Falls "=" im Value vorkommt
    value <- trimws(value)
    return(data.frame(key = key, value = value, stringsAsFactors = FALSE))
  }))

  return(result)
}
