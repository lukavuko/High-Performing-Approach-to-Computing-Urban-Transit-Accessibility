library(shiny)
library(glue)
#library(stringr)

# for data table page
#library(DT)
#library(gridExtra)
#library(ggplot2)
#library(dplyr)

# for unpuervised learning page # all caused problems
#library(cluster)
#library(FactoMineR)
#library(factoextra)

#  import data for data explorer
#all_ams <- read.csv("datatable/all_data.csv")[,-c(1,2)]  # ams = accessibility measures
#sumstat_df <- read.csv("datatable/summary_statistics_by_city.csv")[,-1]

# import data for pca
#df_pca <- read.csv("datatable/pca_data.csv")
#df_pca <- data.frame(column_to_rownames(df_pca, var = "X"))
#df.num <- df_pca %>% select(where(is.numeric))
#df_pca<-fread(file.path('../../../data/3_computed', '/unsupervised_data.csv'))

# Directory paths
scoremap_dir <- "/maps/score_maps"
#kepmap_dir <- "/maps/kepler_maps/general"
isomap_dir <- "/maps/isochrone_maps"
effmap_dir <- "/maps/efficiency_maps"
kepmap_dir_time_window <- "/maps/kepler_maps/time_window"
compare_dir <- "/maps/kepler_maps/compare"

# Add resource paths, with specific resource names
addResourcePath('map_sco', paste0(getwd(), scoremap_dir))
#addResourcePath('map_kep', paste0(getwd(), kepmap_dir))
addResourcePath('map_iso', paste0(getwd(), isomap_dir)) 
addResourcePath('map_eff', paste0(getwd(), effmap_dir)) 
addResourcePath('kep_time', paste0(getwd(), kepmap_dir_time_window))
addResourcePath('kep_com', paste0(getwd(), compare_dir))

# Factor vector names
amenity_factor <- c("Library or Archives", "Gallery", "Museum", "Theatre and Concert Hall")
weight_factor <- c('no', 'yes')
nearest_n_factor <- c('1', '2', '3', 'ALL')
stops <- c('no', 'yes')
efficiency_type <- c('Continuous', 'Discrete')
day_factor <- c('Friday', 'Saturday', 'Sunday')

## Primary UI function
ui <- shinyUI(
    navbarPage("Vancouver Transit Accessibility to Cultural Amenities",

                navbarMenu("Leaflet Accessibility Visualizations", 
                           "----",
                           tabPanel("Score Percentile Measures", 
                                    div(class="outer",
                                        tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")), # styles
                                        htmlOutput('map_sco'), # leaflet html map
                                        absolutePanel(id = "title", class = "panel panel-default",
                                                      top = 20, left = 65, right = "auto", bottom = "auto",
                                                      width = "auto", height = "auto",draggable = TRUE,
                                                      h2('Score Percentile Measure')),
                                        
                                        absolutePanel(id = "controls", class = "panel panel-default",
                                                      fixed = TRUE, draggable = TRUE,
                                                      top = 70, left = "auto", right = 20, bottom = "auto",
                                                      width = 360, height = "auto",
                                                      h2("Accessibility Explorer"),
                                                      h5("Score measures are based on the worst case scenario trip time where worst case is to the average time + 2 standard deviations. A higher score corresponds to a lower transit time, although the percentile is taken to render it more interprettable."),
                                                      br(),
                                                      selectInput(inputId = "type_sco", label = "Amenity Type", choices = amenity_factor),
                                                      selectInput(inputId = "weight", label =  "Amenity Weights", choices= weight_factor),
                                                      selectInput(inputId = "nearest_n", label =  "Nearest n Amenities", choices = nearest_n_factor))
                                                      #selectInput(inputId = 'stop_sco', label = "Include Bus Stops", choices = stops)
                                                      
                            )),
                           tabPanel("Isochrone Measures",
                                    div(class="outer",
                                        tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")), # styles
                                        htmlOutput('map_iso'), # get the map
                                        absolutePanel(id = "title", class = "panel panel-default",
                                                      top = 20, left = 65, right = "auto", bottom = "auto",
                                                      width = "auto", height = "auto",draggable = TRUE,
                                                      h2('Isochrone Measure')),
                                        
                                        absolutePanel(id = "controls", class = "panel panel-default",
                                                      fixed = TRUE, draggable = TRUE,
                                                      top = 70, left = "auto", right = 20, bottom = "auto",
                                                      width = 360, height = "auto",
                                                      h2("Accessibility Explorer"),
                                                      h5("Isochrones show the time required to reach the nearest amenity."),
                                                      br(),
                                                      selectInput(inputId = "type_iso", label = "Amenity Type", choices = amenity_factor),
                                                      selectInput(inputId = 'stop_iso', label = "Include Bus Stops", choices = stops))
                            )),
                           tabPanel("Network Efficiency",
                                    div(class="outer",
                                        tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")), # styles
                                        htmlOutput('map_eff'), # get the map
                                        absolutePanel(id = "title", class = "panel panel-default",
                                                      top = 20, left = 65, right = "auto", bottom = "auto",
                                                      width = "auto", height = "auto",draggable = TRUE,
                                                      h2('Network Efficiency')),
                                        
                                        absolutePanel(id = "controls", class = "panel panel-default",
                                                      fixed = TRUE, draggable = TRUE,
                                                      top = 70, left = "auto", right = 20, bottom = "auto",
                                                      width = 360, height = "auto",
                                                      h2("Accessibility Explorer"),
                                                      h5("Efficiency is based on the difference between the accessibility score and the transit needs.
                                                         Transit needs depend on the population size, the local amenity density, and the average amount of traffic in a ~5km region."),
                                                      br(),
                                                      selectInput(inputId = 'type_eff', label = "Efficiency Type", choices = efficiency_type),
                                                      selectInput(inputId = 'stop_eff', label = "Include Bus Stops", choices = stops))
                                    ))
                ),

               navbarMenu("Kepler (3D) Accessibility Visualizations",
                          "----",
                        # exclude this tab to cut down on data required for the dashboard
                        #   tabPanel("Score Percentile Measures",
                        #            div(class="outer",
                        #                tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")),
                        #                htmlOutput('map_kep'),
                        #                absolutePanel(id = "title", class = "panel panel-default",
                        #                              top = 20, left = 65, right = "auto", bottom = "auto",
                        #                              width = "auto", height = "auto",draggable = TRUE,
                        #                              h2('Score Percentile Measure')),
                                       
                        #                absolutePanel(id = "controls", class = "panel panel-default",
                        #                              fixed = TRUE, draggable = TRUE,
                        #                              top = 70, left = "auto", right = 20, bottom = "auto",
                        #                              width = 360, height = "auto",
                        #                              h2("Accessibility Explorer"),
                        #                              h5("Score measures are based on the worst case scenario trip time where worst case is to the average time + 2 standard deviations. A higher score corresponds to a lower transit time, although the percentile is taken to render it more interprettable."),
                        #                              br(),
                        #                              selectInput(inputId = "type_kep", label = "Amenity Type", choices = amenity_factor))
                        #            )),
                          tabPanel("Weekday/Weekend Isochrone Comparison",
                                   div(class="outer",
                                       tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")), # styles
                                       htmlOutput('kep_com'),
                                       absolutePanel(id = "title", class = "panel panel-default",
                                                     top = 20, left = 65, right = "auto", bottom = "auto",
                                                     width = "auto", height = "auto",draggable = TRUE,
                                                     h2('Comparison Map for Weekend/Weekday Transit Times')),
                                       
                                       absolutePanel(id = "controls", class = "panel panel-default",
                                                     fixed = TRUE, draggable = TRUE,
                                                     top = 70, left = "auto", right = 20, bottom = "auto",
                                                     width = 360, height = "auto",
                                                     h2("Accessibility Explorer"),
                                                     h5("Isochrones show the time required to reach the nearest amenity."),
                                                     br(),
                                                     selectInput(inputId = "type_com", label = "Amenity Type", choices = amenity_factor))
                                   )),
                          tabPanel("Time of Day Isochrone Comparison",
                                   div(class="outer",
                                       tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")),# styles
                                       htmlOutput('keplertime'),
                                       absolutePanel(id = "title", class = "panel panel-default",
                                                     top = 20, left = 65, right = "auto", bottom = "auto",
                                                     width = "auto", height = "auto", draggable = TRUE,
                                                     h2('Transit Time to the Nearest Amenity')),
                                       
                                       absolutePanel(id = "controls", class = "panel panel-default",
                                                     fixed = TRUE, draggable = TRUE,
                                                     top = 60, left = "auto", right = 20, bottom = "auto",
                                                     width = 360, height = "auto",
                                                     h2("Accessibility Explorer"),
                                                     h5("Isochrones show the time required to reach the nearest amenity."),
                                                     br()
                                       ))
                          )
                          
               ),
            # excluded since dependency stack takes >15min and fails

            #    tabPanel("Unsupervised Analysis",
            #         fluidPage(align = "center",
            #             tags$div(style="margin: 20px; width: 95%; height: 95%",
                     
            #                 sidebarPanel(width = 4,
            #                     selectInput("var","Select Variables:",
            #                                 choices = colnames(df.num),
            #                                 multiple = T,
            #                                 selected=colnames(df.num))
            #                 ),
            #                 mainPanel(width = 8,
            #                     tabsetPanel(
            #                         tabPanel("Clustering",
            #                                  plotOutput("plot_cluster", height = '700px')),
            #                         tabPanel("Scree Plot",
            #                                  plotOutput("plot_scree", height = '700px')),
            #                         tabPanel("Biplot",
            #                                  plotOutput("plot_bi", height = '700px'))
            #                         # tabPanel("Correlation Plot",
            #                         #          plotOutput("plot_cor")),
            #                         # tabPanel(" Contributions Plot",
            #                         #          plotOutput("plot_con")),
            #                         # tabPanel("Individual Plot",
            #                         #          plotOutput("plot_ind")),
            #                     )
            #                 )
            #             )
            #         )
            #    ),

            # excluded since dependency stack takes >15min and fails

            #    tabPanel("Data Explorer", width = 12,
            #             tags$div(style="margin: 20px; width: 80%"),
            #             fluidRow(column(titlePanel("Welcome to the Data Explorer"), width = 4, offset = 1)),
            #             hr(),
            #             fluidRow(align = "left",
            #                 column(6, offset = 1, tags$h4("Click on rows in the data table to view accessibility distributions of that particular Vancouver City Subdivision.")),
            #                 column(2, offset = 1, 
            #                        selectInput("weights", "Weights:",
            #                                    choices=c("Yes"="yes","No"="no"),
            #                                    selected = "Yes"),
            #                        selectInput(inputId="nearest", label="Access to:",
            #                                     choices=c("All Amenities" = "avg_time_to_any_amenity",
            #                                               "Nearest Amenity" = "time_to_nearest_amenity"),
            #                                    selected = "All Amenities"))
            #             ),
            #             hr(),
            #             fluidRow(align = "center",
            #                 column(width = 9, offset = 1,
            #                        tabPanel("summary_statistics",
            #                                  DT::dataTableOutput("summary_table"),
            #                                  width = '95%'),
            #                        hr(),
            #                        plotOutput("subdivision_violin_plot", click = "plot_click",
            #                        width = '100%', height = '600px')
            #                 )
            #             ), 
                        
            #    ),

               
               tabPanel('About this Project',
                        fluidPage(align = "center", column( 12,
                        div(style="max-width:72%; text-align: center",
                            tags$head(includeCSS("styles/styles.css"), includeScript("styles/gomap.js")),
                            img(src = "headerlogo.png", style="max-width:100%;width:100%; height: 300"),
                            
                            tags$h2("Welcome!", style="font-weight: bold"),
                            tags$text("The dashboard serves as our final visualization tool for our main project, which aimed to compute and develop transit measures of accessibility to cultural amenities in Vancouver, Canada.",
                                      style="font-size:20px"),
                            
                            br(),br(),
                            tags$h2("About the Dashboard", style="font-weight: bold"),
                            tags$text("This dashboard is used to visualize accessibility to cultural amenities via the transit network in Greater Vancouver.
                            The main two measures visualized are Scores (as percentiles) and times (as modified isochrones). 
                            The Score map uses the quantiles of the raw accessibility score to show relative transit access to each amenity type with or without popularity weights and between the nearest 1,2,3 and all amenities accessible to that point. 
                            The modified isochrone maps use actual transit time to visualize travel time to the nearest selected amenity type. 
                            The network efficiency map is an experimental measure intended to compare current accessibility (scores) with estimated accessibility needs.
                            Needs are based on how many people live in the block, the amount of traffic, and the amenity density around that block, but this measure is far from being complete.
                            The closer the needs match the accessibility, the more efficiently transit resources are being distributed.
                            Regarding Kepler.gl tab as a visualization tool, it is intended to provide more
                            detailed evaluation of accessibility over different times and days since it's designed to manipulate data on the fly which leaflet does not do after the visualization is generated.",
                                      style="font-size:20px"),
                            
                            br(),br(),
                            tags$h2("About the Project (Executive Summary)", style="font-weight: bold"),
                            br(),
                            tags$h4("A High Performing, Scalable Model for Computing and Visualizing Public Transit Accessibility", style="font-size: 24px; font-family:Times, serif;"), 
                            tags$h4("A Case Study on Cultural and Art Amenities in Metro Vancouver", style="font-size: 24px; font-style: italic; font-family:Times, serif;"),
                            
                            br(),
                            tags$h3("Introduction", style="font-weight: bold"),
                            tags$text("Transportation network analysis is fundamental to urban planning for it determines how resources are distributed across a population. Resources come in the form of amenities such as grocery stores, schools, parks, and hospitals. Our client, Statistics Canada produces data to better understand Canada's population, resources, economy, society, and culture. They have previously developed network accessibility measures based on distance of driving, and walking to compute proximity scores for various types of amenities.",style="font-size:20px;"),
                            
                            br(),
                            tags$h3("Problem", style="font-weight: bold"),
                            tags$text("Accessibility measures based on time using transit have not yet been incorporated into proximity scores due to its multi-modal complexity and computational intensity. In 2016, 22.3% of Canadians depended on public transit in large cities; thus, incorporating transit accessibility measures is paramount to not under-represent large segments of the population which can inevitably worsen pre-existing inequalities in the urban landscape.",
                                      style="font-size:20px"),
                            
                            br(),
                            tags$h3("Objective", style="font-weight: bold"),
                            tags$text("The aim of this project was to establish a first iteration of an open source scalable framework for data collection and analysis of transit accessibility measures. We validated our framework on Vancouver, raising the question of, 'How accessible are Vancouver's cultural amenities (libraries, museums, art galleries, and theatres) using the current transit system?'",
                                      style="font-size:20px"),
                            
                            br(),
                            tags$h3("Methodology/Results:", style="font-weight: bold"),
                            tags$text("To address the computational intensity of multimodal shortest path routing, we use Conveyalâs R5 realistic routing algorithm available in R as r5r. It allows us to compute over 5.3 million transit routes repeatedly, 360 times in a day over 3 days, in just a matter of one hour. The travel time matrix was then used to develop three accessibility measures: one based on time, one on scores, and one on percentiles which were visualized with Leaflet and Kepler.gl and embedded in an R shiny dashboard. ", 
                                      style="font-size:20px"),
                            
                            br(),
                            tags$h3("Conclusion:", style="font-weight: bold"),
                            tags$text("This project provides a high performing and scalable framework for producing three unique transit accessibility measures for network analysis using Greater Vancouver as an initial use-case scenario. The frameworks can be further developed and adopted by urban developers to ensure equitable, sustainable, and optimal urban design for years to come.",style="font-size:20px"),
                            
                            br(),br(),
                            tags$h3("Code and more detailed information are available at ",
                            tags$a(href="https://github.com/ubco-mds-2020-labs/w2020-data599-capstone-projects-statistics-canada-transit", "Github."),
                            style="font-weight: bold"),
                            
                            br(), br(),
                            tags$h3("Authors"),
                            tags$text("Graham Kerford, Luka Vukovic, Yuxuan Cui, Rain Shen",
                                      style="font-weight: bold; font-size:20px"),
                            br(),
                            tags$text("Computer Science and Statistics", style="font-weight: 400; font-size:20px"),
                            br(),
                            tags$text("Faculty of Science, University of British Columbia", style="font-weight: 400; font-size:20px"),
                            br(),
                            tags$img(src = "logo.png", width = "550px", height = "200px")
                        )))
               )
    )
)


# primary server function for interactivity
server <- function(input, output){
    
    # functions to get html paths

    getScore_map <- reactive({ 
        amn_name <- input$type_sco
        weight <- input$weight
        nearest_n <- input$nearest_n
        html_file <- glue("{amn_name} - wt({weight}) - n({nearest_n}) - stops(yes)")
        return(glue('/{html_file}.html'))
    })
    getKepler_map <- reactive({ 
        amn_name <- input$type_kep
        html_file <-  glue('{amn_name} Score Kepler')
        return(glue('/{html_file}.html'))
    })
    getIsochrone_map <- reactive({ 
        amn_name <- input$type_iso
        stop <- input$stop_iso
        html_file <-  glue('{amn_name} - isochrone - stops({stop})')
        return(glue('/{html_file}.html'))
    })
    getEfficiency_map <- reactive({ 
        efficiency <- input$type_eff
        stop <- input$stop_eff
        html_file <-  glue('{efficiency} Efficiency - stops({stop})')
        return(glue('/{html_file}.html'))
    })
    getKepler_time <- reactive({ 
        amn_name <- input$type_kep_time
        html_file <-  "Friday_TimeWindow"
        return(glue('/{html_file}.html'))
    })
    getKepler_com <- reactive({ 
        amn_name <- input$type_com
        html_file <-  glue('{amn_name} compare')
        return(glue('/{html_file}.html'))
    })

    
    # tab rendering using the resource path names functions for retrieveing resource paths
    # allows for dynaic map calling

    # dynamic calling for leaflet score maps
    output$map_sco <- renderUI({
        tags$iframe(seamless="seamless", src=paste0('map_sco', getScore_map()),
                    style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
                    width='100%', height='100%')
    })
    
    # dynamic file calling kepler map
    # output$map_kep <- renderUI({
    #     tags$iframe(seamless="seamless", src=paste0('map_kep', getKepler_map()),
    #                 style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
    #                 width='100%', height='100%')
    # })
    
    # dynamic file calling isochrone map
    output$map_iso <- renderUI({
        tags$iframe(seamless="seamless", src=paste0('map_iso', getIsochrone_map()),
                    style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
                    width='100%', height='100%')
    })
    
    # dynamic file calling efficiency map
    output$map_eff <- renderUI({
        tags$iframe(seamless="seamless", src=paste0('map_eff', getEfficiency_map()),
                    style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
                    width='100%', height='100%') 
    })

    # dynamic file calling kepler time window map
    output$keplertime <- renderUI({
        tags$iframe(seamless="seamless", src=paste0('kep_time', getKepler_time()),
                    style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
                    width='100%', height='100%')
    })
    
   
    
    output$kep_com <- renderUI({
        tags$iframe(seamless="seamless", src=paste0('kep_com', getKepler_com()),
                    style="position: absolute; top: 0; right: 0; bottom: 0: left: 0;",
                    width='100%',
                    height='100%') # dynamic height (100%) doesn't work so I set it manually
    })
    
    # data table render output
    #output$summary_table = DT::renderDataTable({
    #    sumstat_df
    #})
    
    # plot based on the selected row shows that  total dissemination blocks
    # output$subdivision_violin_plot <- renderPlot({
        
    #     # user selected row indexing
    #     rows_selected = input$summary_table_rows_selected
        
    #     # keep subdivisions in selected rows
    #     cities_to_keep <- sumstat_df[rows_selected, 1]#$subdiv
    #     filtered_ams <- all_ams %>%
    #         filter(subdiv %in% cities_to_keep & weight == input$weights)
        
    #     # ordered legend 
    #     legend_ord_score <- levels(with(filtered_ams,
    #                                     reorder(factor(subdiv), -avg_score_to_nearest_amenity, na.rm = TRUE)))
        
    #     score_plot <- filtered_ams %>% 
    #         ggplot(aes(y = reorder(factor(subdiv), avg_score_to_nearest_amenity, na.rm = TRUE),
    #                    x = avg_score_to_nearest_amenity)) +
    #         geom_violin(aes(fill = subdiv), scale = 'width', alpha = 0.4, draw_quantiles = c(0.5), size = 0.5) + 
    #         scale_fill_discrete(breaks = legend_ord_score) +
    #         scale_x_continuous("Average Score to Nearest Amenity",limits = c(0, 0.3), breaks=c(0,0.1,0.2,0.3)) +
    #         guides(fill= guide_legend(title = 'Subdivision')) +
    #         theme_minimal() +
    #         theme(aspect.ratio = 1,
    #               text = element_text(size=20),
    #               panel.grid.major.x = element_line(colour="lightgray", size=0.05),
    #               panel.grid.major.y = element_line(colour="lightgray", size=0.05),
    #               panel.grid.minor.y = element_blank(),
    #               axis.title.y = element_blank(),
    #               axis.text.y = element_blank(),
    #               axis.ticks.y = element_blank()) 
        
        
    #     # change selected column name so it can be called as object in ggplot
    #     sub <- filtered_ams %>% select(subdiv, input$nearest)
    #     names(sub)[names(sub) == input$nearest] <- "selected_column"
        
    #     legend_ord_time <- levels(with(sub,
    #                                    reorder(factor(subdiv), selected_column, na.rm = TRUE)))
        
    #     time_plot <- sub %>%
    #         ggplot(aes(y = reorder(factor(subdiv), -selected_column, na.rm = TRUE), 
    #                    x = selected_column)) +
    #         geom_violin(aes(fill = subdiv), scale = 'width', alpha = 0.4, draw_quantiles = c(0.5), size = 0.5) +
    #         scale_fill_discrete(breaks = legend_ord_time) +
    #         scale_x_continuous(paste0(input$nearest, " (minutes)")) +
    #         guides(fill = guide_legend(title = 'Subdivision')) +
    #         theme_minimal() +
    #         theme(aspect.ratio = 1,
    #               text = element_text(size=20),
    #               panel.grid.major.x = element_line(colour="lightgray", size=0.05),
    #               panel.grid.major.y = element_line(colour="lightgray", size=0.05),
    #               panel.grid.minor.y = element_blank(),
    #               axis.title.y = element_blank(),
    #               axis.text.y = element_blank(),
    #               axis.ticks.y = element_blank())
        
    #     grid.arrange(score_plot, time_plot, ncol=2)
    # })
    
    ## Unsupervised analysis tab

    # # clustering
    # output$plot_cluster<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     df_1<- scale(df_1)
    #     # Compute k-means using 4 clusters
    #     set.seed(123)
    #     km.res <- kmeans(df_1, 4, nstart = 25)
    #     # Plot the k-means clustering
    #     fviz_cluster(km.res, df_1)+theme_minimal()
        
    # })
    
    # # bi plotlot
    # output$plot_bi<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     res.pca <- prcomp(na.omit(df_1), scale = T)
    #     fviz_pca_biplot(res.pca, repel = TRUE, select.var = list(contrib =7),
    #                     geom = c("text","point"),
    #                     col.var = "#00AFBB", # Variables color
    #                     col.ind = "#FC4E07" # Individuals color
    #                     )
    #     })
    
    # # scree
    # output$plot_scree<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     res.pca <- prcomp(na.omit(df_1), scale = T)
    #     #res.pca<-prcomp(df.st,scale = T)
    #     eig.val <- get_eigenvalue(res.pca)
    #     fviz_eig(res.pca, addlabels = TRUE, ylim = c(0, 70))
    # })
    
    # # cor plot
    # output$plot_cor<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     res.pca <- prcomp(na.omit(df_1), scale = T)
    #     var <- get_pca_var(res.pca)
    #     corrplot(var$cos2, is.corr=FALSE)
    # })
    # # contribution plot
    # output$plot_con<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     res.pca <- prcomp(na.omit(df_1), scale = T)
    #     # Contributions of variables to PC1
    #     p1<-fviz_contrib(res.pca, choice = "var", axes = 1, top = 10)
    #     # Contributions of variables to PC2
    #     p2<-fviz_contrib(res.pca, choice = "var", axes = 2, top = 10)
    #     
    #     plot_grid(p1, p2, labels = "AUTO")
    # })
    #ind plot
    # output$plot_ind<- renderPlot({
    #     df_1<-df.num%>%select(input$var)
    #     res.pca <- prcomp(na.omit(df_1), scale = T)
    #     fviz_pca_ind(res.pca,
    #                  col.ind = "cos2", # Color by the quality of representation
    #                  gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
    #                  repel = T     # Avoid text overlapping
    #     ) +xlim(-9,6)+ylim(-2,2)
    # })
    
    autoInvalidate <- reactiveTimer(10000)
    observe({
        autoInvalidate()
        cat(".")
    })
}
    
shinyApp(ui, server)
