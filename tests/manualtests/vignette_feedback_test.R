library(ShinyItemBuilder)
library(shiny)

item_pool <- getDemoPool("demo01")
item_pool <- item_pool[c(2,3,4),]
assessment_config <- getConfig(Verbose = T)

assessment_config$end <- function(session) {

  data <- runtime.data[[session$userData$cbasession]]
  a <- NULL
  for (d in 1:dim(data$ResultData)[1]){
    s <- parse_ib_scoring(data$ResultData[d,"Resultdata"])
    a <- rbind(a,cbind(Project=data$ResultData[d,"Project"],
                       Task=data$ResultData[d,"Task"],
                       Scope=data$ResultData[d,"Scope"],
                       s[s$Active,c("Name","ResultText")]))
  }

  template <- '---
output: html_document
---
### Your Results: A Score of `r sum(a$Name == "ScoreCorrect")`

``` {r, echo=F}
knitr::kable(a)
```
';write(template, file=paste0(session$userData$cbasession,".rmd"), append = FALSE)

  tmpfile <- rmarkdown::render(paste0(session$userData$cbasession,".rmd"))
  b64 <- base64enc::dataURI(file = tmpfile, mime = "text/html")

  if (file.exists(tmpfile))
    file.remove(tmpfile)

  if (file.exists(paste0(session$userData$cbasession,".rmd")))
    file.remove(paste0(session$userData$cbasession,".rmd"))

  showModal(modalDialog(
    title = "Feedback",
    footer = tagList(actionButton("endActionButtonOK", "Restart")),
    renderUI({
      tags$iframe(src=b64, height=400, width=550, frameBorder=0)
    }),
  ), session)
}

shinyApp(assessmentOutput(pool = item_pool,
                          config = assessment_config,
                          overwrite=T),
         renderAssessment)



