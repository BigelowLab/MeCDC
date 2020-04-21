#' Read the cumulative cases file for a given date
#'
#' @param date Date class, the day to retrieve
#' @param path the path to the data file
#' @param pop sf object, as per \code{\link{read_census}}
#' @return the merged covid/census table as sf MULTIPOLYGON
read_covid_cumulative <- function(date = Sys.Date(),
                                  path = "/mnt/ecocast/projectdata/covid19/MeCDC/cumcounts",
                                  pop = read_census()){
  if (!inherits(date, 'Date')) date <- as.Date(date)
  ifile <- file.path(path, format(date, '%Y-%m-%d.csv'))
  if (!file.exists(ifile)){
    x <- dplyr::tibble()
  } else {
    x <- readr::read_csv(ifile)
    if (!is.null(pop)) x <- merge_covid_census(x, pop = pop)
  }
  x
}

#' Merge COVID-19 and census data
#'
#' @export
#' @param x tibble, the COVID-19 cases
#' @param pop sf object, as per \code{\link{read_census}}
#' @return the merged covid/census table as sf MULTIPOLYGON
merge_covid_census <- function(x = read_covid_cumulative(pop = NULL),
                               pop = read_census()){
  if (nrow(x) == 0) return(x)
  pop %>%
    dplyr::bind_cols(x %>% dplyr::select(-.data$County)) %>%
    dplyr::mutate(
      dConfirmed = .data$Confirmed/(pop/1000),
      dRecovered = .data$Recovered/(pop/1000),
      dHospitalizations = .data$Hospitalizations/(pop/1000),
      dDeaths = .data$Deaths/(pop/1000)) %>%
    dplyr::select(
      .data$date,
      .data$geoid,
      .data$County,
      .data$pop,
      .data$density,
      .data$Confirmed,
      .data$Recovered,
      .data$Hospitalizations,
      .data$Deaths,
      .data$dConfirmed,
      .data$dRecovered,
      .data$dHospitalizations,
      .data$dDeaths,
      .data$geometry
    )
}

#' Retrieve the current COVID-19 cumulative counts
#'
#' @export
#' @param pop sf MUTLIPOLYGON as per \code{\link{read_census}}
#' @param save_file logical, if TRUE save as CSV
#' @param path character, where to save the file (date timestamped CSV)
#' @return table of COVID19 cumulative counts and densities with spatial geometry.
#'    If pop is \code{NULL} then just a simple table of cumualtive counts is returned.
fetch_covid_cumulative <- function(pop = read_census(),
                                   save_file = TRUE,
                                   path = "/mnt/ecocast/projectdata/covid19/MeCDC/cumcounts"){
  uri <- "https://www.maine.gov/dhhs/mecdc/infectious-disease/epi/airborne/coronavirus.shtml"
  tbl <- xml2::read_html(uri) %>%
    rvest::html_nodes("table") %>%
    .[[3]] %>%
    rvest::html_table()
  colnames(tbl) <- gsub("[0-9]", "", unname(as.vector(tbl[1,])))
  the_date <- Sys.Date()
  x <- tbl[-1,] %>%
    dplyr::as_tibble() %>%
    dplyr::mutate_at(colnames(tbl)[-1], as.numeric) %>%
    dplyr::arrange(.data$County) %>%
    dplyr::filter(.data$County != "Unknown") %>%
    dplyr::mutate(date = the_date)
  if (save_file){
    x <- readr::write_csv(x,
                          file.path(path, format(the_date, "%Y-%m-%d.csv")))
  }
  if (!is.null(pop)){
    x <- merge_covid_census(x, pop = pop)
  }
  x
}
