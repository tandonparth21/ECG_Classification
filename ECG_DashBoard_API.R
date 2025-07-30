#dataset - https://www.kaggle.com/code/viserion7/dl-ecg-final-2d/input

library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(httr)
library(jsonlite)
library(plotly)
library(DT)
library(shinyWidgets)
library(shinyjs)

api_url <- "http://127.0.0.1:8000/predict"

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = tagList(span(class = "logo-lg", "ECG Classifier"), icon("heartbeat")),
                  titleWidth = 250),
  dashboardSidebar(width = 250,
                   sidebarMenu(
                     menuItem("Dashboard", tabName = "predict", icon = icon("dashboard")),
                     menuItem("Compare with Normal", tabName = "compare", icon = icon("balance-scale")),
                     menuItem("About Classes", tabName = "about", icon = icon("info-circle")),
                     menuItem("Analysis History", tabName = "history", icon = icon("history")),
                     menuItem("Settings", tabName = "settings", icon = icon("cog"))
                   )
  ),
  dashboardBody(
    useShinyjs(),
    tabItems(
      # Dashboard tab
      tabItem(tabName = "predict",
              fluidRow(
                box(title = "ECG Image Upload", width = 4, solidHeader = TRUE, status = "primary",
                    fileInput("file", "Choose ECG Image (.png/.jpg)", accept = c('image/png', 'image/jpeg')),
                    actionButton("predict_btn", "Analyze ECG", icon = icon("magic"), class = "btn-primary"),
                    prettySwitch("auto_refresh", "Auto-refresh Results", status = "success", fill = TRUE)
                ),
                box(title = "Prediction Analysis", width = 8, solidHeader = TRUE, status = "success",
                    tabsetPanel(
                      tabPanel("Bar Plot", div(class="fadeIn", plotlyOutput("prob_plot", height = "400px"))),
                      tabPanel("Pie Chart", div(class="fadeIn", plotlyOutput("pie_plot", height = "400px"))),
                      tabPanel("Results Table", div(class="fadeIn", DTOutput("prob_table")))
                    )
                )
              ),
              fluidRow(
                infoBoxOutput("confidence_box", width = 3),
                infoBoxOutput("prediction_box", width = 3),
                infoBoxOutput("processing_time_box", width = 3)
              )
      ),
      
      # Compare with Normal tab
      tabItem(tabName = "compare",
              fluidRow(
                box(title = "Comparison with Normal ECG Profile", width=12, solidHeader=TRUE, status="warning",
                    p("This plot shows your predicted probabilities compared to a healthy person's typical ECG profile."),
                    plotlyOutput("compare_plot", height="400px")
                )
              )
      ),
      
      # About tab
      tabItem(tabName = "about",
              box(width=12, status="info", solidHeader=TRUE, title="Detailed ECG Classes Explanation",
                  h3("Understanding the Five ECG Classes"),
                  p("ECG signals can be classified into distinct heartbeat types, each providing insight into cardiac rhythm:"),
                  tags$ul(
                    tags$li(strong("Class N (Normal): "), "Represents normal sinus rhythm, where the heart beats regularly without anomalies."),
                    tags$li(strong("Class S (Supraventricular ectopic beat): "), "Premature beats originating above the heart's ventricles, often benign but sometimes linked to arrhythmias."),
                    tags$li(strong("Class V (Ventricular ectopic beat): "), "Premature beats originating in the ventricles; may indicate structural heart issues."),
                    tags$li(strong("Class F (Fusion beat): "), "Result from fusion between normal and ectopic beats; relatively rare."),
                    tags$li(strong("Class Q (Unknown beat): "), "Unclassified or ambiguous beats, often noise or rare arrhythmias.")
                  ),
                  p("These classifications help cardiologists identify potential heart issues and decide on further diagnostic steps.")
              )
      ),
      
      # History tab
      tabItem(tabName = "history",
              box(width=12, title="Prediction History", status="warning", solidHeader=TRUE,
                  DTOutput("history_table"))
      ),
      
      # Settings tab
      tabItem(tabName = "settings",
              box(width=12, title="Settings", status="primary", solidHeader=TRUE,
                  sliderInput("plot_height", "Plot Height (px):", min=300, max=800, value=400, step=50)
              )
      )
    )
  )
)

server <- function(input, output, session) {
  probs <- reactiveVal(NULL)
  history <- reactiveVal(data.frame(Timestamp=character(), TopClass=character(), Confidence=numeric(), FileName=character()))
  processing_time <- reactiveVal(NULL)
  
  observeEvent(input$predict_btn, {
    req(input$file)
    start <- Sys.time()
    res <- POST(api_url, body = list(file = upload_file(input$file$datapath)), encode = "multipart")
    processing_time(round(difftime(Sys.time(), start, units="secs"),2))
    if (res$status_code==200) {
      resp <- fromJSON(content(res, "text", encoding="UTF-8"))
      probs(resp)
      topclass <- names(which.max(unlist(resp$probabilities)))
      conf <- max(unlist(resp$probabilities))
      new_row <- data.frame(Timestamp=format(Sys.time(),"%Y-%m-%d %H:%M:%S"), TopClass=topclass, Confidence=conf, FileName=input$file$name)
      history(rbind(new_row, history()))
    } else {
      showModal(modalDialog("API call failed!"))
    }
  })
  
  # Bar plot
  output$prob_plot <- renderPlotly({
    req(probs())
    df <- data.frame(Class=names(probs()$probabilities), Prob=unlist(probs()$probabilities))
    plot_ly(df, x=~Class, y=~Prob, type='bar', text=~paste0(round(Prob*100,1),"%"), textposition='auto') %>%
      layout(title="Class Probabilities", yaxis=list(range=c(0,1)), height=input$plot_height)
  })
  
  # Pie chart
  output$pie_plot <- renderPlotly({
    req(probs())
    df <- data.frame(Class=names(probs()$probabilities), Prob=unlist(probs()$probabilities))
    plot_ly(df, labels=~Class, values=~Prob, type='pie', textinfo='label+percent') %>%
      layout(title="Class Distribution (Pie)", height=input$plot_height)
  })
  
  # Compare with normal
  output$compare_plot <- renderPlotly({
    req(probs())
    df_user <- data.frame(Class=names(probs()$probabilities), User=unlist(probs()$probabilities))
    normal_ref <- rep(0.8, length(df_user$Class)) # simulate normal ECG has high probability on N, low elsewhere
    df_user$Normal <- normal_ref / sum(normal_ref) # normalized
    
    plot_ly(df_user, x=~Class, y=~User, type='bar', name='Your ECG') %>%
      add_trace(y=~Normal, name='Normal ECG') %>%
      layout(barmode='group', title="Your ECG vs Normal ECG", yaxis=list(range=c(0,1)), height=400)
  })
  
  # Table
  output$prob_table <- renderDT({
    req(probs())
    df <- data.frame(Class=names(probs()$probabilities), Probability=round(unlist(probs()$probabilities),4))
    datatable(df, options=list(pageLength=5, dom='t'))
  })
  
  output$history_table <- renderDT({ datatable(history()) })
  
  output$confidence_box <- renderInfoBox({
    req(probs())
    infoBox("Confidence", paste0(round(max(unlist(probs()$probabilities))*100,1),"%"), icon=icon("check"), color="green", fill=TRUE)
  })
  
  output$prediction_box <- renderInfoBox({
    req(probs())
    infoBox("Top Class", names(which.max(unlist(probs()$probabilities))), icon=icon("heartbeat"), color="blue", fill=TRUE)
  })
  
  output$processing_time_box <- renderInfoBox({
    req(processing_time())
    infoBox("Time", paste0(processing_time()," sec"), icon=icon("clock"), color="purple", fill=TRUE)
  })
}

shinyApp(ui, server)
