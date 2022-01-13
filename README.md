# Data: As Omicron Surges, Effort to Vaccinate Young Children Stalls

This repository includes data and analysis used in KHN's January 14, 2022, story "As Omicron Surges, Effort to Vaccinate Young Children Stalls".

## Attribution

The computed rates and analysis provided here should be cited as: "according to a KHN analysis of CDC data."

## Methodology

Vaccination numbers are from the Centers for Disease Control and Prevention as of Jan. 12.

[National vaccination rates](https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-Demographics-in-the-United-St/km4m-vcsb) are calculated by the CDC and include vaccinations provided by federal programs such as the Indian Health Service and the Department of Defense, as well as U.S. territories. To compare the vaccination rollout for kids and adolescents, we counted day 0 as the day the CDC approved the vaccine for each age group: [May 12](https://www.cdc.gov/media/releases/2021/s0512-advisory-committee-signing.html), 2021, for 12- to 15-year-olds and [Nov. 2](https://www.cdc.gov/media/releases/2021/s1102-PediatricCOVID-19Vaccine.html), 2021, for 5- to 11-year-olds.

The CDC provides vaccination numbers at the [state](https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-Jurisdi/unsk-b7fc/) and [county](https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-County/8xkx-amqh) level. These numbers do not include the small fraction of children who were vaccinated by federal programs. To calculate rates for 5- to 11-year-olds, we divided by the total number of kids ages 5 to 11 in each state or county.

To calculate the number of children ages 5 to 11 in each state, we used the U.S. Census Bureau's 2019 [Population Estimates Program](https://www.census.gov/programs-surveys/popest.html) "single year of age" dataset, the latest release available. For county-level data, we used the National Center for Health Statistics' [Bridged Race Population Estimates](https://www.cdc.gov/nchs/nvss/bridged_race.htm), which contain single-year-of-age county-level estimates. We selected the 2019 estimates from the 2020 vintage release so the data would reflect the same year as the state-level estimates.

Vaccination data by age is unavailable for Idaho, counties in Hawaii and several California counties. For county-level vaccination data, we excluded states in which the county was unknown for at least 10% of the kids vaccinated in that state: Georgia, Michigan, Rhode Island, Virginia and Vermont.

## About the data

Get the data in an easy to use [Excel file](https://github.com/khnews/2022-child-covid-vaccination-rates-data/raw/main/data/child-covid-vaccination-rates.xlsx) or read on to use the CSV files.

Two R scripts create all of the data files used in this story. First, [get-populations.R](scripts/get-populations.R) compiles population numbers for children ages 5 to 11 by state and by county. Then [get-child-vaccine-rates.R](scripts/get-child-vaccine-rates.R) retrieves data from the CDC and computes rates.

The key data files used in the story are:

[child-state-vaccine-rates.csv](data/child-state-vaccine-rates.csv) - state-level vaccination numbers and rates for children ages 5 to 11

[child-county-vaccine-rates.csv](data/child-county-vaccine-rates.csv) - county-level vaccination numbers and rates for children ages 5 to 11

Columns:

-   date = date in CDC dataset

-   state_code, fips_state, fips_county, state_name, county_name = geographic identifiers

-   metro_status (county dataset) = metro status of county, as provided by CDC

-   pct_dose1_5\_11 = percent of children ages 5 to 11 who have received at least one dose of a covid vaccine

-   pct_complete_5\_11 = percent of children ages 5 to 11 who are fully vaccinated against covid

-   population_5\_11 = total number of children ages 5 to 11 in that geography

-   dose1_5\_11 = number of children ages 5 to 11 who have received at least one dose of a covid vaccine

-   complete_5\_11 = number of children ages 5 to 11 who are fully vaccinated against covid

And:

[child-national-vaccine-rates-by-age.csv](data/child-national-vaccine-rates-by-age.csv)- national vaccination rates for children ages 5 to 11 and ages 12 to 15, by days since CDC approval

Columns:

-   date_from approval = days since the covid vaccine was approved for the given age group (see methodology for details)

-   pct_dose1_12_15 = percent of children ages 12 to 15 who have received at least one dose of a covid vaccine

-   pct_complete_12_15 = percent of children ages 12 to 15 who are fully vaccinated against covid

-   pct_dose1_5\_11 = percent of children ages 5 to 11 who have received at least one dose of a covid vaccine

-   pct_complete_5\_11 = percent of children ages 5 to 11 who are fully vaccinated against covid

## 
