#' Load and clean data from BMG plate readers
#'
#' Loads in data from BMG Labtech plate readers such as FLUOstar, CLARIOstar,
#' etc. in a tidy (long) format. Users can then directly plot the data or
#' estimate growth parameters with `grofitr()`.
#'
#' @param file Raw-text file output from BMG plate reader containing growth data
#' @param get.barcode If TRUE, will search for a plate barcode in the "ID1"
#' field of the file header.
#' @param time.limits A numeric vector of length two providing two time points
#' (in hours) designating the times before and after which the data should be
#' truncated.
#'
#' @importFrom readr read_csv
#' @importFrom dplyr slice mutate rename_at vars select %>% funs
#' @importFrom tidyr gather
#'
#' @export

load_BMG <- function(file, time.limits = c(0, Inf), get.barcode = FALSE) {
  x <- file %>%
    readLines() %>%
    grepl("Well Row", .) %>%
    which() %>%
    `-`(1) %>%
    read_csv(file, skip = .)
  x <- x %>% rename_at(vars(-c(1:3)),
                       funs(x %>% slice(1) %>% select(-c(1:3)))) %>%
    dplyr::slice(-1) %>%
    tidyr::gather(time, OD, -`Well Row`, -`Well Col`, -Content) %>%
    dplyr::mutate(.data = ., time = time_to_dbl(time), OD = as.numeric(OD)) %>%
    dplyr::filter(time > time.limits[1], time < time.limits[2])
  if (get.barcode == TRUE) {
    x <-  dplyr::mutate(.data = x, plate = get_barcode_BMG(file))
  } else {
    x <-  dplyr::mutate(.data = x, plate = basename(file) %>%
                          strsplit("\\.") %>% `[[`(1) %>% `[`(1))
  }
}
