# parse_ib_trace.R

#' @title Parse CBA ItemBuilder Trace JSON
#' @description `parse_ib_trace` converts the JSON to a data.frame
#' @details The returned object returns a data.frame containing the trace data provided as JSON.
#' @param tracejson Trace JSON as provided by the CBA ItemBuilder runtime.
#' @return data frame with all hits and result texts
#' @examples
#' \dontrun{
#'  demo <- parse_ib_trace(json)
#' }

parse_ib_trace <- function(tracejson){

  jsonlite::fromJSON(tracejson)

}


