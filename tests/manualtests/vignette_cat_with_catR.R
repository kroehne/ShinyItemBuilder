# vignette_cat_with_catR.R

library(shiny)
library(ShinyItemBuilder)
library(openxlsx)
library(catR)

item_pool <- getDemoPool("demo03")
item_pool <- item_pool[1:20,]

assessment_config <- getConfig(Verbose = T)

# read item parameter from excel file

assessment_config$itemPoolDescription <- read.xlsx(file.path(system.file("static", package = "ShinyItemBuilder"), "IBProjects/demo03/pool.xlsx"))

it.parameters <- assessment_config$itemPoolDescription[,c("A","B","C","D")]
it.parameters <- it.parameters[1:20,]

assessment_config$bank <- it.parameters
assessment_config$stop <- list(rule = c("length", "precision"), thr = c(10, 0.1))

assessment_config$score=function(pool, session, score, current_item){

  # Score response

  solved_current_item <- ifelse(length(grep("Correct",score[score$Active,1]))>0,1,0)

  # Store score and item in history

  history_items  <- getValueForTestTaker(session, "history-items",default=list(), store = F)
  setValueForTestTaker(session, "history-items", append(history_items, current_item))

  history_scores  <- getValueForTestTaker(session, "history-scores",default=list(), store = F)
  setValueForTestTaker(session, "history-scores", append(history_scores, solved_current_item))

}

assessment_config$navigation = function(pool, session, direction="NEXT"){

  # Load history

  current_item <- getValueForTestTaker(session, "current-item-in-pool", default=1, store = F)
  history_items  <- as.numeric(unlist(getValueForTestTaker(session, "history-items",default=list(), store = F)))
  history_scores  <- as.numeric(unlist(getValueForTestTaker(session, "history-scores",default=list(), store = F)))

  if ((current_item==0  && direction=="START")||
      (length(history_items) ==0)){

    # Select first item

    res <- nextItem(assessment_config$bank,theta=0, randomesque = 3, random.seed=1)
    current_item <- as.numeric(res$name)

    if (assessment_config$verbose)
      print(paste0("Selected first item: ", current_item))
  }
  else
  {
    if (direction=="NEXT"){

      # Estimate theta

      th <- thetaEst(rbind(assessment_config$bank[history_items,]), history_scores, method = "WL")
      se <- semTheta(th, rbind(assessment_config$bank[history_items,]), history_scores, method = "ML")

      # Store history

      history_th  <- getValueForTestTaker(session, "history-theta",default=list(), store = F)
      setValueForTestTaker(session, "history-theta", append(history_th, th))
      history_se  <- getValueForTestTaker(session, "history-se",default=list(), store = F)
      setValueForTestTaker(session, "history-se", append(history_se, se))

      if (assessment_config$verbose)
        print(paste0("Updated interrim estimate: theta = ", round(th,3), " (se = ", round(se,3), ")"))

      # Check test termination

      check <- checkStopRule(th = th, se = se, N = length(history_items),
                             stop = assessment_config$stop)

      if (check$decision)
      {
        current_item <- -1 # end the assessment
      }
      else
      {
        if (assessment_config$verbose)
          print(paste0("Items excluded for item selection: ", paste0(history_items, collapse = ";")))

        # Select next item

        res <- nextItem(assessment_config$bank, theta=th, out = history_items)
        current_item <- as.numeric(res$name)

        if (assessment_config$verbose)
          print(paste0("Selected item for step ", length(history_items)+1, ": ", current_item))
      }
    }
    else if (direction=="PREVIOUS"){
      # ignore
    }
    else if (direction=="CANCEL"){
      current_item <- -2 # pause the assessment
    }
  }

  setValueForTestTaker(session, "current-item-in-pool",current_item)

  current_item
}


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

  history_items  <- as.numeric(unlist(getValueForTestTaker(session, "history-items",default=list(), store = F)))
  history_scores  <- as.numeric(unlist(getValueForTestTaker(session, "history-scores",default=list(), store = F)))
  history_th  <- as.numeric(unlist(getValueForTestTaker(session, "history-theta",default=list(), store = F)))
  history_se  <- as.numeric(unlist(getValueForTestTaker(session, "history-se",default=list(), store = F)))

  template <- '---
output: html_document
---

``` {r, echo=F}
  history_b <- assessment_config$bank[history_items,"B"]
  plot(c(1,length(history_items)+1),c(-4,4),type="n",bty="n",xlab="Step (Test length)",ylab="Theta",
       main=paste0("Estimated Ability: ", round(history_th[length(history_th)],2), " (SE ", round(history_se[length(history_se)],2), ")"))
  arrows(x0=1:length(history_items), y0=history_th-history_se, x1=1:length(history_items), y1=history_th+history_se,
         code=3, angle=90, length=0.05, col="gray")
  points(1:length(history_items), history_th,type="l")
  points(1:length(history_items), history_b,type="p", pch=history_scores+1)
  legend("topleft",inset=0.1,pch=c(1,2),c("not solved","solved"),bty="n")
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
                          config = assessment_config,overwrite=T),
         renderAssessment)
