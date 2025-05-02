# app.R

analyse_zip_content <- function(zip_path) {

  Tasks <- data.frame()
  Scoring <- data.frame()
  Metadata <- data.frame()
  Ressources <- data.frame()
  ExternalRessources <- data.frame()
  Properties <- data.frame()
  Variables <- data.frame()
  ValueMaps <- data.frame()

  Errors <- data.frame()

  tryCatch({
    Tasks <- get_stimulus_infos_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_stimulus_infos_from_ib_file", error=e$message))
  })

  tryCatch({
    Scoring <- get_scoring_info_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_scoring_info_from_ib_file", error=e$message))
  })

  tryCatch({
    Metadata <- get_metadata_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_metadata_from_ib_file", error=e$message))
  })

  tryCatch({
    Properties <- get_properties_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_properties_from_ib_file", error=e$message))
  })

  tryCatch({
    Ressources <- get_resource_infos_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_resource_infos_from_ib_file", error=e$message))
  })

  tryCatch({
    ExternalRessources <- get_external_resource_infos_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_external_resource_infos_from_ib_file", error=e$message))
  })

  tryCatch({
    Variables <- get_variable_infos_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_variable_infos_from_ib_file", error=e$message))
  })

  tryCatch({
    ValueMaps <- get_value_maps_from_ib_file(zip_path)
  }, error = function(e) {
    Errors<-rbind(Errors, data.frame(step="get_value_maps_from_ib_file", error=e$message))
  })

  list(
    Tasks = Tasks,
    Scoring = Scoring,
    Metadata = Metadata,
    Ressources = Ressources,
    ExternalRessources = ExternalRessources,
    Properties = Properties,
    Variables = Variables,
    ValueMaps = ValueMaps,
    Errors = Errors
  )

}

ui <- navbarPage(
  "ShinyItemBuilder: Inspect Project Tool (IPT)",

  tabPanel("Upload & Export",
           fluidPage(
             sidebarLayout(
               sidebarPanel(
                 fileInput("zipfile", "Upload CBA ItemBuilder-Project File", accept = ".zip"),
                 downloadButton("download_excel", "Download Tables as Excel File")
               ),
               mainPanel(
                 verbatimTextOutput("status")
               )
             )
           )
  ),

  tabPanel("Result & Output",
           fluidPage(
             uiOutput("tables_ui")
           )
  )
)


server <- function(input, output, session) {
  result_data <- reactiveVal(NULL)
  result_file <- reactiveVal(NULL)

  observeEvent(input$zipfile, {
    req(input$zipfile)
    zip_path <- input$zipfile$datapath

    tryCatch({

      result <- analyse_zip_content(zip_path)
      stopifnot(is.list(result))
      result_data(result)

      excel_path <- tempfile(fileext = ".xlsx")
      wb <- openxlsx::createWorkbook()
      for (name in names(result)) {
        openxlsx::addWorksheet(wb, name)
        openxlsx::writeData(wb, name, result[[name]])
      }
      openxlsx::saveWorkbook(wb, excel_path, overwrite = TRUE)
      result_file(excel_path)

      if (dim(result$Errors)[1] == 0) {
        output$status <- renderText("Analysis successfully completed.")
      } else {
        output$status <- renderText(paste0("Analysis completed with errors. ", dim(result$Errors)))
      }


    }, error = function(e) {
      output$status <- renderText(paste("Errors in the analysis:", e$message))
      result_data(NULL)
      result_file(NULL)
    })
  })

  output$tables_ui <- renderUI({
    req(result_data())
    tabs <- lapply(names(result_data()), function(name) {
      tabPanel(title = name, dataTableOutput(paste0("table_", name)))
    })
    do.call(tabsetPanel, tabs)
  })

  observe({
    req(result_data())
    for (name in names(result_data())) {
      local({
        tab_name <- name
        output_id <- paste0("table_", tab_name)
        output[[output_id]] <- renderDataTable({
          head(result_data()[[tab_name]], 100)
        }, options = list(pageLength = 10))
      })
    }
  })

  output$download_excel <- downloadHandler(
    filename = function() {
      paste0("Analyse_", gsub(".zip","",input$zipfile), "_",Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(result_file())
      file.copy(result_file(), file)
    }
  )
}

shinyApp(ui, server)

