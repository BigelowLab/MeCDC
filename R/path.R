#' Retrieve a CDC path
#'
#' @export
#' @param ... path segements passed to file.path
#' @param root character, the root path to the CDC data directory
#' @return a file/directory path (not tested for existence)
mecdc_path <- function(...,
                       root = "/mnt/ecocast/projectdata/covid19/MeCDC"){
  file.path(root, ...)
}
