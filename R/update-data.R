# packages ----------------------------------------------------------------
library(httr, quietly = TRUE)
library(jsonlite, quietly = TRUE)
library(data.table, quietly = TRUE)
library(here, quietly = TRUE)
library(lubridate, quietly = TRUE)

# Get utilities -----------------------------------------------------------
source(here::here("R", "utils.R"))

# Set filters  ------------------------------------------------------------
today <- Sys.Date()
days_with_data <- 90
min_cases_in_horizon <- 1000
min_start_cases <- 10
time_horizon <- 52 #(weeks)
days_to_truncate <- 3

# Extract data ------------------------------------------------------------
brazil_io_csv <- 
  scan(
    gzcon(rawConnection(content(GET("https://data.brasil.io/dataset/covid19/caso.csv.gz")))), 
    what="",sep="\n"
    )  
brazil_io_full <- data.frame(strsplit(brazil_io_csv, ",")) 
row.names(brazil_io_full) <- brazil_io_full[,1]
brazil_data <- data.table::as.data.table(t(brazil_io_full[,-1]))

# Clean data --------------------------------------------------------------
# keep only city level data, format date and drop cases without a specific city
brazil_data <- brazil_data[place_type == "city"][city != "Importados/Indefinidos"][,
                            date := as.Date(date, format = "%Y-%m-%d")]

# Clean up reporting issues -----------------------------------------------
brazil_data <- brazil_data[order(state, city, date)][, `:=`(confirmed = as.numeric(confirmed),
                                                           deaths = as.numeric(deaths))]
## drop zero cases, and remove cumulative data
brazil_data <- brazil_data[confirmed != 0][, 
                           `:=`(case_inc = confirmed - data.table::shift(confirmed, 1, type = "lag", fill = confirmed[1]),
                                death_inc = deaths - data.table::shift(deaths, 1, type = "lag", fill = deaths[1])),
                           by = .(state, city)]

# Fill missing dates with data --------------------------------------------
all.dates.frame <- data.frame(list(date = seq(min(brazil_data$date), max(brazil_data$date), by="day")))
all.dates.frame$merge_col <- "A"

# Merge all cities and dates 
all_cities <- unique(brazil_data[,c("city", "state", "city_ibge_code")])
all_cities$merge_col <- "A"

all_dates_cities <- merge(all.dates.frame,all_cities,by="merge_col")
all_dates_cities <- data.table::as.data.table(all_dates_cities[c(2,3,4,5)])

### Merge Municipality data to dates - missing days should be NULL
brazil_data <- merge(all_dates_cities,brazil_data,by=c("date","city","state","city_ibge_code"),all.x=TRUE)
brazil_data <- brazil_data[, c("date","city","state","city_ibge_code", "case_inc", "death_inc")]
brazil_data <- brazil_data[is.na(case_inc), case_inc := 0][is.na(death_inc), death_inc := 0]

# Fix negatives -----------------------------------------------------------
brazil_data <- brazil_data[order(city, state, date)][, 
                          `:=`(case_inc = spread_negatives(case_inc), 
                               death_inc = spread_negatives(death_inc)),
                           by = .(city_ibge_code)]

# City encoding -----------------------------------------------------------
brazil_data <- brazil_data[, city := as.character(city)]
Encoding(brazil_data$city) <- "UTF-8"

# Filter to use last x months of data -------------------------------------
brazil_data <- brazil_data[date >= (today - lubridate::weeks(time_horizon))]
brazil_data <- brazil_data[date <= (today - lubridate::days(days_to_truncate))]

# Generate filter summary data --------------------------------------------
eval_regions <- data.table::copy(brazil_data)[, .(cum_cases = cumsum(case_inc),
                                                  case_inc,
                                                  non_zero = case_inc > 0,
                                                  date = date), by = city_ibge_code]
# Identify when each region had at least x cases and set as start  --------
eval_dates <- data.table::copy(eval_regions)[, .SD[case_inc >= min_start_cases], by = city_ibge_code]
eval_dates <- eval_dates[, .(start_date = min(date)), by = city_ibge_code]
brazil_data <- brazil_data[eval_dates, on = "city_ibge_code"][date >= start_date][, start_date := NULL]

# Apply minimum case and timepoints filters -------------------------------
eval_regions <- eval_regions[, .(cum_cases = max(cum_cases), non_zero = sum(non_zero)), by = city_ibge_code]
eval_regions <- eval_regions[non_zero >= days_with_data][cum_cases >= min_cases_in_horizon]
brazil_data <- brazil_data[city_ibge_code %in% unique(eval_regions$city_ibge_code)]

# Save data  --------------------------------------------------------------
data.table::fwrite(brazil_data, here::here("data", "cases", paste0(today, ".csv")))
