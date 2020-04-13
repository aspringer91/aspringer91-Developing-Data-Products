library(shiny)
library(data.table)
library(zoo)
library(stringr)
library(ggplot2)
library(forecast)
library(plotly)
# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    df <- fread("quarterly_apt_rent.csv")
    names(df) <- c("Quarter", "Average","One_One","Two_Two")
    df[, c("Average", "One_One", "Two_Two") := list(str_remove(Average, ","),
                                                    str_remove(One_One,","),
                                                    str_remove(Two_Two, ","))]

    df[, c("Average", "One_One", "Two_Two") := list(as.numeric(Average),
                                                    as.numeric(One_One),
                                                    as.numeric(Two_Two))]
    df[, Quarter := as.yearqtr(Quarter)]

    #make time series
    selectedTs <- reactive ({
        if(input$aptSizeSelect == 1) {
            ts(df[,"One_One"], start=c(1999,1),end=c(2016,2),frequency=4)
        } else if(input$aptSizeSelect == 2) {
            ts(df[,"Two_Two"], start=c(1999,1),end=c(2016,2),frequency=4)
        } else if(input$aptSizeSelect == 3) {
            ts(df[,"Average"], start=c(1999,1),end=c(2016,2),frequency=4)
        }
    })

    #Gather User Input
    predStart <- reactive({input$predStart})
    predDate <- reactive({as.yearqtr(as.Date(input$predDate))})

    #Make time series prediction window
    selectTsWindow <- reactive({window(selectedTs(), start = predStart(), end=2016.50)})
    #Number of Periods to Predict
    predPeriods <- reactive({(predDate() - as.yearqtr("2016 Q2")) * 4})
    #Create Prediction Model
    hwFit <- reactive({hw(selectTsWindow(), h=predPeriods())})

    output$tsPlot <- renderPlot({

        titleText <-
            if(input$aptSizeSelect == 1) {
                "1 Bed/1 Bath"
            } else if(input$aptSizeSelect == 2) {
                "2 Bed/2 Bath"
            } else if(input$aptSizeSelect == 3) {
                "Average"
            }

        plot(hwFit(), col="red", lwd = 4,
             xlim=c(as.yearqtr("1999 Q1"),predDate()),
             ylim=c(1000,4000),
             xlab = "Date",
             ylab = "Rental Rate",
             main = paste("Holts-Winters' Model\nPredicting",titleText, "Rental Rates in San Jose, CA"))
        lines(selectedTs(), col="black")

    })

    output$predCaption <- renderText({
        paste0("Predicted Rental Rate for ", predDate(),":")
        })
    output$predValue <- renderText({
        HTML(paste0("<b>$", format(tail(hwFit()$mean,1)[[1]],digits = 0, big.mark = ",")),"</b>")
        })
    output$plotNote <- renderText({"Red Line indicates date Range used for Prediction"})

    output$documentation <- renderText({
        HTML("<br/>
        <b>Summary</b>: This application uses a Holts-Winter time series prediction model <br/>
        to forecast future rental rates in San Jose, CA. <br/>
        Data was sourced from kaggle.com, link below: <br/>
        https://www.kaggle.com/sanjosedata/quarterly-average-apartment-rent <br/>
        <br/>
        <b>User Inputs</b><br/>
        <b>Select Apt Size</b>: Select the apartment type to run the prediction model for. Average <br/>
        yields the average of the 1 bed and 2 bed sizes. <br/>
        <b>Start Year for Prediction</b>: Select the year for the prediction window to begin. The times <br/>
        series is forecasted using data between the selected start date and Q2 2016. <br/>
        <b>Date to Predict For</b>: Select the period for the model to forecast rents until. This will be <br/>
        the last period in the prediction window and the value in this period will be printed below. <br/>
        <br/>
        <b>Output</b><br/>
        The plot will update to show the time series forecast for the period and apt type selected.<br/>
        The predicted rental rate for the selected prediction date will be displayed at the<br/>
        bottom of the sidebar panel.")
    })

})

