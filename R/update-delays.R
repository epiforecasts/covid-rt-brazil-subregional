# Packages ----------------------------------------------------------------
library(EpiNow2, quietly = TRUE)
library(covidregionaldata, quietly = TRUE)
library(data.table, quietly = TRUE)
library(future, quietly = TRUE)
library(here, quietly = TRUE)

# Save incubation period and generation time ------------------------------
generation_time <- get_generation_time(disease = "SARS-CoV-2", source = "ganyani")
incubation_period <- get_incubation_period(disease = "SARS-CoV-2", source = "lauer")
saveRDS(generation_time , here::here("data", "delays", "generation_time.rds"))
saveRDS(incubation_period, here::here("data", "delays", "incubation_period.rds"))

# Set up parallel ---------------------------------------------------------
if (!interactive()) {
  ## If running as a script enable this
  options(future.fork.enable = TRUE)
}
plan(multisession)

# Fit delay from onset to admission ---------------------------------------
report_delay <- covidregionaldata::get_linelist(clean = TRUE)
report_delay <- data.table::as.data.table(report_delay)[country %in% "Brazil"]
report_delay <- report_delay[!is.na(delay_onset_report)]
onset_to_report <- estimate_delay(report_delay$delay_onset_report,
                                  bootstraps = 100, max_value = 15)

saveRDS(onset_to_report, here::here("data", "delays", "onset_to_report.rds"))

plan(sequential)