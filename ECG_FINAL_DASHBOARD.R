# ECG Diagnostic Dashboard
# A Shiny application for ECG analysis with a mock 2D CNN model
# Features: Simulated predictions, 5-second processing with overlay, slow rendering, modern UI
# Modifications: 
# - Removed pop-out feature
# - Fixed sprintf typo
# - Risk-based color (red, yellow, green) applied only to content-wrapper background
# - Boxes remain white with black text for all risk levels
# - Fixed Plotly plots (dos_plot, donts_plot, comparison_health_plot) to stay within box boundaries

# --- Package Installation ---
required_packages <- c("shiny", "shinydashboard", "ggplot2", "plotly", "png", "grid", "reshape2", "keras")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) install.packages(pkg)
}

# --- Load Libraries ---
library(shiny)
library(shinydashboard)
library(ggplot2)
library(plotly)
library(png)
library(grid)
library(reshape2)
library(keras)

# --- UI Definition ---
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(
    title = tags$span(
      icon("heartbeat"), "ECG Diagnostic Dashboard",
      style = "font-family: 'Roboto', sans-serif; font-size: 24px; font-weight: 500;"
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("ECG Analysis", tabName = "analysis", icon = icon("heartbeat")),
      menuItem("Clinical Insights", tabName = "insights", icon = icon("book-medical")),
      menuItem("Disease Correlations", tabName = "correlations", icon = icon("chart-line")),
      menuItem("Care Tips", tabName = "care_tips", icon = icon("heart"))
    ),
    tags$style(
      HTML("
        .sidebar-menu li a {
          font-family: 'Roboto', sans-serif;
          font-size: 16px;
          font-weight: 400;
          transition: transform 0.3s, background-color 0.3s;
          padding: 12px 15px;
          border-radius: 8px;
          margin: 5px 10px;
        }
        .sidebar-menu li a:hover {
          background-color: #007bff !important;
          color: #ffffff !important;
          transform: scale(1.05);
        }
      ")
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(
        HTML('
          /* General styling */
          body, .content-wrapper {
            font-family: "Roboto", sans-serif;
            background: linear-gradient(135deg, #e6f0fa 0%, #d3cce3 100%);
            transition: background-color 0.5s;
          }
          
          /* Default box styling */
          .box {
            border-radius: 12px;
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
            background-color: #ffffff !important;
            position: relative;
            z-index: 1;
            animation: fadeIn 1s ease-in;
          }
          
          /* Text color for boxes (always black for white background) */
          .box,
          .box .box-header,
          .box .box-header *,
          .box .box-title,
          .box .box-body,
          .box .box-body *,
          .box p,
          .box li,
          .box h4,
          .box h3,
          .box ul,
          .box .shiny-html-output,
          .box .shiny-html-output *,
          .box .html-widget,
          .box .shiny-plot-output,
          .box .shiny-plot-output * {
            color: #000000 !important;
          }
          
          /* Risk-based background colors for content-wrapper */
          .content-wrapper.high-risk {
            background: linear-gradient(135deg, #ff4d4d 0%, #cc0000 100%) !important;
          }
          .content-wrapper.moderate-risk {
            background: linear-gradient(135deg, #ffeb3b 0%, #ffca28 100%) !important;
          }
          .content-wrapper.normal-risk {
            background: linear-gradient(135deg, #00e676 0%, #00c853 100%) !important;
          }
          
          /* Value box styling */
          .value-box {
            background-color: transparent !important;
          }
          .value-box *,
          .value-box h3,
          .value-box p {
            color: #000000 !important;
          }
          
          /* Plot text styling for contrast */
          .plotly .plotly-html-widget text,
          .plotly .plotly-html-widget tspan,
          .plotly .plotly-html-widget .legendtext,
          .plotly .plotly-html-widget .ticktext,
          .plotly .plotly-html-widget .title,
          .plotly .plotly-html-widget .annotation text {
            fill: #000000 !important;
            color: #000000 !important;
          }
          
          /* Constrain Plotly plots to box boundaries */
          .shiny-plot-output .plotly {
            max-width: 100% !important;
            overflow: hidden;
          }
          
          /* Processing overlay */
          .processing-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.7);
            z-index: 9999;
            justify-content: center;
            align-items: center;
            animation: fadeIn 0.5s ease-in;
          }
          .processing-content {
            background: #ffffff;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            box-shadow: 0 8px 16px rgba(0,0,0,0.3);
            max-width: 500px;
          }
          .processing-spinner {
            border: 6px solid #f3f3f3;
            border-top: 6px solid #007bff;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
          }
          .processing-message {
            font-size: 20px;
            font-weight: 500;
            color: #007bff;
            animation: pulseText 1.5s infinite;
          }
          .progress-bar-container {
            margin-top: 20px;
            width: 100%;
            background: #f3f3f3;
            border-radius: 5px;
            overflow: hidden;
          }
          .progress-bar {
            height: 10px;
            background: #007bff;
            width: 0%;
            transition: width 0.3s ease;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          @keyframes pulseText {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
          }
          
          /* Button styling */
          .btn-primary {
            border-radius: 8px;
            font-weight: 500;
            padding: 10px 20px;
            background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
            border: none;
            transition: transform 0.3s, box-shadow 0.3s;
            animation: pulseButton 2s infinite;
          }
          .btn-primary:hover {
            background: linear-gradient(135deg, #0056b3 0%, #003d80 100%);
            transform: scale(1.05);
            box-shadow: 0 6px 12px rgba(0,0,0,0.2);
          }
          @keyframes pulseButton {
            0% { box-shadow: 0 0 0 0 rgba(0,123,255,0.7); }
            70% { box-shadow: 0 0 0 10px rgba(0,123,255,0); }
            100% { box-shadow: 0 0 0 0 rgba(0,123,255,0); }
          }
          
          /* Animations */
          @keyframes fadeIn {
            0% { opacity: 0; }
            100% { opacity: 1; }
          }
        ')
      ),
      tags$link(
        href = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap",
        rel = "stylesheet"
      ),
      tags$script(
        HTML('
          // Initialize Shiny message handlers
          Shiny.addCustomMessageHandler("showProcessingOverlay", function(data) {
            const overlay = document.getElementById("processing-overlay");
            const messageEl = document.getElementById("processing-message");
            const progressBar = document.getElementById("progress-bar");
            messageEl.textContent = data.message;
            progressBar.style.width = data.progress + "%";
            overlay.style.display = "flex";
          });
          
          Shiny.addCustomMessageHandler("hideProcessingOverlay", function(data) {
            document.getElementById("processing-overlay").style.display = "none";
          });
        ')
      )
    ),
    div(
      id = "processing-overlay",
      class = "processing-overlay",
      div(
        class = "processing-content",
        div(class = "processing-spinner"),
        div(id = "processing-message", class = "processing-message"),
        div(
          class = "progress-bar-container",
          div(id = "progress-bar", class = "progress-bar")
        )
      )
    ),
    uiOutput("dynamic_background_class"),
    tabItems(
      tabItem(tabName = "analysis",
              fluidRow(
                box(
                  title = "Upload ECG Image", width = 4, solidHeader = TRUE, status = "primary",
                  fileInput("ecg_img", "Choose an ECG file", accept = c("image/png", "image/jpeg")),
                  actionButton("predict_btn", "Analyze ECG", class = "btn btn-primary")
                ),
                box(
                  title = "ECG Image", width = 8, status = "info",
                  div(class = "fade-in", plotOutput("image_plot", height = "200px"))
                )
              ),
              fluidRow(
                div(class = "fade-in", valueBoxOutput("risk_summary", width = 12))
              ),
              fluidRow(
                box(title = "Prediction Probability", width = 4, 
                    div(class = "fade-in", plotOutput("bar_plot", height = "300px"))),
                box(title = "EF Comparison", width = 4, 
                    div(class = "fade-in", plotlyOutput("ef_plot"))),
                box(title = "Risk Radar", width = 4, 
                    div(class = "fade-in", plotlyOutput("radar_plot")))
              )
      ),
      tabItem(tabName = "insights",
              fluidRow(
                box(
                  title = "Understanding LV Systolic Dysfunction", width = 12, solidHeader = TRUE, status = "primary",
                  p("LV Systolic Dysfunction (LVSD) occurs when the heart’s left ventricle is unable to pump efficiently, reducing the ejection fraction (EF)."),
                  p("EF (Ejection Fraction) is a key metric: a normal EF ranges from 55% to 70%. Values below 40% indicate significant dysfunction, while 40–55% suggest mild to moderate impairment."),
                  h4("Risk Factors:"),
                  tags$ul(
                    tags$li("Smoking: Increases vascular resistance and cardiac stress."),
                    tags$li("Obesity: Contributes to hypertension and diabetes, exacerbating LVSD."),
                    tags$li("Family History: Genetic predisposition to cardiomyopathy."),
                    tags$li("Chronic Alcohol Use: Can lead to alcoholic cardiomyopathy.")
                  ),
                  h4("Diagnostic Methods:"),
                  tags$ul(
                    tags$li("ECG: Detects arrhythmias and ischemic changes."),
                    tags$li("Echocardiography: Measures EF and ventricular function."),
                    tags$li("Cardiac MRI: Provides detailed imaging of heart tissue.")
                  ),
                  h4("Treatment Options:"),
                  tags$ul(
                    tags$li("Medications: ACE inhibitors, beta-blockers, and diuretics to manage symptoms."),
                    tags$li("Lifestyle Changes: Low-sodium diet, regular exercise, and smoking cessation."),
                    tags$li("Surgical Interventions: Implantable defibrillators or coronary artery bypass in severe cases.")
                  )
                )
              ),
              fluidRow(
                box(title = "Risk Factor Distribution", width = 6, plotlyOutput("risk_factor_pie")),
                box(title = "ECG Comparison", width = 6, plotlyOutput("comparison_chart"))
              )
      ),
      tabItem(tabName = "correlations",
              fluidRow(
                box(
                  title = "LVSD and Comorbidities", width = 12, solidHeader = TRUE, status = "primary",
                  p("LV Systolic Dysfunction (LVSD) is often associated with other cardiovascular and metabolic conditions."),
                  p("Common comorbidities include:"),
                  tags$ul(
                    tags$li("Hypertension: Increases cardiac workload, contributing to ventricular dysfunction."),
                    tags$li("Diabetes: Impairs cardiac muscle function through metabolic stress."),
                    tags$li("Coronary Artery Disease (CAD): Reduces blood flow, leading to myocardial damage."),
                    tags$li("Heart Failure: Often a consequence of chronic LVSD.")
                  ),
                  p("Upload an ECG and click 'Analyze ECG' to see patient-specific prevalence.")
                )
              ),
              fluidRow(
                box(title = "Comorbidity Prevalence", width = 6, plotlyOutput("comorbidity_bar")),
                box(title = "Interpretation", width = 6, solidHeader = TRUE, uiOutput("comorbidity_interpretation"))
              )
      ),
      tabItem(tabName = "care_tips",
              fluidRow(
                box(
                  title = "Care Tips for LVSD", width = 12, solidHeader = TRUE, status = "primary",
                  p("Managing LV Systolic Dysfunction (LVSD) involves lifestyle changes and adherence to medical advice."),
                  h4("Do’s:"),
                  tags$ul(
                    tags$li("Follow a low-sodium diet to reduce fluid retention and blood pressure."),
                    tags$li("Engage in moderate exercise, like walking, as advised by your doctor."),
                    tags$li("Take prescribed medications (e.g., ACE inhibitors, beta-blockers) regularly."),
                    tags$li("Monitor your weight daily to detect fluid buildup early."),
                    tags$li("Reduce stress through relaxation techniques like meditation.")
                  ),
                  h4("Don’ts:"),
                  tags$ul(
                    tags$li("Don’t smoke, as it worsens heart function and vascular health."),
                    tags$li("Don’t consume excessive alcohol, which can weaken heart muscle."),
                    tags$li("Don’t eat high-sodium foods, as they increase blood pressure."),
                    tags$li("Don’t skip medications, as this can worsen symptoms."),
                    tags$li("Don’t ignore symptoms like shortness of breath or swelling; contact your doctor.")
                  )
                )
              ),
              fluidRow(
                box(title = "Impact of Do’s", width = 4, plotlyOutput("dos_plot", height = "250px")),
                box(title = "Impact of Don’ts", width = 4, plotlyOutput("donts_plot", height = "250px")),
                box(title = "Health Comparison", width = 4, plotlyOutput("comparison_health_plot", height = "250px"))
              )
      )
    )
  )
)

# --- SERVER ---
server <- function(input, output, session) {
  
  # Reactive values
  prediction_result <- reactiveVal(NULL)
  image_path <- reactiveVal(NULL)
  processing_state <- reactiveVal(FALSE)
  
  # Dynamic background class
  output$dynamic_background_class <- renderUI({
    req(prediction_result())
    prob <- prediction_result()$prob
    risk_class <- if (prob > 50) "high-risk" else if (prob > 30) "moderate-risk" else "normal-risk"
    message("Predicted probability: ", prob, " | Risk class: ", risk_class)
    tags$script(HTML(sprintf("
      document.querySelector('.content-wrapper').classList.remove('high-risk', 'moderate-risk', 'normal-risk');
      document.querySelector('.content-wrapper').classList.add('%s');
    ", risk_class)))
  })
  
  # Simulated comorbidity data
  disease_data <- reactive({
    req(prediction_result())
    diseases <- c("LVSD", "Hypertension", "Diabetes", "CAD", "Heart Failure")
    prob <- prediction_result()$prob
    base_prevalence <- c(60, 45, 55, 70)
    prevalence_adjust <- ifelse(prob > 50, 10, -5)
    adjusted_prevalence <- pmin(100, pmax(0, base_prevalence + prevalence_adjust))
    
    list(
      prevalence = data.frame(
        Disease = diseases[-1],
        Prevalence = adjusted_prevalence
      )
    )
  })
  
  # Mock CNN prediction function
  mock_cnn_predict <- function(image_path) {
    prob <- round(runif(1, 10, 90), 2)
    if (prob > 50) {
      ef_patient <- round(runif(1, 20, 40), 2)
      status <- "High Risk: Impaired EF (<40%)"
    } else if (prob > 30) {
      ef_patient <- round(runif(1, 40, 55), 2)
      status <- "Moderate Risk: Mild Dysfunction"
    } else {
      ef_patient <- round(runif(1, 55, 70), 2)
      status <- "Normal/Low Risk: Normal EF"
    }
    ef_normal <- 65
    list(prob = prob, summary = status, ef_patient = ef_patient, ef_normal = ef_normal)
  }
  
  # Handle ECG analysis
  observeEvent(input$predict_btn, {
    req(input$ecg_img)
    image_path(input$ecg_img$datapath)
    processing_state(TRUE)
    
    # Show overlay
    session$sendCustomMessage("showProcessingOverlay", list(
      message = "Loading pre-trained 2D CNN model from 'ecg_2d_cnn.h5'...",
      progress = 20
    ))
    Sys.sleep(1)
    
    session$sendCustomMessage("showProcessingOverlay", list(
      message = "Preprocessing ECG image for 2D CNN input...",
      progress = 50
    ))
    Sys.sleep(2)
    
    session$sendCustomMessage("showProcessingOverlay", list(
      message = "Generating prediction using 2D CNN model...",
      progress = 80
    ))
    Sys.sleep(2)
    
    prediction <- mock_cnn_predict(image_path())
    prediction_result(prediction)
    
    session$sendCustomMessage("showProcessingOverlay", list(
      message = sprintf("Prediction complete: Probability = %s%%", prediction$prob),
      progress = 100
    ))
    Sys.sleep(1)
    
    # Hide overlay
    session$sendCustomMessage("hideProcessingOverlay", list())
    processing_state(FALSE)
  })
  
  # Render ECG image
  output$image_plot <- renderPlot({
    req(image_path())
    Sys.sleep(0.5)
    img <- readPNG(image_path())
    grid.raster(img)
  })
  
  # Risk summary
  output$risk_summary <- renderValueBox({
    req(prediction_result())
    Sys.sleep(0.5)
    valueBox(
      prediction_result()$summary,
      paste("Predicted Probability:", prediction_result()$prob, "%"),
      icon = icon("exclamation-triangle"),
      color = ifelse(prediction_result()$prob > 50, "red", ifelse(prediction_result()$prob > 30, "yellow", "green"))
    )
  })
  
  # Prediction probability bar plot
  output$bar_plot <- renderPlot({
    req(prediction_result())
    Sys.sleep(0.5)
    df <- data.frame(Label = "Probability", Value = prediction_result()$prob)
    ggplot(df, aes(x = Label, y = Value)) +
      geom_col(fill = ifelse(prediction_result()$prob > 50, "#ff4d4d", ifelse(prediction_result()$prob > 30, "#ffca28", "#00c853"))) +
      ylim(0, 100) +
      geom_text(aes(label = paste0(Value, "%")), vjust = -0.5, size = 5, colour = "#000000") +
      theme_minimal(base_family = "Roboto") +
      labs(title = "Prediction Probability", y = "Probability (%)", x = "") +
      theme(
        plot.title = element_text(colour = "#000000"),
        axis.title = element_text(colour = "#000000"),
        axis.text = element_text(colour = "#000000")
      )
  })
  
  # EF comparison gauge
  output$ef_plot <- renderPlotly({
    req(prediction_result())
    Sys.sleep(0.5)
    plot_ly(
      type = 'indicator',
      mode = 'gauge+number+delta',
      value = prediction_result()$ef_patient,
      delta = list(reference = prediction_result()$ef_normal),
      title = list(text = "Ejection Fraction (%)", font = list(family = "Roboto", color = "#000000")),
      gauge = list(
        axis = list(range = list(0, 100), tickfont = list(color = "#000000")),
        bar = list(color = "#007bff"),
        steps = list(
          list(range = c(0, 40), color = "#ff4d4d"),
          list(range = c(40, 55), color = "#ffca28"),
          list(range = c(55, 100), color = "#00c853")
        )
      )
    ) %>% layout(
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#007bff")
    )
  })
  
  # Risk radar plot
  output$radar_plot <- renderPlotly({
    req(prediction_result())
    Sys.sleep(0.5)
    metrics <- data.frame(
      Parameter = c("Heart Rate Variability", "QRS Width", "ST Deviation", "QT Interval", "EF Score"),
      Value = c(65, 45, 35, 60, prediction_result()$prob)
    )
    plot_ly(
      type = 'scatterpolar',
      r = metrics$Value,
      theta = metrics$Parameter,
      fill = 'toself',
      fillcolor = 'rgba(0,123,255,0.3)',
      line = list(color = '#007bff')
    ) %>% layout(
      polar = list(radialaxis = list(visible = TRUE, range = c(0,100), tickfont = list(color = "#000000"))),
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#007bff")
    )
  })
  
  # ECG comparison chart
  output$comparison_chart <- renderPlotly({
    req(prediction_result())
    Sys.sleep(0.5)
    df <- data.frame(
      Category = c("Patient EF", "Normal EF"),
      EF = c(prediction_result()$ef_patient, prediction_result()$ef_normal)
    )
    plot_ly(df, x = ~Category, y = ~EF, type = 'bar', marker = list(color = c('#ff4d4d', '#00c853'))) %>%
      layout(
        font = list(family = "Roboto", color = "#000000"),
        xaxis = list(title = "", tickfont = list(color = "#000000")),
        yaxis = list(title = "Ejection Fraction (%)", tickfont = list(color = "#000000")),
        autosize = TRUE,
        margin = list(l = 50, r = 50, t = 50, b = 50),
        hoverlabel = list(bgcolor = "#007bff")
      )
  })
  
  # Risk factor pie chart
  output$risk_factor_pie <- renderPlotly({
    Sys.sleep(0.5)
    df <- data.frame(
      RiskFactor = c("Smoking", "Obesity", "Family History", "Alcohol Use"),
      Proportion = c(30, 25, 20, 25)
    )
    plot_ly(df, labels = ~RiskFactor, values = ~Proportion, type = 'pie',
            marker = list(colors = c('#ff4d4d', '#ffca28', '#00c853', '#007bff'))) %>%
      layout(
        title = list(text = "Risk Factor Distribution", font = list(family = "Roboto", color = "#000000")),
        font = list(family = "Roboto", color = "#000000"),
        autosize = TRUE,
        margin = list(l = 50, r = 50, t = 50, b = 50),
        hoverlabel = list(bgcolor = "#007bff")
      )
  })
  
  # Comorbidity bar chart
  output$comorbidity_bar <- renderPlotly({
    req(disease_data())
    Sys.sleep(0.5)
    df <- disease_data()$prevalence
    plot_ly(
      df,
      x = ~Disease,
      y = ~Prevalence,
      type = "bar",
      marker = list(color = "#6f42c1")
    ) %>% layout(
      title = list(text = "Comorbidity Prevalence", font = list(family = "Roboto", color = "#000000")),
      yaxis = list(title = "Prevalence (%)", range = c(0, 100), tickfont = list(color = "#000000")),
      xaxis = list(title = "", tickfont = list(color = "#000000")),
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#6f42c1")
    )
  })
  
  # Comorbidity interpretation
  output$comorbidity_interpretation <- renderUI({
    req(disease_data())
    Sys.sleep(0.5)
    df <- disease_data()$prevalence
    prob <- prediction_result()$prob
    risk_level <- ifelse(prob > 50, "high", ifelse(prob > 30, "moderate", "normal/low"))
    
    bullets <- lapply(1:nrow(df), function(i) {
      disease <- df$Disease[i]
      prevalence <- df$Prevalence[i]
      interpretation <- switch(
        disease,
        "Hypertension" = sprintf("Hypertension prevalence is %s%%, indicating %s likelihood of increased cardiac workload.", prevalence, ifelse(prevalence > 60, "elevated", "typical")),
        "Diabetes" = sprintf("Diabetes prevalence is %s%%, suggesting %s risk of metabolic stress on the heart.", prevalence, ifelse(prevalence > 50, "heightened", "standard")),
        "CAD" = sprintf("Coronary Artery Disease prevalence is %s%%, reflecting %s risk of reduced blood flow.", prevalence, ifelse(prevalence > 60, "significant", "moderate")),
        "Heart Failure" = sprintf("Heart Failure prevalence is %s%%, indicating %s likelihood of chronic LVSD progression.", prevalence, ifelse(prevalence > 70, "high", "expected"))
      )
      tags$li(interpretation)
    })
    
    tagList(
      h4("Interpretation:"),
      p(sprintf("Based on ECG analysis (probability: %s%%, %s risk), comorbidity prevalence:", prob, risk_level)),
      tags$ul(bullets)
    )
  })
  
  # Do's impact plot
  output$dos_plot <- renderPlotly({
    Sys.sleep(0.5)
    df <- data.frame(
      Action = c("Low-Sodium Diet", "Moderate Exercise", "Medication Adherence", "Weight Monitoring", "Stress Reduction"),
      Impact = c(80, 70, 90, 65, 60)
    )
    plot_ly(
      df,
      x = ~Action,
      y = ~Impact,
      type = "bar",
      marker = list(color = "#00c853")
    ) %>% layout(
      title = list(text = "Positive Impact of Do’s", font = list(family = "Roboto", color = "#000000")),
      yaxis = list(title = "Impact Score (0-100)", range = c(0, 100), tickfont = list(color = "#000000")),
      xaxis = list(title = "", tickfont = list(color = "#000000")),
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#00c853")
    )
  })
  
  # Don'ts impact plot
  output$donts_plot <- renderPlotly({
    Sys.sleep(0.5)
    df <- data.frame(
      Action = c("Smoking", "Excessive Alcohol", "High-Sodium Foods", "Skipping Medications", "Ignoring Symptoms"),
      Impact = c(80, 70, 75, 85, 90)
    )
    plot_ly(
      df,
      x = ~Action,
      y = ~Impact,
      type = "bar",
      marker = list(color = "#ff4d4d")
    ) %>% layout(
      title = list(text = "Negative Impact of Don’ts", font = list(family = "Roboto", color = "#000000")),
      yaxis = list(title = "Impact Score (0-100)", range = c(0, 100), tickfont = list(color = "#000000")),
      xaxis = list(title = "", tickfont = list(color = "#000000")),
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#ff4d4d")
    )
  })
  
  # Health comparison plot
  output$comparison_health_plot <- renderPlotly({
    Sys.sleep(0.5)
    df <- data.frame(
      Category = c("LVSD (Following Do’s)", "LVSD (Ignoring Don’ts)", "Normal Person"),
      EF = c(50, 30, 65),
      SymptomSeverity = c(20, 60, 10)
    )
    plot_ly(
      df,
      x = ~Category,
      y = ~EF,
      name = "Ejection Fraction (%)",
      type = "bar",
      marker = list(color = "#007bff")
    ) %>% add_trace(
      y = ~SymptomSeverity,
      name = "Symptom Severity (0-100)",
      x = ~Category,
      marker = list(color = "#ff4d4d")
    ) %>% layout(
      title = list(text = "Health Metrics: LVSD vs. Normal", font = list(family = "Roboto", color = "#000000")),
      yaxis = list(title = "Score", tickfont = list(color = "#000000")),
      xaxis = list(title = "", tickfont = list(color = "#000000")),
      barmode = "group",
      font = list(family = "Roboto", color = "#000000"),
      autosize = TRUE,
      margin = list(l = 50, r = 50, t = 50, b = 50),
      hoverlabel = list(bgcolor = "#007bff")
    )
  })
}

# --- Run App ---
shinyApp(ui, server)