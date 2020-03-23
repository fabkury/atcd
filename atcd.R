# Header ----------------------------------------------------------------------------------------------------------
#' atcd.R
#' ---
#' Scrapes the ATC data from https://www.whocc.no/atc_ddd_index/.
#' 
#' By Fabrício Kury
#' File started on 2020/3/20 5:08.
#' Margin column at 120 characters.
#' 
##
# Globals ---------------------------------------------------------------------------------------------------------
pacman::p_load(rvest)
pacman::p_load(dplyr)
pacman::p_load(readr)
pacman::p_load(xml2)

ensureDir <- function(...) {
  dir_path <- paste0(...)
  if(!dir.exists(dir_path))
    dir.create(dir_path, recursive = TRUE)
  dir_path
}

out_dir <- ensureDir('../Out')
rds_dir <- ensureDir(paste0(out_dir, '/rds'))

options(expressions= 100000) # Allow deep recursion.

wrapRDS <- function(var, exprs, ovr = FALSE, by_name = FALSE, pass_val = FALSE, assign_val = TRUE) {
  #' This is a handy function to store variables between runs of the code and skip recreating them.
  #' It checks if an RDS file for var already exists in rds_dir. If it does, read it from there. If
  #' it does not, evaluates exprs and saves it to such RDS file.
  #' var: The object itself, unquoted, or a character vector containing its name.
  #' exprs: Expression to be evaluated if the RDS file doesn't already exist.
  #' by_name: If true, var is interpreted as a character vector with the object name.
  #' pass_val: If true, will return the object at the end.
  #' assign_val: If true, will assign the value of the object to its name in the calling envirmt.
  #' ovr: If true, will ignore existing RDS files and evaluate exprs.
  if(by_name)
    varname <- var
  else
    varname <- deparse(substitute(var))
  
  if(!ovr && exists(varname, envir = parent.frame(n = 1)))
    message("Object '", varname, "' already exists.")
  else {
    rds_file <- paste0(rds_dir, '/', varname, '.rds')
    if(!ovr && file.exists(rds_file)) {
      message("Reading '", varname, "' from file '", rds_file, "'... ")
      var_val <- readRDS(rds_file)
      message('done.')
    } else {
      # Evaluate the expression in a temporary environment, akin to a function call.
      # TODO: Revise if I need to create a new environment using new.env(). Is this function's own environment enough?
      message('Building ', varname, '.')
      var_val <- eval(substitute(exprs),
        envir = new.env(parent = parent.frame(n = 1)))
      message(varname, " completed. Saving to file '", rds_file, "'... ")
      if(!dir.exists(rds_dir))
        dir.create(rds_dir, recursive = T)
      saveRDS(var_val, rds_file)
      message('done.')
    }
    if(assign_val)
      assign(varname, var_val, envir = parent.frame(n = 1))
  }
  
  if(pass_val || !assign_val)
    var_val
}

getRDS <- function(var, by_name = FALSE, pass_val = FALSE, assign_val = TRUE) {
  #' In connection to wrapRDS, this function only loads the RDS file, or raises an error if unable to.
  #' var: The object itself, unquoted, or a character vector containing its name.
  #' by_name: If true, var is interpreted as a character vector with the object name.
  #' pass_val: If true, will return the object at the end.
  #' assign_val: If true, will assign the value of the object to its name in the calling envirmt.
  if(by_name)
    varname <- var
  else
    varname <- deparse(substitute(var))
  
  if(exists(varname, envir = parent.frame(n = 1))) {
    message("Object '", varname, "' already exists.")
    var_val <- get(varname, envir = parent.frame(n = 1))
  } else {
    rds_file <- paste0(rds_dir, '/', varname, '.rds')
    if(file.exists(rds_file)) {
      message("Reading '", varname, "' from file '", rds_file, "'... ")
      var_val <- readRDS(rds_file)
      message('done.')
    } else {
      stop(paste0('Unable to find file ', rds_file, '.'))
    }
    
    if(assign_val)
      assign(varname, var_val, envir = parent.frame(n = 1))
  }
  
  if(pass_val || !assign_val)
    var_val
}

# A 	Alimentary tract and metabolism
# B 	Blood and blood forming organs
# C 	Cardiovascular system
# D 	Dermatologicals
# G 	Genito-urinary system and sex hormones
# H 	Systemic hormonal preparations, excluding sex hormones and insulins
# J 	Antiinfectives for systemic use
# L 	Antineoplastic and immunomodulating agents
# M 	Musculo-skeletal system
# N 	Nervous system
# P 	Antiparasitic products, insecticides and repellents
# R 	Respiratory system
# S 	Sensory organs
# V 	Various 
atc_roots <- c('A', 'B', 'C', 'D', 'G', 'H', 'J', 'L', 'M', 'N', 'P', 'R', 'S', 'V')


# Scrape data -----------------------------------------------------------------------------------------------------
scrape_who_atc <- function(root_atc_code) {
  web_address <- paste0('https://www.whocc.no/atc_ddd_index/?code=', root_atc_code, '&showdescription=no')
  message('Scraping ', web_address, '.')
  atc_code_length <- nchar(root_atc_code)
  html_data <- read_html(web_address)
  if(atc_code_length < 5) {
    scraped_strings <- html_data %>%
      html_node(css="#content > p:nth-of-type(2n)") %>%
      html_text() %>%
      strsplit('\n') %>%
      nth(1) %>%
      Filter(f = nchar)

    if(length(scraped_strings) == 0)
      return(NULL)

    tval <- lapply(scraped_strings, function(scraped_string) {
        atc_codes <- sub('^([A-Z]\\S*) (.*)', '\\1', scraped_string)
        atc_names <- sub('^([A-Z]\\S*) (.*)', '\\2', scraped_string)
        t1 <- tibble(atc_code = atc_codes, atc_name = atc_names)
        t2 <- lapply(atc_codes, scrape_who_atc) %>% bind_rows
        bind_rows(t1, t2)
      }) %>%
      bind_rows
    
    # Add the root node if needed.
    if(atc_code_length == 1) {
      root_atc_code_name <- html_data %>%
        html_nodes(css="#content a") %>%
        nth(3) %>% html_text
      bind_rows(tibble(atc_code = root_atc_code, atc_name = root_atc_code_name), tval)
    } else tval
  } else {
    html_node(html_data, xpath="//ul/table") %>%
      (function(sdt) {
        if(class(sdt) == 'xml_missing')
          return(NULL)
        sdt %>%
          html_table(header = TRUE) %>%
          rename(atc_code = `ATC code`, atc_name = Name, ddd = DDD, uom = U, adm_r = `Adm.R`, note = Note) %>%
          mutate(
            atc_code = ifelse(!nchar(atc_code), lag(atc_code, 1), atc_code),
            atc_name = ifelse(!nchar(atc_name), lag(atc_name, 1), atc_name)) %>%
          mutate_all(~ifelse(.=='', NA, .))
      })
  }
}

for(atc_root in atc_roots)
  paste0('who_atc_', atc_root) %>%
    wrapRDS(by_name = TRUE, scrape_who_atc(atc_root))


# Write to storage ------------------------------------------------------------------------------------------------
who_atc <- paste0('who_atc_', atc_roots) %>%
  lapply(getRDS, by_name = TRUE, assign_val = FALSE, pass_val = TRUE) %>%
  bind_rows

# Generate file name from current date in year-month-day format.
paste0(out_dir, '/WHO ATC-DDD ', format(Sys.Date(), "%Y-%m-%d"), '.csv') %>%
  (function(out_file_name) {
    message('Writing results to ', out_file_name, '.')
    write_csv(who_atc, out_file_name)
    message('Done.')
    remove(out_file_name)
  })


# Finish execution ------------------------------------------------------------------------------------------------
message('Script execution completed.')

