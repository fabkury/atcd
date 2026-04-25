# Header ----------------------------------------------------------------------------------------------------------
#' atcd_combinations.R
#' ---
#' Scrapes the WHO Collaborating Centre's separate "DDDs for combination products" list
#' (https://atcddd.fhi.no/ddd/list_of_ddds_combined_products/) and writes a sibling CSV file
#' next to the main ATC-DDD output.
#'
#' This complements atcd.R: the main ATC index does not list DDDs for many combination products
#' (e.g. J01EE01, J04AM02). They live in a separate flat HTML table with its own column schema:
#'   ATC code | Brand name | Dosage form | Active ingredients per unit dose (UD) | DDD comb.
#'
#' The unit of measure here is "unit doses" (UD), not the mg/g/mcg used in the main DDD table,
#' so combination DDDs are kept in a separate file rather than merged into the main CSV.
#'
#' By Fabrício Kury
#' Margin column at 120 characters.
##

# Globals ---------------------------------------------------------------------------------------------------------
pacman::p_load(rvest)
pacman::p_load(dplyr)
pacman::p_load(readr)
pacman::p_load(xml2)
pacman::p_load(stringr)

ensure_directory <- function(...) {
  dir_path <- paste0(...)
  if(!dir.exists(dir_path))
    dir.create(dir_path, recursive = TRUE)
  dir_path
}

out_dir <- ensure_directory('output')


# Scrape data -----------------------------------------------------------------------------------------------------
scrape_who_combinations <- function() {
  web_address <- 'https://atcddd.fhi.no/ddd/list_of_ddds_combined_products/'
  message('Scraping ', web_address, '.')
  Sys.sleep(0.5)
  html_data <- read_html(web_address)

  # The page contains the combination DDDs in a single HTML table. Find the largest table on
  # the page, which is the data table.
  tables <- html_data |> html_elements('table')
  if(length(tables) == 0)
    stop('No tables found on the combinations page.')

  parsed <- lapply(tables, html_table, header = TRUE, fill = TRUE)
  row_counts <- vapply(parsed, NROW, integer(1))
  retval <- parsed[[which.max(row_counts)]]

  # Normalise column names to match the main scraper's snake_case style.
  colnames(retval) <- colnames(retval) |>
    str_squish() |>
    str_replace_all('\\s+', '_') |>
    tolower() |>
    str_replace_all('[^a-z0-9_]', '')

  expected <- c('atc_code', 'brand_name', 'dosage_form', 'active_ingredients_per_unit_dose_ud', 'ddd_comb')
  rename_map <- c(
    atc_code                           = 'atc_code',
    brand_name                         = 'brand_name',
    dosage_form                        = 'dosage_form',
    active_ingredients_per_unit_dose_ud = 'ingredients',
    ddd_comb                           = 'ddd_comb'
  )

  # Keep only columns that look like the schema we expect; rename to clean names.
  keep_cols <- intersect(names(rename_map), colnames(retval))
  if(length(keep_cols) < 4)
    warning('The combinations table has unexpected columns: ',
      paste(colnames(retval), collapse = ', '))

  retval <- retval[, keep_cols, drop = FALSE]
  colnames(retval) <- unname(rename_map[keep_cols])

  # Strip whitespace and turn empty strings into NA for cleanliness.
  retval <- retval |>
    mutate(across(everything(), ~ {
      x <- str_squish(.)
      ifelse(x == '', NA_character_, x)
    }))

  # Drop spurious header-repeat rows, if any.
  retval <- retval |>
    filter(!is.na(atc_code), atc_code != 'ATC code')

  # The WHO page has rows where a long explanatory paragraph spans every column (HTML rowspan
  # parsed as duplicated text). Detect those by atc_code being identical to brand_name (and
  # therefore not a real ATC code), and drop them.
  if(all(c('atc_code', 'brand_name') %in% names(retval)))
    retval <- retval |> filter(atc_code != brand_name)

  # Real ATC codes are at most 7 characters (level 5); the combinations table occasionally
  # references level-4 codes (5 chars). Anything longer is parsing junk.
  retval <- retval |> filter(nchar(atc_code) <= 7)

  retval
}

combinations <- scrape_who_combinations()


# Write results to storage ----------------------------------------------------------------------------------------
out_file_name <- paste0(out_dir, '/WHO ATC-DDD-combinations ', format(Sys.Date(), "%Y-%m-%d"), '.csv')
message('Writing ', nrow(combinations), ' rows to ', out_file_name, '.')
if(file.exists(out_file_name))
  message('Warning: file already exists. Will be overwritten.')
write_csv(combinations, out_file_name)


# Finish execution ------------------------------------------------------------------------------------------------
message('Script execution completed.')
