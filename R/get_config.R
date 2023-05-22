# get_config.R

getConfig <- function(){

  ret <- list()

  ret$WindowTitle="MyAssessment"
  ret$verbose=T
  ret$end=function(){
      showModal(modalDialog(
      title = "You Answered all Items",
      "Please close the browser / tab.",
      footer = tagList()))
  }
  ret$WWWfolder="_mywww"
  ret$Datafolder="_mydata"

  # visual presentation

  ret$posH = "center"
  ret$posV = "center"
  ret$scaling = "updown"

  ret$sessiontype = "sessionstorage"
  ret$session <- ""

  # end function

  ret$end=function(session){
    showModal(modalDialog(
      title = "You Answered all Items",
      "Please close the browser / tab.",
      footer = tagList(actionButton("ok", "Restart"))))
  }

  #ret$end=function(session){
  #  session$sendCustomMessage("shinyassess_redirect", "http://www.tagesschau.de/?1234")
  #}

  ret$navigation = function(pool, session, direction="NEXT"){

      current_item <- getValueForTestTaker(session, "current-item-index", default=1, store = F)
      if (current_item==0  && direction=="START"){
        current_item <- 1 # start the assessment
      }
      else
      {
        if (direction=="NEXT"){
          if (current_item >= dim(assessment_env$pool)[1])
          {
            current_item <- -1 # end the assessment
          }
          else
          {
            current_item <- current_item + 1 # move to the next item
          }
        }
        else if (direction=="PREVIOUS"){
          if (current_item > 0)
          {
            current_item <- -1
          }
          else
          {
            # ignore
          }
        }
        else if (direction=="CANCEL"){
          current_item <- -2 # pause the assessment
        }
      }

      print(paste0("Navigation: Current Item = ", current_item))
      setValueForTestTaker(session, "current-item-index",current_item)

      current_item
    }

  ret$menu = function(session,unvalidated=TRUE){
    showModal(dataModalDownloadDialog(session,unvalidated))
  }

  ret$maintanancePassword <- "felix"

  ret

}

dataModalDownloadDialog <- function(session, unvalidated = TRUE) {
  if (unvalidated){
    modalDialog(
      title = paste0(assessment_env$config$WindowTitle,": Maintanance"),
      passwordInput("downloadPassword", "Password", placeholder = 'Enter the *Maintanance Password*.'),
      footer = tagList(
        actionButton("validatePassword","OK"),
        modalButton("Cancel")
      )
    )
  } else {
    nfiles <- length(list.files("data/"))
    modalDialog(
      title = paste0(assessment_env$config$WindowTitle,": Maintanance"),
      p(paste0("Found ", nfiles, " data file(s).")),
      downloadButton("downloadData", "Download all data"),
      actionButton("deleteData","Delete all data"),
      footer = tagList(
        modalButton("Close")
      )
    )
  }
}
