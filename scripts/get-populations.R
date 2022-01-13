# Get population numbers for kids ages 5-11
# Not a standard age bucket so we'll need to use single year of age estimates

library(dplyr)
library(tidyr)
library(censusapi)
library(haven)

###########################################################################
# Get state population numbers from Census
# 2019 is the latest release with single year of age
# https://www.census.gov/data/developers/data-sets/popest-popproj/popest.Vintage_2019.html
###########################################################################
# 2019 population estimates - single year of age
# DATE_CODE = 12 - 7/1/2019 Population Estimate
state_pop <- getCensus(
	name = "pep/charage",
	vintage = 2019,
	vars = c("NAME", "POP", "AGE"),
	region = "state:*",
	DATE_CODE = 12)
state_pop <- state_pop %>% rename(state_name = NAME, population = POP, age = AGE, fips_state = state) %>% 
	select(-DATE_CODE) %>% 
	mutate(age = as.numeric(age)) %>%
	arrange(fips_state, age)

state_pop_511 <- state_pop %>% filter(age >= 5, age <= 11) %>%
	group_by(fips_state) %>%
	summarize(population_5_11 = sum(population)) %>%
	ungroup()

write.csv(state_pop_511, "data/2019-state-child-population.csv", na = "", row.names = F)

###########################################################################
# Get county-level single year of age from NCHS estimates using SAS data file
# https://www.cdc.gov/nchs/nvss/bridged_race/data_documentation.htm#vintage2020
###########################################################################
# download.file("https://ftp.cdc.gov/pub/Health_Statistics/NCHS/nvss/bridged_race/pcen_v2020_y1020_sas7bdat.zip",
# 							destfile = "data/original/pcen_v2020_y1020_sas7bdat.zip")
# unzip("data/original/pcen_v2020_y1020_sas7bdat.zip", exdir = "data/original/")

nchs_raw <- read_sas("data/original/pcen_v2020_y1020.sas7bdat")
colnames(nchs_raw) <- tolower(colnames(nchs_raw))
head(nchs_raw)

# Make long by year
county_pop <- nchs_raw %>% pivot_longer(
	cols = starts_with("pop"),
	names_to = "year",
	values_to = "population")
head(county_pop)

# Summarize by age - don't need other demographics
county_pop <- county_pop %>% group_by(st_fips, co_fips, vintage, year, age) %>%
	summarize(population = sum(population)) %>%
	ungroup()

county_pop_511 <- county_pop %>% filter(age >= 5 & age <= 11) %>%
	group_by(st_fips, co_fips, vintage, year) %>%
	summarize(population_5_11 = sum(population)) %>%
	ungroup()

# Summarize by state to compare with Census 2019 PEP estimates
compare_511 <- county_pop_511 %>%
	group_by(st_fips, vintage, year) %>%
	summarize(county_population_5_11 = sum(population_5_11)) %>%
	mutate(st_fips = sprintf("%02s", st_fips)) %>%
	ungroup()

compare_511 <- left_join(compare_511, state_pop_511, by = c("st_fips" = "fips_state"))
options(scipen = 9999)
compare_511 <- compare_511 %>% mutate(pop_diff = (county_population_5_11 - population_5_11)/population_5_11)

# Use vintage 2020 estimates for 2019 - almost identical state totals to estimates that we're using for states
table(county_pop_511$year)
county_pop_511_min <- county_pop_511 %>% filter(year == "pop2019") %>%
	mutate(fips_state =  sprintf("%02s", st_fips),
				 fips_county = paste0(fips_state, sprintf("%03s", co_fips))) %>%
	select(fips_state, fips_county, population_5_11)

write.csv(county_pop_511_min, "data/2019-county-child-population.csv", na = "", row.names = F)
