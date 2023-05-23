# test_demo01.R

library(shiny)
library(ShinyItemBuilder)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig()

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T),
         renderAssessment)


