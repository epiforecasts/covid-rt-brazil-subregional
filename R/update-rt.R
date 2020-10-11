# Packages -----------------------------------------------------------------
library(EpiNow2, quietly = TRUE)
library(data.table, quietly = TRUE)
library(future, quietly = TRUE)
library(here, quietly = TRUE)

# Set target date ---------------------------------------------------------
target_date <- as.character(Sys.Date())

# Update delays -----------------------------------------------------------
generation_time <- readRDS(here::here("data", "delays", "generation_time.rds"))
incubation_period <- readRDS(here::here("data", "delays", "incubation_period.rds"))
reporting_delay <- readRDS(here::here("data", "delays", "onset_to_report.rds"))

# Get cases  ---------------------------------------------------------------
cases <- data.table::fread(file.path("data", "cases", paste0(target_date, ".csv")))
cases <- cases[, .(region = as.character(city), date = as.Date(date), 
                   confirm = case_inc)]
data.table::setorder(cases, region, date)

# # Set up cores -----------------------------------------------------
plan("multiprocess", gc = TRUE, earlySignal = TRUE)

# Run Rt estimation -------------------------------------------------------
regional_epinow(reported_cases = cases, 
                method = "approximate",
                generation_time = generation_time, 
                delays = list(incubation_period, reporting_delay),
                stan_args = list(trials = 5), 
                samples = 2000, 
                horizon = 7, 
                burn_in = 14, 
                output = c("region", "summary", "timing"),
                fixed_future_rt = TRUE, 
                target_folder = here::here("data", "rt-samples"), 
                summary_args = list(summary_dir = here::here("data", "rt", target_date),
                                    all_regions = FALSE),
                logs = "logs",
                max_execution_time = 60 * 20)

