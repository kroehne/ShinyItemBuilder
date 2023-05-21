# parse_ib_trace.R

shinyassess_internal_parse_ib_trace <- function(session, e){
 
  if (assessment_env$config$verbose){
    tmp <- jsonlite::fromJSON(e$trace)
    print(tmp$logEntriesList[,c("entryId","timestamp","type")])
  }
     
  cbind(Time = Sys.time(), Tracedata = e$trace)
         
}

 
