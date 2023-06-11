# vignette_booklets_test.R

library(ShinyItemBuilder)
library(shiny)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig(Verbose = T)

assessment_config$navigation = function(pool, session, direction="NEXT"){

  booklets <- data.frame(Booklet = c(1,1,1,2,2,2),
                         ItemIndex=c(2,3,6,4,5,6))

  current_booklet <- getValueForTestTaker(session, "current-booklet",
                                          default=sample(unique(booklets$Booklet),1), store = T)

  current_item <- getValueForTestTaker(session, "current-item-in-pool",
                                       default=0,
                                       store = F)

  if (current_item==0  && direction=="START"){
    current_item <- booklets[booklets$Booklet==current_booklet,"ItemIndex"][1]
  }
  else
  {

    current_item_index <- which(booklets[booklets$Booklet==current_booklet,"ItemIndex"]==current_item)

    if (direction=="NEXT"){
      if (current_item_index >= length(booklets[booklets$Booklet==current_booklet,"ItemIndex"]))
      {
        current_item <- -1 # end the assessment
      }
      else
      {
        current_item_index <- current_item_index + 1 # move to the next item
        current_item <- booklets[booklets$Booklet==current_booklet,"ItemIndex"][current_item_index]
      }
    }
    else if (direction=="PREVIOUS"){
      if (current_item_index > 1){
        current_item_index <- current_item_index - 1 # move to the previous item
        current_item <- booklets[booklets$Booklet==current_booklet,"ItemIndex"][current_item_index]
      }
    }
    else if (direction=="CANCEL"){
      current_item <- -1 # end the assessment
    }
  }

  setValueForTestTaker(session, "current-item-in-pool",current_item)

  current_item
}

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T),
         renderAssessment)



