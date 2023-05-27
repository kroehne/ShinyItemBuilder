# server_renderAssessment.R

#' @title Render assessment content
#' @description Function to be passed as argument to 'shinyApp(server=...)'
#' @param input Input.
#' @param output Output
#' @param session Session.
#' @return code to be used as argument to the function 'shinyApp(server=...)'
#' @import shiny
#' @importFrom jsonlite fromJSON
#' @importFrom jsonlite toJSON
#' @importFrom utils zip
#' @export
#' @examples
#' \dontrun{
#' shinyApp(assessmentOutput(pool = getDemoPool("demo01"),
#'      config = getConfig(), overwrite=T),
#'      renderAssessment)
#' }

renderAssessment <- function(input, output, session){

  output$frame <- renderUI({

    query <- shiny::parseQueryString(session$clientData$url_search)
    if (!base::is.null(query[[assessment_env$config$queryStringAdminParameterName]])) {
      value <- base_extract_parameter(query, assessment_env$config$queryStringAdminParameterName)
      if (length(value)!=0 && assessment_env$config$maintenancePassword != "" && assessment_env$config$maintenancePassword == value)
        assessment_env$config$menu(session, FALSE)
      else
        assessment_env$config$menu(session, TRUE)
    }

    if (assessment_env$config$sessiontype=="provided"){
      provided_session <- ""
      if (!base::is.null(query[[assessment_env$config$queryStringParameterName]])) {
        provided_session <- base_extract_parameter(query, assessment_env$config$queryStringParameterName)
        if (assessment_env$config$verbose)
          print(paste0("Info: New Window, " , assessment_env$config$queryStringParameterName, "=", provided_session))
      }
      if (!assessment_env$config$validate(provided_session,assessment_env$config)){
        assessment_env$config$login()
      } else {

        tags$iframe(id="myiframe", class="myiframe", style="width: 100%; height: 100vh; transform: scale(1); display: inline; transform-origin: 0px 0px; position: absolute; top: 0; bottom: 0; left: 0; right: 0; border: none; margin: 0; padding: 0; overflow: hidden",
                    src=paste0("./ee/index.html?sessiontype=",assessment_env$config$sessiontype,
                               "&posH=",assessment_env$config$posH,
                               "&posV=",assessment_env$config$posV,
                               "&scaling=",assessment_env$config$scaling,
                               "&session=",provided_session))
      }

    } else {

      if (assessment_env$config$verbose)
        print(paste0("Info: New Window."))

      tags$iframe(id="myiframe", class="myiframe", style="width: 100%; height: 100vh; transform: scale(1); display: inline; transform-origin: 0px 0px; position: absolute; top: 0; bottom: 0; left: 0; right: 0; border: none; margin: 0; padding: 0; overflow: hidden",
                  src=paste0("./ee/index.html?sessiontype=",assessment_env$config$sessiontype,
                             "&posH=",assessment_env$config$posH,
                             "&posV=",assessment_env$config$posV,
                             "&scaling=",assessment_env$config$scaling))

    }
  })

  observeEvent(input$endActionButtonOK, {
    removeModal()
    session$sendCustomMessage("shinyassess_restart","new")
  })

  observeEvent(input$validatePassword, {
    if (!is.null(input$downloadPassword) && nzchar(input$downloadPassword) &&
        input$downloadPassword == assessment_env$config$maintenancePassword &&
        assessment_env$config$maintenancePassword != "") {
      assessment_env$config$menu(session, FALSE)
    } else {
      removeModal()
    }
  })

  output$downloadData <- downloadHandler(
    filename = function() {
      paste("output", "zip", sep=".")
    },
    content = function(fname) {
      fs <- list.files(paste0(assessment_env$config$Datafolder,"/"))
      zip(zipfile=fname, files=paste0(paste0(assessment_env$config$Datafolder,"/"),fs))
    },
    contentType = "application/zip"
  )

  observeEvent(input$deleteData, {
    removeModal(session)
    do.call(file.remove, list(list.files(paste0(assessment_env$config$Datafolder,"/"), full.names = TRUE)))
    runtime.data <<- list()
    session$sendCustomMessage("shinyassess_restart","new")
  })

  observeEvent(input$submitLoginOK, {
    session$sendCustomMessage("shinyassess_redirect", paste0(session$clientData$url,"?", assessment_env$config$queryStringParameterName,"=",input$queryStringParameter))
  })

  observeEvent(input$ibevents, {
    e <- fromJSON(input$ibevents)
    if (e$eventname == "loaded")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: Player loaded (",e$cbasession,")"))

      session$userData$cbasession=e$cbasession

      current_item <- assessment_env$config$navigation(assessment_env$pool, session, direction="START")

      if (assessment_env$config$verbose)
        print(paste0("Info: Current Item for '",e$cbasession,"': ", current_item))

      if (current_item == -1){
        session$sendCustomMessage("shinyassess_iframe_visibility","none")
        assessment_env$config$end(session)
      }
      else
      {
        session$sendCustomMessage("shinyassess_iframe_visibility","block")
        session$sendCustomMessage("shinyassess_navigate_to", toJSON(list(runtime=assessment_env$pool[current_item,"runtimeCompatibilityVersion"],
                                                                   item=assessment_env$pool[current_item,"itemName"],
                                                                   task=assessment_env$pool[current_item,"Task"])))

      }

    }
    else if (e$eventname == "trace")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: Trace data provided (",e$cbasession,")"))

      runtime.data[[session$userData$cbasession]]$TraceData <<- rbind(runtime.data[[session$userData$cbasession]]$TraceData,shinyassess_internal_parse_ib_trace(session,e))

      shinyassess_internal_save_session(session)
    }
    else if (e$eventname == "score-task-back")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: Request back (",e$cbasession,")"))

      current_item <- assessment_env$config$navigation(assessment_env$pool, session, direction="PREVIOUS")

      shinyassess_internal_save_session(session)

    }
    else if (e$eventname == "score-task-next")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: Request next (",e$cbasession,")"))


      if (!is.null(e$result)){

        score <- parse_ib_scoring(e$result)

        if (assessment_env$config$verbose){
          print(paste0("Info: Item Score"))
          print(score)
        }

        current_item <- getValueForTestTaker(session, "current-item-in-pool", default=1, store = F)
        if (current_item > 0){

          assessment_env$config$score(assessment_env$pool, session, score, current_item)

          runtime.data[[session$userData$cbasession]]$ResultData <<- rbind(runtime.data[[session$userData$cbasession]]$ResultData,
                                                                           cbind(Time = Sys.time(),
                                                                                 Project =assessment_env$pool[current_item,"itemName"],
                                                                                 Task=assessment_env$pool[current_item,"Task"],
                                                                                 Scope=assessment_env$pool[current_item,"Scope"],
                                                                                 Resultdata = e$result))
        }
      }

      current_item <- assessment_env$config$navigation(assessment_env$pool, session, direction="NEXT")

      if (assessment_env$config$verbose)
        print(paste0("Info: Function 'navigation' returned next item index =  ",current_item))

      if (current_item > 0)
      {
        session$sendCustomMessage("shinyassess_navigate_to", toJSON(list(runtime=assessment_env$pool[current_item,"runtimeCompatibilityVersion"],
                                                                   item=assessment_env$pool[current_item,"itemName"],
                                                                   task=assessment_env$pool[current_item,"Task"],
                                                                   scope=assessment_env$pool[current_item,"Scope"])))
      }
      else
      {
        session$sendCustomMessage("shinyassess_iframe_visibility","none")
        assessment_env$config$end(session)
      }

    }
    else if (e$eventname == "taskSwitchRequest")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: taskSwitchRequest (",e$cbasession,", ",e$request, ")"))
    }
    else if (e$eventname == "test-administrator-menu")
    {
      if (assessment_env$config$verbose)
        print(paste0("Info: Test-administrator-menu requested (",e$cbasession,")"))

      assessment_env$config$menu(session)
    }
    else {
      print(paste0("Warning: Command not recognized -- ", e))
    }

  })

}


base_extract_parameter <- function(query_list, parameter) {
  regmatches(query_list[[parameter]], regexpr(pattern = "[^*/]+", text = query_list[[parameter]]))
}

### Internal Functions ####
