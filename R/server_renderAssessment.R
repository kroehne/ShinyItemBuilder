# server_renderAssessment.R

#' @import shiny
#' @importFrom jsonlite fromJSON
#' @importFrom jsonlite toJSON
#' @importFrom utils zip

#'
renderAssessment <- function(input, output, session){

  output$frame <- renderUI({

    if (assessment_env$config$verbose)
      print(paste0("Info: New Window."))

    tags$iframe(id="myiframe", class="myiframe", style="width: 100%; height: 100vh; transform: scale(1); display: inline; transform-origin: 0px 0px; position: absolute; top: 0; bottom: 0; left: 0; right: 0; border: none; margin: 0; padding: 0; overflow: hidden",
                src=paste0("./ee/index.html?sessiontype=",assessment_env$config$sessiontype,
                           "&posH=",assessment_env$config$posH,
                           "&posV=",assessment_env$config$posV,
                           "&scaling=",assessment_env$config$scaling))

  })

  observeEvent(input$ok, {
    session$sendCustomMessage("shinyassess_restart","new")
    removeModal()
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
    do.call(file.remove, list(list.files(paste0(assessment_env$config$Datafolder,"/"), full.names = TRUE)))
    runtime.data <<- list()
    session$sendCustomMessage("shinyassess_restart","new")
    removeModal()
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
        if (assessment_env$config$verbose){

          print(paste0("Info: Item Score"))
          print(shinyassess_internal_parse_ib_scoring(e$result))
        }
      }

      current_item <- assessment_env$config$navigation(assessment_env$pool, session, direction="NEXT")
      print(current_item)

      if (current_item > 0)
      {
        session$sendCustomMessage("shinyassess_navigate_to", toJSON(list(runtime=assessment_env$pool[current_item,"runtimeCompatibilityVersion"],
                                                                   item=assessment_env$pool[current_item,"itemName"],
                                                                   task=assessment_env$pool[current_item,"Task"])))

        print(paste0("Requested Item", current_item))

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
