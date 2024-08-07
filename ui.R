# used to install the old 2.13.* tensorflow version on shinyapps.io
# can be skipped if running locally
if (eval(parse(text="tensorflow::tf_version()")) != '2.13') {
  tensorflow::install_tensorflow(method = "virtualenv", version = "2.13")
}
  
library(quarto)
library(shiny)
library(bslib)
library(bsicons)
library(shinydashboard)
library(plotly)
library(EBImage)
library(keras)
library(zip)
library(stringr)
library(tidyverse)
library(ggplot2)



#specify which model should be loaded
model_name = "model_Biotechnology_20240515T120510"

q3_save_path = "outputs/q3_results_20240522T131242.RData"
load(q3_save_path)

# load in the saved model
zip_name = paste0("outputs/", model_name, ".zip")
dir_name = paste0("outputs/", model_name)
zip::unzip(zip_name, exdir = "outputs/")
yy = readRDS(paste0(dir_name, "/yy.RDS"))
model = keras::load_model_tf(dir_name)
unlink(dir_name, recursive=TRUE) # deletes unzipped folder




pairwise_1 = ggplot(original_wt_chisq_statistic_df) +
  aes(x = Original, y = WT, fill = chisq_statistic) +
  geom_tile() +
  geom_text(aes(label = round(chisq_statistic, 0))) +
  scale_fill_continuous(limits = c(0, 350)) +
  labs(y = "Original", fill = "Chi-square \nstatistic") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


pairwise_2 = ggplot(tgcrnd8_wt_chisq_statistic_df) +
  aes(x = TgCRND8, y = WT, fill = chisq_statistic) +
  geom_tile() +
  geom_text(aes(label = round(chisq_statistic, 0))) +
  scale_fill_continuous(limits = c(0, 350)) +
  labs(y = "Alzheimer's model", fill = "Chi-square \nstatistic") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text.y = element_blank(), 
        axis.ticks.y = element_blank())

pairwise_3 = ggplot(wt_wt_chisq_statistic_df) +
  aes(x = WT, y = WT2, fill = chisq_statistic) +
  geom_tile() +
  geom_text(aes(label = round(chisq_statistic, 0))) +
  scale_fill_continuous(limits = c(0, 350)) +
  labs(y = "WT", fill = "Chi-square \nstatistic") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text.y = element_blank(), 
        axis.ticks.y = element_blank())



# --------------------------Functions------------------------------------
mask_resize = function(img, img_inside, w = 50, h = 50) {
  
  img_mask = img * img_inside
  
  # then, transform the masked image to the same number of pixels, 50x50
  img_mask_resized = resize(img_mask, w, h)
  
  return(img_mask_resized)
}


extract_numbers <- function(input_string) {
  number <- gsub("\\D", "", input_string)
  
  number <- as.integer(number)
  
  return(number)
}



# --------------------------UI------------------------------------
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Cell classifier project"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "introduction", icon = icon("image")),
      menuItem("Prediction", tabName = "Prediction", icon = icon("image")),
      menuItem("Multi-cell Prediction", tabName = "newPrediction", icon = icon("image")),
      menuItem("Analysis", tabName = "analysis", icon = icon("search"))
    )
  ),
  dashboardBody(
    tabItems(
      #----------------------introduction----------
      tabItem(tabName = "introduction",
              tags$head(
                tags$style(HTML("
              .welcome-header { 
                color: #2C3E50; 
                font-size: 24px; 
                font-weight: bold;
                margin-bottom: 20px;
              }
              .description { 
                color: #34495E; 
                font-size: 18px;
                margin-bottom: 10px;
              }
              .description p { 
                margin-bottom: 15px; 
              }
              .highlight {
                color: #16A085;
                font-weight: bold;
              }
            "))
              ),
              div(class = "welcome-header", "Welcome to Our Cell Classifier!"),
              div(class = "description",
                  p("Our Shiny App performs ", span(class = "highlight", "predictions on different images"), ". It uses a convolutional neural network classifier to determine the cluster to which each cell belongs, according to the original ", a("Xenium mouse brain tiny subset dataset", href="https://www.10xgenomics.com/datasets/fresh-frozen-mouse-brain-for-xenium-explorer-demo-1-standard"), ". This kind of classifier extracts features from the image automatically, and uses these features to learn to classify cells. You can find more details about the trained CNN and other information on this Shiny app in our report."),
                  p("The application supports selecting multiple cells at once, ", span(class = "highlight", "displaying a detailed distribution of cluster predictions from the classifier"), ". This feature facilitates a comprehensive analysis of cell classifications."),
                  p("Lastly, a dynamic ", span(class = "highlight", "Heat Map"), " is provided, showcasing the distribution of different cells across various datasets. This visual representation helps illustrate data variability and clustering effectively."),
                  p("Note: this classifier was originally trained on images with cell boundary information given for masking. Uploaded images will not have defined cell boundary information, and are likely to be less accurate. Non-greyscale images will be made greyscale."),
                  p("Privacy information: please do not upload any sensitive information. Images are not permanently saved, but file names and other information may be recorded in server logs.")
              )
      ),
      tabItem(tabName = "Prediction",
              fluidRow(
                box(title = "Input", 
                    solidHeader = TRUE,
                    h2("Upload Images"),
                    fileInput("file2", 
                              "Upload an image file (.png)", 
                              multiple = TRUE, 
                              accept = c("image/png")),
                    verbatimTextOutput("fileInfo2"),
                    h2("Please select the images for prediction"),
                    uiOutput("imageSelect2"),
                    actionButton("predictBtn2", "Predict")
                ),
                column(
                  width = 6,
                  box(title = "Selected image", 
                      width = NULL,
                      solidHeader = TRUE,
                      imageOutput("displayedImage2", 
                                  width = "60px",
                                  height = "60px")),
                  box(title = "Important",
                      solidHeader = TRUE, 
                      collapsible = TRUE,
                      width = NULL,
                      status = "warning", 
                      div(class = "description", p("Even though the classifier can very be confident in its predictions, it is usually only slightly better than random chance at guessing the correct cluster."))),
                  box(title = "Predicted cluster",
                      width = NULL,
                      solidHeader = TRUE,
                      strong(textOutput("outputOfprediction2"),
                             style = "font-size: 32px"),
                      conditionalPanel(
                        condition = "output.outputOfprediction2",
                        style = "display:none;",
                        shinycssloaders::withSpinner(plotOutput("prediction_barplot")))
                  )
                )
              )
      ),
      tabItem(tabName = "newPrediction",
              fluidRow(
                box(title = "Input", 
                    solidHeader = TRUE,
                    h2("Upload Images"),
                    fileInput("file3", 
                              "Upload image files (.png)", 
                              multiple = TRUE, 
                              accept = c("image/png")),
                    verbatimTextOutput("fileInfo3"),
                    h2("Please select the image for prediction"),
                    actionButton("selectAllBtn", "Select all"),
                    actionButton("deselectAllBtn", "Deselect all"),
                    uiOutput("imageSelect3"),
                    actionButton("confirmBtn", "Confirm Selection")
                ),
                column(
                  width = 6,
                  box(title = "Predicted cluster",
                      width = NULL,
                      solidHeader = TRUE,
                      strong(textOutput("outputOfprediction3"),
                             style = "font-size: 32px"),
                      conditionalPanel(
                        condition = "output.outputOfprediction3",
                        style = "display:none;",
                        shinycssloaders::withSpinner(plotOutput("prediction_barplot3")))
                  )
                )
              )
      ),
      tabItem(tabName = "analysis",
              h2("Analysis Reports"),
              p("Click on a tile to see the corresponding prediction distributions which are being compared"),
              fluidRow(
                shinycssloaders::withSpinner(plotlyOutput("heatmap")),
                shinycssloaders::withSpinner(plotlyOutput("distribution_barplot"))
              )
      )
    )
  )
)




server <- function(input, output, session) {
  # --------------------------Create folders------------------------------------
  if (!dir.exists("Upload1")) {
    dir.create("Upload1")
  }
  if (!dir.exists(paste0("Upload2/", session$token))) {
    R.utils::copyDirectory(from = "Upload2/default", to = paste0("Upload2/", session$token))
  }
  
  # ----------------------page 2-------------------------------
  observeEvent(input$file2, {
    req(input$file2)
    for (i in 1:nrow(input$file2)) {
      file_temp <- input$file2$datapath[i]
      file_name <- input$file2$name[i]
      permanent_path <- file.path(getwd(), paste0("Upload2/", session$token), file_name)
      file.copy(file_temp, permanent_path, overwrite = TRUE)
    }
  })
  
  #-------view select images
  imageDir2 <- file.path(getwd(), paste0("Upload2/", session$token))
  
  # Monitor changes in the image directory
  imageFiles2 <- reactivePoll(1000, session,
                              checkFunc = function() {
                                file.info(imageDir2)$mtime
                              },
                              valueFunc = function() {
                                list.files(path = imageDir2, pattern = "png")
                              }
  )
  
  output$imageSelect2 <- renderUI({
    img_files2 <- imageFiles2()
    if (length(img_files2) == 0) {
      HTML("<p>No images available. Please upload images.</p>")
    } else {
      selectInput("selectedImage2", "Choose an image to predict:",
                  choices = imageFiles2(),
                  selected = imageFiles2()[1])
    }
  })
  
  #-------------------preview the image
  
  output$displayedImage2 <- renderImage({
    req(input$selectedImage2)
    filename <- file.path(getwd(), paste0("Upload2/", session$token), input$selectedImage2)
    list(src = filename, contentType = 'image/png', width = "64 px", height = "64 px", alt = "This is the selected image")
  }, deleteFile = FALSE)
  
  
  #--------------------------------------------------prediction------------------------------
  
  # predict button
  observeEvent(input$predictBtn2, {
    req(input$selectedImage2)
    print(input$selectedImage2)
    filename <- file.path(getwd(), paste0("Upload2/", session$token), input$selectedImage2)
    
    img <- png::readPNG(filename)
    img_inside <- img
    img_masked_resized <- mask_resize(img, img_inside, w = 64, h = 64)
    x = array(dim=c(1, 64, 64, 1))
    
    if (length(dim(img_masked_resized)) > 2) {
      img_masked_resized = channel(img_masked_resized, "grey")[,,1]
    }
    
    x[1,,,1] = img_masked_resized@.Data
    
    #img_array <- array_reshape(as.array(img_masked_resized), c(1, 64, 64, 1)) / 255
    input_img_array = x
    
    predictions = reactive({
      img_array = input_img_array
      model_predictions = model |> predict(img_array)
      model_predictions
    })
    
    predicted_class = reactive({
      img_array = input_img_array
      model_predictions = predictions()
      class = colnames(yy)[model_predictions |> k_argmax() |> as.array() + 1]
      class
      # result <- extract_numbers(class)
      # print(result)
    })
    
    
    #(output the prediction) for print
    output$outputOfprediction2 <- renderText({
      model_predictions = predictions()
      
      paste0("Cluster ", 
             predicted_class() |> 
               str_extract_all("\\d+") |> 
               as.numeric(),
             " (", round(max(model_predictions),2) , ")")
      
    })
    
    output$prediction_barplot = renderPlot({
      predictions_t = t(predictions())
      # todo 1:28 is temporary
      predictions_by_cluster = data.frame(x = colnames(yy) |> str_extract_all("\\d+") |> as.numeric() |> unlist() |> as.factor(), y = predictions_t)
      
      
      ggplot(predictions_by_cluster) +
        aes(x = x, y = y) +
        geom_bar(stat = "identity") +
        scale_y_continuous(limits = c(0,1)) +
        labs(x = "Cluster", y = "Probability") +
        theme_minimal()
    })
  })
  
  #--------------------------------------------------Page 3------------------------------
  if (!dir.exists(paste0("Upload3/", session$token))) {
    R.utils::copyDirectory(from = "Upload3/default", to = paste0("Upload3/", session$token))
  }
  predict_list <- list()
  
  observeEvent(input$file3, {
    req(input$file3)
    lapply(1:nrow(input$file3), function(i) {
      file_temp <- input$file3$datapath[i]
      file_name <- input$file3$name[i]
      permanent_path <- file.path(getwd(), paste0("Upload3/", session$token), file_name)
      file.copy(file_temp, permanent_path, overwrite = TRUE)
    })
  })
  
  imageDir3 <- file.path(getwd(), paste0("Upload3/", session$token))
  
  imageFiles3 <- reactivePoll(1000, session,
                              checkFunc = function() {
                                file.info(imageDir3)$mtime
                              },
                              valueFunc = function() {
                                list.files(path = imageDir3, pattern = "png")
                              }
  )
  
  output$imageSelect3 <- renderUI({
    img_files3 <- imageFiles3()
    if (length(img_files3) == 0) {
      HTML("<p>No images available. Please upload images.</p>")
    } else {
      checkboxGroupInput("selectedImage3", "Choose images to predict:",
                         choices = img_files3,
                         selected = img_files3[1])
    }
  })
  
  observeEvent(input$selectAllBtn, {
    img_files3 <- imageFiles3()
    updateCheckboxGroupInput(session, "selectedImage3", selected = img_files3)
  })
  
  observeEvent(input$deselectAllBtn, {
    updateCheckboxGroupInput(session, "selectedImage3", selected = list())
  })
  
  observeEvent(input$confirmBtn, {
    output$outputOfprediction3 <- renderText({
      paste0("Distribution of predictions")
    })
    
    selected_images <- input$selectedImage3
    if (length(selected_images) > 0) {
      print(selected_images) # Print selected images for debugging
      
      
      
      # Loop through each selected image
      for (i in seq_along(selected_images)) {
        filename <- file.path(getwd(), paste0("Upload3/", session$token), selected_images[i])
        img <- png::readPNG(filename)
        img_inside <- img
        img_masked_resized <- mask_resize(img, img_inside, w = 64, h = 64)
        
        if (length(dim(img_masked_resized)) > 2) {
          img_masked_resized = channel(img_masked_resized, "grey")[,,1]
        }
        
        # Prepare image array for prediction
        x <- array(dim = c(1, 64, 64, 1))
        x[1, , , 1] <- img_masked_resized@.Data
        
        # Assuming `model` is a pre-trained Keras model loaded in your environment
        model_predictions <- model %>% predict(x)
        
        # Get the predicted class
        class <- colnames(yy)[model_predictions |> k_argmax() |> as.array() + 1]
        print(class)
        
        # Extract numbers from the class (if necessary)
        result <- extract_numbers(class)
        # print("add result")
        # print(result)
        predict_list <- c(predict_list, result)
      }
      
      predict_list <- predict_list[!is.na(predict_list)]
      
      # 初始化数据框架，所有计数初值为0
      cluster_data <- data.frame(cluster = 1:28, count = integer(28))
      print(predict_list)
      # 更新列表中存在的簇的计数
      for (cl in unique(predict_list)) {
        cluster_data$count[cluster_data$cluster == cl] <- sum(predict_list == cl)
      }
      
      # 生成图形
      output$prediction_barplot3 <- renderPlot({
        ggplot(cluster_data, aes(x = as.factor(cluster), y = count)) +
          geom_bar(stat = "identity") +
          labs(x = "Cluster", y = "Count") +
          theme_minimal()
      })
      
    }
  })
  
  output$displayedImage3 <- renderImage({
    req(input$selectedImage3)
    # 注意，这里只显示第一张选中的图片作为示例
    filename <- file.path(getwd(), paste0("Upload3/", session$token), input$selectedImage3[1])
    list(src = filename, contentType = 'image/png', width = "64 px", height = "64 px", alt = "This is the selected image")
  }, deleteFile = FALSE)
  
  
  
  
  # ------------------------------------------------analysis -------------------------------
  heatmap_subplot = subplot(ggplotly(pairwise_1 + aes(text = chisq_statistic)),
                            ggplotly(pairwise_3),
                            ggplotly(pairwise_2))
  
  output$heatmap = renderPlotly({
    heatmap_subplot
  })
  
  # contains curveNumber, pointNumber, x, y, and z
  click_data = reactive(event_data("plotly_click"))
  
  clicked_tile = reactive({
    req(event_data("plotly_click"))
    pairwise_list = list(pairwise_1, pairwise_3, pairwise_2)
    click_location = click_data()
    
    # get x and y position in the subplot
    # (only need to consider 1 row, because only one click event)
    x = click_location[1, "x"]
    y = click_location[1, "y"]
    
    # convert curve number to index of corresponding plot
    index = (click_location[1, "curveNumber"] %/% 3) + 1
    
    # first column corresponds to the y axis text, second is x text
    # gets the levels of the column and then gets the one corresponding to the index
    # as.factor() is needed for columns with only one variable
    subplot_y = levels(pairwise_list[[index]]$data[,1] |> as.factor())[y]
    subplot_x = levels(pairwise_list[[index]]$data[,2] |> as.factor())[x]
    list(subplot_x, subplot_y)
  })
  
  
  output$distribution_barplot = renderPlotly({
    levels = c("Different 1000", "WT 2.5 months", "WT 5.7 months", "WT 13.4 months", "TgCRND8 2.5 months", "TgCRND8 5.7 months", "TgCRND8 17.9 months")
    selected = clicked_tile() |> paste(collapse = '|')
    
    p = ggplot(merged |> filter(type == "predictions", str_detect(dataset, selected))) +
      aes(x = factor(as.numeric(cluster)),
          y = count,
          fill = factor(dataset, levels = levels)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = clicked_tile() |> paste(collapse = ' and '), 
           fill = "Data",
           x = "Clusters",
           y = "Number of predictions") +
      theme_bw()
    
    ggplotly(p)
  })  
  
  session$onSessionEnded(function() {
    R.utils::removeDirectory(paste0("Upload2/", session$token), recursive = TRUE)
    R.utils::removeDirectory(paste0("Upload3/", session$token), recursive = TRUE)
  })
}




# Combine the UI and server components to create the Shiny app
shinyApp(ui = ui, server = server)






