library(ggplot2)
library(patchwork)
library(shiny)

pop <- MeCDC::read_census()
cases <- MeCDC::read_covid19datahub(add_mecdc = FALSE)
