

do_plot <- function(the_date = Sys.Date()){
  cat("date received:", the_date, "\n")
  x <- merge_covid_census(cases %>% dplyr::filter(date == the_date), pop)
  MeCDC::plot_cumulative(x)
}

shiny::fluidPage(
  shiny::titlePanel("submitButton example"),
  shiny::fluidRow(
    shiny::column(3, shiny::wellPanel(
      shiny::sliderInput("date", "Date:",
                         min = min(cases$date),
                         max = max(cases$date),
                         value = max(cases$date),
                         step = 1),
      shiny::submitButton("Submit")
    )),
    shiny::column(6,
           shiny::plotOutput("plot", width = 900, height = 500)
    )
  )
)

