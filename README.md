[![R-CMD-check](https://github.com/kroehne/ShinyItemBuilder/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kroehne/ShinyItemBuilder/actions/workflows/R-CMD-check.yaml)

# ShinyItemBuilder -- Use Shiny with CBA ItemBuilder Items

The R project `ShinyItemBuilder` can be used to implement computer-based assessments using the [CBA ItemBuilder](https://cba.itembuilder.de) and [R](https://www.r-project.org/)/[Shiny](https://shiny.posit.co/).  

The [CBA ItemBuilder](https://cba.itembuilder.de) is an authoring tool for designing and implementing simple and complex computer-based items that can be used without programming knowledge to create assessment content for computer-based testing. 

[R](https://www.r-project.org/)/[Shiny](https://shiny.posit.co/) is a technology to create web applications using R. Packages and functions from R can be executed on the server side. R/Shiny requires special Shiny servers, such as an account on [ShinyApps.io](https://shinyapps.io/) or the operation of a [ShinyProxy](https://www.shinyproxy.io/) server. 

Demo: 

* Install the packages `shiny`, `remotes` and `ShinyItemBuilder`:
````
# install.packages("shiny")
# install.packages("remotes")
# remotes::install_github("kroehne/ShinyItemBuilder")
````

* Run the following code in R
````
# app.R

library(shiny) 
library(ShinyItemBuilder)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig() 

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T), 
         renderAssessment)
 
````

To use your own CBA ItemBuilder-project files, create a R-Studio project, copy the CBA ItemBuilder project files into a folder `items` and run the following code in R: 

````
# app.R

library(shiny) 
library(ShinyItemBuilder)

item_pool <- getPool(path="demo01/")
assessment_config <- getConfig() 

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T), 
         renderAssessment)
 
````

This software is currently a proof-of-concept. 
