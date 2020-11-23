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
plan("multisession", gc = TRUE, earlySignal = TRUE)

# Run Rt estimation -------------------------------------------------------
regional_epinow(reported_cases = cases,
                generation_time = generation_time, 
                delays = delay_opts(incubation_period, reporting_delay),
                rt = NULL, backcalc = backcalc_opts(rt_window = 3),
                stan = stan_opts(samples = 2000, warmup = 250, chains = 2,
                                 max_execution_time = 20*60, 
                                 control = list(adapt_delta = 0.95)),
                horizon = 0,
                output = c("region", "summary", "timing"),
                target_date = target_date,
                target_folder = here::here("data", "rt", "samples"), 
                summary_args = list(summary_dir = here::here("data", "rt", 
                                                             target_date),
                                    all_regions = FALSE),
                logs = "logs/cases")

plan("sequential")