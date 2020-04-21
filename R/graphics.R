#' Create a two panel plot of COVID-19, by count and by density
#'
#' @export
#' @param x sf object of merged COVID-19 and census data
#' @return a 2-plot ggplot2 object
plot_cumulative <- function(x = fetch_covid_cumulative()){

  if (inherits(x$date[1], "character")){
    the_date <- x$date[1]
  } else {
    the_date <- format(x$date[1], "%Y-%m-%d")
  }

  p1 <- ggplot2::ggplot(data = x)  +
    ggplot2::geom_sf(ggplot2::aes(fill = .data$Confirmed)) +
    ggplot2::labs(title = 'Cumulative Confirmed Cases',
                  subtitle = the_date,
                  fill = "Cases",
                  caption = "COVID-19 Source: Maine CDC")
  p2 <- ggplot2::ggplot(data = x)  +
    ggplot2::geom_sf(ggplot2::aes(fill = .data$dConfirmed)) +
    ggplot2::labs(title = 'Cumulative Confirmed Density',
                  subtitle = the_date,
                  fill = "Cases/1000",
                  caption = "Census Source: US Census Bureau")
  p1 + p2
}
