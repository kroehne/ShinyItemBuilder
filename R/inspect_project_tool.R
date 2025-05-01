#' inspect_project_tool.R
#'
#' This function starts the "inspect-project-tool" (ipt, a shiny app included in ShinyItemBuilder)
#' @export
inspect_project_tool <- function() {
  app_dir <- system.file("ipt", package = "ShinyItemBuilder")
  if (app_dir == "") stop("Folder not found.", call. = FALSE)
  shiny::runApp(app_dir, display.mode = "normal")
}

