# vignette_document_events.R

library(shiny)
library(ShinyItemBuilder)

item_pool <- getDemoPool(name="demo02")

assessment_config <- getConfig()

assessment_config$trace <- function(pool, session, item, e){

  tmp <- jsonlite::fromJSON(e$trace)
  for (i in 1:dim(tmp$logEntriesList)[1]){
    d <- names(tmp$logEntriesList$details[i,])[!is.na(tmp$logEntriesList$details[i,])]
    cat(paste0("Type: ", tmp$logEntriesList[i,"type"], "\n",
               "Time: ", lubridate::seconds(lubridate::ymd_hms(tmp$logEntriesList[i,"timestamp"])), "\n",
               "Details: ", length(d), " Attributes \n\n"))

  }

}

shinyApp(assessmentOutput(pool = item_pool,
         config = assessment_config,
         overwrite=T),
         renderAssessment)

