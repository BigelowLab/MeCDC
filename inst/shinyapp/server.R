function(input, output) {
  output$plot <- shiny::renderPlot({
    cat("date", input$date, "\n")
    pp <- do_plot(input$date)
    print(plot)
  })
}

