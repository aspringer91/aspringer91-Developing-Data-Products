library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Time Series Prediction Model for San Jose Rental Rates"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            #Select apt size to predict on
            radioButtons("aptSizeSelect", label = h3("Select Apt Size"),
                         choices = list("1 Bed/1 Bath" = 1, "2 Bed/2 Bath" = 2, "Average" = 3),
                         selected = 1),
            #Select year to start the time series model from
            sliderInput("predStart",
                        "Select Start Year for Prediction",
                        min = 1999,
                        max = 2014,
                        value = 2006),
            #Select date to predict for
            dateInput("predDate", label = ("Select Date to Predict For"),
                      value = "2020-06-01",
                      min = "2017-01-01",
                      max = "2022-01-01"),
            #Display Predicted Value
            textOutput("predCaption"),
            htmlOutput("predValue")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            tabsetPanel(id = "tab",
                tabPanel("Display",
                        plotOutput("tsPlot"),
                        textOutput("plotNote")),
                tabPanel("Documentation",
                         htmlOutput("documentation"))

            )
        )
    )
))

