# ShinyItemBuilder

The R project `ShinyItemBuilder` can be used to implement computer-based assessments using the [CBA ItemBuilder](http://cba.itembuilder.de) and [R](https://www.r-project.org/))/[Shiny](https://shiny.posit.co/).  

Example: 

````
# app.R

# install.packages("shiny")
# install.packages("remotes")
# remotes::install_github("kroehne/ShinyItemBuilder")

library(shiny) 
library(ShinyItemBuilder)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig() 

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T), 
         renderAssessment)
 
````
