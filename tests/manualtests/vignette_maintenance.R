# vignette_maintenance.R

library(ShinyItemBuilder)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig(maintenancePassword = "secret")

shinyApp(assessmentOutput(pool = item_pool, config = assessment_config,overwrite=T),
         renderAssessment)
