# vignette_access_login01.R

library(ShinyItemBuilder)
library(shiny)

item_pool <- getDemoPool("demo01")
assessment_config <- getConfig(sessiontype="provided")

assessment_config$login=function(session){
  showModal(modalDialog(
    tags$h2('Login'),
    tags$div('Please enter a valid token and press "OK".'),
    textInput('queryStringParameter', ''),
    footer=tagList(
      actionButton('submitLoginOK', 'OK')
    )
  ))
}

assessment_config$custom_list_accounts <- c("A","B","C")

assessment_config$validate=function(token_or_login=NULL, password=NULL, config=NULL){


  if (is.null(token_or_login)||length(token_or_login)==0)
  {
    return (FALSE)
  }
  else {
    if (!is.na(match(token_or_login,config$custom_list_accounts))){
      return (TRUE)
    }
  }
  FALSE
}

shinyApp(assessmentOutput(pool = item_pool, config = assessment_config,overwrite=T),
         renderAssessment)
