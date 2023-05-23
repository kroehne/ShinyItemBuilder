# get_config.R

#' Get configuration object (currently a list) with examples
#'
#' @param WindowTitle Title of the html browser window.
#' @param Verbose Should the package provide log information to the console?
#' @param WWWfolder Folder to store html/javascript files required to run the assessment
#' @param Datafolder Folder to store data files for started/completed assessments
#' @param posH Horizontal orientation (should be one of 'left', 'right' or 'center')
#' @param posV Vertical orientation (should be one of 'top', 'bottom' or 'center')
#' @param scaling Scaling of content (should be one of 'up', 'down', 'updown' or 'none')
#' @param sessiontype Session storage (should be one of 'sessionstorage', 'cookie', 'localstorage' or 'provided' )
#' @param maintenancePassword Password to access data online (no access possible if not defined).
#' @return The value (if present) for the current test-taker (or the default value)

getConfig <- function(WindowTitle="MyAssessment",
                      Verbose=TRUE,
                      WWWfolder="_mywww",
                      Datafolder="_mydata",
                      posH="center",
                      posV = "center",
                      scaling="updown",
                      sessiontype = "sessionstorage",
                      maintenancePassword = ""
                      ){

  ret <- list()

  # window title

  ret$WindowTitle<-WindowTitle
  ret$verbose<-Verbose

  ret$WWWfolder<-WWWfolder
  ret$Datafolder=Datafolder

  # visual presentation

  if (is.na(match(posH,c("left","right","center")))){
    stop("Parameter posH should be one of 'left', 'right' or 'center'.")
  } else {
    ret$posH <- posH
  }

  if (is.na(match(posV,c("top","bottom","center")))){
    stop("Parameter posV should be one of 'top', 'bottom' or 'center'.")
  } else {
    ret$posV <- posV
  }

  if (is.na(match(scaling,c("up","down","updown","none")))){
    stop("Parameter scaling should be one of 'up', 'down', 'updown' or 'none'.")
  } else {
    ret$scaling <- scaling
  }

  # session storage

  if (is.na(match(sessiontype,c("sessionstorage","cookie","localstorage","provided")))){
    stop("Parameter sessiontype should be one of 'sessionstorage', 'cookie', 'localstorage' or 'provided'.")
  } else {
    ret$sessiontype <- sessiontype
  }


  # end function

  ret$end=function(session){
    showModal(modalDialog(
      title = "You Answered all Items",
      "Please close the browser / tab.",
      footer = tagList(actionButton("ok", "Restart"))))
  }

  #ret$end=function(){
  #  showModal(modalDialog(
  #    title = "You Answered all Items",
  #    "Please close the browser / tab.",
  #    footer = tagList()))
  #}

  #ret$end=function(session){
  #  session$sendCustomMessage("shinyassess_redirect", "http://www.any-url.com/?1234")
  #}

  # navigation function

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

      setValueForTestTaker(session, "current-item-index",current_item)

      current_item
    }

  # menu function

  ret$menu = function(session,unvalidated=TRUE){
    showModal(dataModalDownloadDialog(session,unvalidated))
  }

  # maintenance password

  ret$maintenancePassword = maintenancePassword

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
