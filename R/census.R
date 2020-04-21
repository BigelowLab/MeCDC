#' Read Maine population and density form US Census
#'
#' @export
#' @param filename character, the name of the file
#' @return sf MULTIPOLYGIN object of county populations
read_census <- function(filename = system.file("me_county_population.geojson",
                                               package = "MeCDC")){
  sf::read_sf(filename)
}

#' Retrieve the CENSUS_API_KEY
#'
#' @export
#' @return character key
get_census_key <- function(){
  Sys.getenv("CENSUS_API_KEY")
}

#' Get census estimates for Maine counties
#'
#' @export
#' @param simplify logical, if TRUE simplify into a familiar form
#' @return table of county population, density, geoid and geometry
fetch_census_estimates <- function(simplify = TRUE){

  get_county_name <- function(NAME){
    sapply(strsplit(NAME, " ", fixed = TRUE), "[[", 1)
  }
  x <- suppressMessages(tidycensus::get_estimates(
                            geography = 'county',
                            product = "population",
                            state = "ME",
                            key = get_census_key(),
                            geometry = TRUE))
  xx <- split(x, x$variable)
  nms <- names(xx)
  xx <- lapply(nms,
               function(nm){
                xx[[nm]] <- xx[[nm]] %>%
                  dplyr::mutate(!!nm := .data$value) %>%
                  dplyr::select(-.data$variable, -.data$value)
               })
  x <- xx[[1]] %>%
    dplyr::mutate(!!nms[2] := xx[[2]][[nms[2]]]) %>%
    dplyr::arrange(.data$NAME)

  if (simplify) x <- x %>%
    dplyr::mutate(NAME = get_county_name(.data$NAME),
                  pop = .data$POP,
                  density = .data$DENSITY) %>%
    dplyr:: select(geoid = .data$GEOID,
                   County = .data$NAME,
                   .data$pop,
                   .data$density,
                   .data$geometry)
  x
}

