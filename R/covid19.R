#' Read the cumulative cases file for a given date
#'
#' @export
#' @param date Date class, the day to retrieve
#' @param path the path to the data file
#' @param pop sf object, as per \code{\link{read_census}}
#' @return the merged covid/census table as sf MULTIPOLYGON
read_covid_cumulative <- function(date = Sys.Date(),
                                  path = mecdc_path("cumcounts"),
                                  pop = read_census()){
  if (!inherits(date, 'Date')) date <- as.Date(date)
  ifile <- file.path(path, format(date, '%Y-%m-%d.csv'))
  if (!file.exists(ifile)){
    x <- dplyr::tibble()
  } else {
    x <- suppressMessages(readr::read_csv(ifile))
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
                                   path = mecdc_path("cumcounts")){
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

#' Update the locally store covid19datahub table for Maine Counties
#'
#' @export
#' @param filename character, the name of the data file with COVID19datahub data
#' @return tibble of COVID19 data hub data
update_covid19datahub <- function(
  filename = mecdc_path("cumcounts","covid19datahub.csv")){

  x <- read_covid19datahub(filename = filename, add_mecdc = FALSE)
  newdata <- fetch_covid19datahub(start = max(x$date) + 1)
  if (nrow(newdata) > 0){
    x <- x %>%
      dplyr::bind_rows(newdata) %>%
      dplyr::distinct() %>%
      readr::write_csv(filename)
  }
  x
}

#' Read the locally store covid19datahub table for Maine Counties
#'
#' @export
#' @param filename character, the name of the data file with COVID19datahub data
#' @param add_mecdc logical, if TRUE append any new Me CDC data
#' @return tibble
read_covid19datahub <- function(
  filename = mecdc_path("cumcounts","covid19datahub.csv"),
  add_mecdc = TRUE){
  x <- suppressMessages(readr::read_csv(filename))
  if (add_mecdc){
    y <- read_covid_cumulative()
    if (nrow(y) > 0) x <- x %>%
      dplyr::bind_rows(y)
      dplyr::distinct()
  }
  x
}

#' Fetch updated data from COVID19 data hub
#'
#' @seealso \url{https://covid19datahub.io/}
#' @export
#' @param ... further arguments for \code{\link[COVID19]{covid19}}
#' @return tibble of COVID19 data hub data
fetch_covid19datahub <- function(...){

  x <- suppressWarnings(COVID19::covid19("USA", level = 3, ...)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(grepl("USA, Maine", .data$id, fixed = TRUE) &
                  !grepl("Out of", .data$id, fixed = TRUE) &
                  !grepl("Unassigned", .data$id, fixed = TRUE)) %>%
    dplyr::mutate(id = gsub("USA, Maine, ", "", .data$id, fixed = TRUE)) %>%
    dplyr::select(
      County = .data$id,
      Confirmed = .data$confirmed,
      Recovered = .data$recovered,
      Hospitalizations = .data$hosp,
      Deaths = .data$deaths,
      .data$date)
}
