# Packages -----------------------------------------------------------------
library(EpiNow2, quietly = TRUE)
library(data.table, quietly = TRUE)
library(future, quietly = TRUE)
library(here, quietly = TRUE)

# Set target date ---------------------------------------------------------
target_date <- as.character(Sys.Date())

# Set up logging ----------------------------------------------------------
setup_logging("INFO", file = paste0("logs/summary/", target_date, ".log"),
              mirror_to_console = TRUE)
setup_logging("INFO", file = paste0("logs/detailed/", target_date, ".log"),
              name = "EpiNow2.epinow")
setup_logging("INFO", file = paste0("logs/fit/", target_date, ".log"),
              name = "EpiNow2.epinow.fit")

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
regional_epinow(reported_cases = cases, method = "approximate",
                generation_time = generation_time, 
                delays = list(incubation_period, reporting_delay),
                stan_args = list(trials = 5), horizon = 7, samples = 2000, 
                burn_in = 14, fixed_future_rt = TRUE, summary = FALSE,
                target_folder = here::here("data", "rt-samples"), 
                return_estimates = FALSE,  max_execution_time = 60 * 20,
                keep_samples = FALSE, make_plots = FALSE)

# Summarise results -------------------------------------------------------
regional_summary(reported_cases = cases,
                 results_dir = here::here("data", "rt-samples"),
                 summary_dir = here::here("data", "rt", target_date),
                 all_regions = FALSE, return_summary = FALSE)

