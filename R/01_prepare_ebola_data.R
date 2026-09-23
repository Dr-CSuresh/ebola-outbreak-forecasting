# Ebola Outbreak Forecasting
# 01_prepare_ebola_data.R
#
# Purpose:
# Import the global outbreak dataset, standardise variable
# names, and create the annual Ebola reporting series used
# in subsequent modelling.



library(tidyverse)
library(readxl)


# 1. Import raw data


outbreak_raw <- read_excel(
  "data/raw/outbreak.xlsx"
)


# Check dimensions
dim(outbreak_raw)


# 2. Rename variables


outbreak <- outbreak_raw %>%
  rename(
    outbreak_id        = `#Year+iso3+icd4`,
    year               = `#date+year`,
    disease_icd        = `#disease+name+icd`,
    disease_icd3       = `#disease+name+icd3`,
    disease_icd4       = `#disease+name+icd4`,
    icd_code           = `#disease+code+icd`,
    icd3_code          = `#disease+code+icd3`,
    icd4_code          = `#disease+code+icd4`,
    disease            = `#disease+name`,
    disease_definition = `#x_disease+definition`,
    country            = `#country+name`,
    iso2               = `#country+code+iso2`,
    iso3               = `#country+code+iso3`,
    unsd_region        = `#region+unsd`,
    unsd_subregion     = `#subregion+unsd`,
    who_region         = `#region+who`,
    news_id            = `#news+id`
  ) %>%
  mutate(
    year = as.integer(year)
  )


# 3. Identify Ebola records


ebola_records <- outbreak %>%
  filter(
    grepl(
      "Ebola",
      disease,
      ignore.case = TRUE
    )
  )


# Check disease labels and number of records
ebola_records %>%
  count(
    disease,
    sort = TRUE
  )



# 4. Restrict to completed calendar years


ebola_complete <- ebola_records %>%
  filter(
    year <= 2025
  )


# 5. Create annual Ebola reporting series


ebola_by_year <- ebola_complete %>%
  count(
    year,
    name = "ebola_records"
  ) %>%
  complete(
    year = 1996:2025,
    fill = list(
      ebola_records = 0
    )
  )


ebola_by_year


# 6. Basic summary


ebola_summary <- tibble(
  measure = c(
    "Total Ebola country-year records",
    "Years analysed",
    "Mean records per year",
    "Maximum records in one year",
    "Year of maximum reporting"
  ),
  value = c(
    sum(ebola_by_year$ebola_records),
    nrow(ebola_by_year),
    mean(ebola_by_year$ebola_records),
    max(ebola_by_year$ebola_records),
    ebola_by_year$year[
      which.max(
        ebola_by_year$ebola_records
      )
    ]
  )
)


ebola_summary

# 7. Save processed datasets


write_rds(
  outbreak,
  "data/processed/outbreak_clean.rds"
)

write_rds(
  ebola_by_year,
  "data/processed/ebola_by_year.rds"
)

write_csv(
  ebola_by_year,
  "results/tables/ebola_annual_counts.csv"
)

write_csv(
  ebola_summary,
  "results/tables/ebola_summary.csv"
)