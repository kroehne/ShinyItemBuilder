# get_config.R

#' @title Get configuration object
#' @description `getConfig` returns a config object required to use ShinyItemBuilder.
#' @details The returned object is a list that contains the different configurations  for an assessment using ShinyItemBuilder.
#' @param WindowTitle Title of the html browser window.
#' @param Verbose Should the package provide log information to the console?
#' @param WWWfolder Folder to store html/javascript files required to run the assessment
#' @param Datafolder Folder to store data files for started/completed assessments
#' @param posH Horizontal orientation (should be one of 'left', 'right' or 'center')
#' @param posV Vertical orientation (should be one of 'top', 'bottom' or 'center')
#' @param scaling Scaling of content (should be one of 'scale-up', 'scale-down', 'scale-up-down' or 'no-scaling')
#' @param sessiontype Session storage (should be one of 'sessionstorage', 'cookie', 'localstorage' or 'provided' )
#' @param maintenancePassword Password to access data online (no access possible if not defined).
#' @param maintenanceQuery Query string parameter name to access data online.
#' @param maintenanceKey Keyboard shortcut to access the maintenance dialog (provide a list in the following form: `list(key="X", ctrl=T, shift=F, alt=F)`)
#' @param clearPreviousTaskState If your test doesn't allow backward navigation, let Itembuilder's runtime flush previous task states when navigating forward
#' @return config object (list)
#' @export
#' @examples
#' \dontrun{
#'  conf <- getConfig()
#' }

getConfig <- function(WindowTitle="MyAssessment",
                      Verbose=FALSE,
                      WWWfolder="_mywww",
                      Datafolder="_mydata",
                      posH="center",
                      posV = "center",
                      scaling="scale-up-down",
                      sessiontype = "sessionstorage",
                      maintenancePassword = "",
                      maintenanceQuery = "maintenance",
                      maintenanceKey=list(key="x", ctrl=T, shift=F, alt=F),
                      clearPreviousTaskState=TRUE
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

  if (is.na(match(scaling,c("scale-up","scale-down","scale-up-down","no-scaling")))){
    stop("Parameter scaling should be one of 'scale-up', 'scale-down', 'scale-up-down' or 'no-scaling'.")
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
      footer = tagList(actionButton("endActionButtonOK", "Restart"))))
  }

  # navigation function

  ret$navigation = function(pool, session, direction="NEXT"){

      current_item <- getValueForTestTaker(session, "current-item-in-pool", default=1, store = F)
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

      setValueForTestTaker(session, "current-item-in-pool",current_item)

      current_item
  }


  # scoring function

  ret$score=function(pool, session, score, current_item){

  }

  # authentication functions

  ret$queryStringParameterName = "token"

  ret$login=function(session){
    showModal(modalDialog(
      tags$h2('Login'),
      tags$div('Please enter a valid token and press "OK".'),
      textInput('queryStringParameter', ''),
      footer=tagList(
        actionButton('submitLoginOK', 'OK')
      )
    ))
  }

  ret$custom_list_accounts <- sprintf("%03d", 0:99)

  ret$validate=function(token_or_login=NULL, password=NULL, config){
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


  # menu function

  ret$menu = function(session,unvalidated=TRUE){
    showModal(dataModalDownloadDialog(session,unvalidated))
  }

  # maintenance password

  ret$queryStringAdminParameterName = maintenanceQuery
  ret$maintenancePassword = maintenancePassword

  if (typeof(maintenanceKey)!="list")
    stop("Parameter maintenanceKey should be list with the elements 'key', 'alt', 'ctrl' and 'shift'.")

  if (is.null(maintenanceKey[["key"]])||is.null(maintenanceKey[["alt"]])||
      is.null(maintenanceKey[["ctrl"]])||is.null(maintenanceKey[["shift"]]))
    stop("Parameter maintenanceKey should contain non-null values for all elements 'key', 'alt', 'ctrl' and 'shift'.")

  ret$maintenanceKey = maintenanceKey

  ret$clearPreviousTaskState = clearPreviousTaskState

  ret

}

### Internal Functions ####

dataModalDownloadDialog <- function(session, unvalidated = TRUE) {
  if (unvalidated){
    modalDialog(
      title = paste0(assessment_env$config$WindowTitle,": Maintenance"),
      passwordInput("downloadPassword", "Password", placeholder = 'Enter the *Maintenance Password*.'),
      footer = tagList(
        actionButton("validatePassword","OK"),
        modalButton("Cancel")
      )
    )
  } else {
    nfiles <- length(list.files(paste0(assessment_env$config$Datafolder,"/")))
    modalDialog(
      title = paste0(assessment_env$config$WindowTitle,": Maintenance"),
      p(paste0("Found ", nfiles, " data file(s).")),
      downloadButton("downloadData", "Download all data"),
      actionButton("deleteData","Delete all data"),
      hr(),
      actionButton("endActionButtonOK","Restart current session"),
      footer = tagList(
        modalButton("Close")
      )
    )
  }
}
