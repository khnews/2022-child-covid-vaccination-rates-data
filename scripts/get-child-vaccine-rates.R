# Calculate age 5-11 covid vaccines by state, county and nationally

library(dplyr)
library(tidyr)
library(RSocrata)
library(lubridate)

fips <- read.csv("data/original/fips-states.csv", colClasses = "character")
state_pop_511 <- read.csv("data/2019-state-child-population.csv", 
													colClasses = c("fips_state" = "character"))
county_pop_511 <- read.csv("data/2019-county-child-population.csv", 
													 colClasses = c("fips_state" = "character", "fips_county" = "character"))

###########################################################################
# Get latest state vaccine numbers by age from the CDC
###########################################################################
dt_raw <- read.socrata("https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-Jurisdi/unsk-b7fc/")
colnames(dt_raw)

# Note API field vs Socrata display name mismatch: administered_dose1_recip_12plus = administered_dose1_recip_1
dt <- dt_raw %>% select(date, 
												state_code = location, 
												dose1_total = administered_dose1_recip, 
												dose1_12plus = administered_dose1_recip_1, 
												dose1_5plus = administered_dose1_recip_5plus,
												complete_total = series_complete_yes,
												complete_12plus = series_complete_12plus,
												complete_5plus = series_complete_5plus) %>%
	mutate(dose1_5_11 = dose1_5plus - dose1_12plus,
				 complete_5_11 = complete_5plus - complete_12plus)

dt <- left_join(dt, fips, by = "state_code")

# Latest data
latest_vaxx <- dt %>% filter(date == max(date)) %>% 
	arrange(state_code)

###########################################################################
# Join together
###########################################################################
state_rates <- left_join(latest_vaxx, state_pop_511, by = "fips_state") %>%
	arrange(fips_state) %>%
	# Account for 0s in Idaho (missing data)
	mutate(pct_dose1_5_11 = ifelse(dose1_5_11 > 0, dose1_5_11/population_5_11, NA),
				 pct_complete_5_11 = ifelse(complete_5_11 > 0, complete_5_11/population_5_11, NA)) %>%
	select(date, state_code, fips_state, state_name, starts_with("pct"), 
				 population_5_11, dose1_5_11, complete_5_11,
				 everything()) %>%
	mutate(state_name = case_when(
		state_code == "BP2" ~ "Bureau of Prisons",
		state_code == "DD2" ~ "Department of Defense",
		state_code == "IH2" ~ "Indian Health Service",
		state_code == "US" ~ "United States",
		state_code == "VA2" ~ "Veterans Affairs",
		TRUE ~ state_name))

state_rates_min <- state_rates %>% filter(fips_state <= 56 | fips_state == 72) %>%
	select(-ends_with("total"), -ends_with("plus"))

# Add percent formatted for datawrapper
state_rates_min <- state_rates_min %>% mutate(
	dw_dose1_5_11 = pct_dose1_5_11 * 100,
	dw_complete_5_11 = pct_complete_5_11 * 100)
write.csv(state_rates_min, "data/child-state-vaccine-rates.csv", na = "", row.names = F)


###########################################################################
# County vaxx rates
###########################################################################
county_dt_raw <- read.socrata("https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-County/8xkx-amqh")
colnames(county_dt_raw)

# Huge dataset, cut to latest date
county_dt_raw <- county_dt_raw %>% filter(date == max(date)) %>% 
	arrange(fips)

county_dt <- county_dt_raw %>% select(date, 
												fips_county = fips, 
												state_code = recip_state,
												county_name = recip_county,
												metro_status,
												dose1_total = administered_dose1_recip, 
												dose1_12plus = administered_dose1_recip_12plus, 
												dose1_5plus = administered_dose1_recip_5plus,
												complete_total = series_complete_yes,
												complete_12plus = series_complete_12plus,
												complete_5plus = series_complete_5plus) %>%
	mutate(dose1_5_11 = dose1_5plus - dose1_12plus,
				 complete_5_11 = complete_5plus - complete_12plus)

# Calculate percent attributed to unknown county by state
county_sums <- county_dt %>% group_by(state_code) %>%
	summarize(dose1_5_11 = sum(dose1_5_11, na.rm = T),
						complete_5_11 = sum(complete_5_11, na.rm = T)) %>% 
	ungroup()

county_unknown <- county_dt %>% filter(fips_county == "UNK") %>%
	select(state_code, unk_dose1_5_11 = dose1_5_11, unk_complete_5_11 = complete_5_11) 

county_unknown_validate <- left_join(county_sums, county_unknown, by = "state_code") %>%
	mutate(pct_unknown_complete = unk_complete_5_11/complete_5_11,
				 pct_unknown_dose1_5_11 = unk_dose1_5_11/dose1_5_11)

states_exclude <- county_unknown_validate %>% 
	filter(pct_unknown_complete >= 0.1 | complete_5_11 == 0 | is.na(complete_5_11)) %>% 
	pull(state_code)
states_exclude

###########################################################################
# Join to county populations
###########################################################################
county_rates <- left_join(county_dt, county_pop_511, by = "fips_county") %>%
	select(-fips_state)
# Add in fips to filter out territories & unknown counties
county_rates <- left_join(county_rates, fips, by = "state_code")
county_rates <- county_rates %>% filter(fips_state <= 56 & fips_county != "UNK") %>%
	arrange(fips_county) %>%
	# Account for 0s (missing data sometimes)
	mutate(
		pct_dose1_5_11 = case_when(
			state_code %in% states_exclude ~ NA_real_,
			dose1_5_11 > 0 ~ dose1_5_11/population_5_11,
			TRUE ~ NA_real_),
		pct_complete_5_11 = case_when(
			state_code %in% states_exclude ~ NA_real_,
			complete_5_11 > 0 ~ complete_5_11/population_5_11,
			TRUE ~ NA_real_))

summary(county_rates$pct_complete_5_11)

county_rates <- county_rates %>%
	select(date, state_code, fips_state, state_name, fips_county, county_name, metro_status, starts_with("pct"), 
				 population_5_11, dose1_5_11, complete_5_11,
				 everything()) %>%
	select(-ends_with("total"), -ends_with("plus"))

# Rates for Datawrapper
county_rates <- county_rates %>% mutate(
	dw_dose1_5_11 = pct_dose1_5_11 * 100,
	dw_complete_5_11 = pct_complete_5_11 * 100)
write.csv(county_rates, "data/child-county-vaccine-rates.csv", na = "", row.names = F)

###########################################################################
# Get national kids' rates over time
###########################################################################
national_raw <- read.socrata("https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-Demographics-in-the-United-St/km4m-vcsb/")
colnames(national_raw)

table(national_raw$demographic_category)

# Age-related data for useful age buckets
national_ages <- national_raw %>% 
	filter(demographic_category %in% c("Ages_5-11_yrs","Ages_12-15_yrs", "Ages_16-17_yrs", "Ages_18-24_yrs", 
																		 "Ages_25-39_yrs", "Ages_40-49_yrs", "Ages_50-64_yrs", 
																		 "Ages_65-74_yrs", "Ages_75+_yrs")) %>% 
	mutate(age = case_when(
		demographic_category == "Ages_5-11_yrs" ~ "5-11",
		demographic_category == "Ages_12-15_yrs" ~ "12-15",
		demographic_category == "Ages_16-17_yrs" ~ "16-17",
		demographic_category == "Ages_18-24_yrs" ~ "18-24",
		demographic_category == "Ages_25-39_yrs" ~ "25-39",
		demographic_category == "Ages_40-49_yrs" ~ "40-49", 
		demographic_category == "Ages_50-64_yrs" ~ "50-64", 
		demographic_category == "Ages_65-74_yrs" ~ "65-74",
		demographic_category == "Ages_75+_yrs" ~ "75+"
	),
	age_group = case_when(
		demographic_category == "Ages_5-11_yrs" ~ 1,
		demographic_category == "Ages_12-15_yrs" ~ 2,
		demographic_category == "Ages_16-17_yrs" ~ 3,
		demographic_category == "Ages_18-24_yrs" ~ 4,
		demographic_category == "Ages_25-39_yrs" ~ 5,
		demographic_category == "Ages_40-49_yrs" ~ 6, 
		demographic_category == "Ages_50-64_yrs" ~ 7, 
		demographic_category == "Ages_65-74_yrs" ~ 8,
		demographic_category == "Ages_75+_yrs" ~ 9
	)) %>% select(date, age, age_group, 
								dose1 = administered_dose1, pct_dose1 = administered_dose1_pct, 
								complete = series_complete_yes, pct_complete = series_complete_pop_pct) %>%
	arrange(age_group, desc(date))

write.csv(national_ages, "data/national-vaccine-rates-by-age.csv", na = "", row.names = F)

# 5-11 vs 12-15 data for chart - base on date after approval announced

age_chart <- national_ages %>% filter(age_group %in% c(1, 2) & date >= "2021-05-01") %>%
	mutate(date_diff = case_when(
		age_group == 1 ~ ymd(date) - ymd("2021-11-02"),
		age_group == 2 ~ as.Date(date) - as.Date("2021-05-12")
	),
	date_from_approval = as.numeric(date_diff)) %>%
	select(date_from_approval, age, pct_dose1, pct_complete) %>%
	pivot_wider(names_from = "age", values_from = starts_with("pct_")) %>%
	filter(date_from_approval >= 0) %>%
	arrange(date_from_approval)
write.csv(age_chart, "data/child-national-vaccine-rates-by-age.csv", na = "", row.names = F)

