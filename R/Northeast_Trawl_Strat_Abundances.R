# Date 3/21/2023
# Subject: Stratified Abundance Changes, decadal variability paper:
# Premise: McCalls basin hypothesis suggests that species with shrinking/growing
# populations will differently track a favorable environment
# Goal is to see which species fall into either category
# Range of specific interest is 2000-2010-2019

# Packages
library(gmRi)
library(targets)
library(tidyverse)
library(patchwork)
library(grid)
library(gridExtra)



# Tweak the theme
new_theme <- function(...){
  theme_gmri() +
    theme(
      plot.margin = margin(t = 2, b = 2, r = 8, l = 2),
      axis.line.y = element_blank(),
      axis.title.y = element_text(size = 14),
      axis.title.x = element_text(size = 14),
      axis.text.y = element_text(size = 12),
      axis.text.x = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12),
      plot.subtitle = element_text(size = 14),
      ...)
}

# Turn it on
theme_set(new_theme())


# Path to decadal folder:
decadal_folder <- cs_path(
  box_group = "mills", 
  subfolder = "Projects/Decadal Variability/Revisions/Strat_Abund/")


#### Load Data  ####

# Load the clean survdat data with targets

# Trawl Cleanup Pipeline Part of another Repository:
# github.com/adamkemberling/nefsc_trawl
withr::with_dir(
  new = "~/Documents/Repositories/nefsc_trawl", 
  code = tar_load(survdat_clean))

# Code from original repo structure
#tar_load("survdat_clean")

# Rename with minor filtering
survdat <- survdat_clean %>%  filter(season %in% c("Spring", "Fall"))





#----------  Stratum Area Details. ----------

# Need the number of all tows in each stratum, the area of each stratum:

####  1. Import supplemental files  ####
nmfs_path <- cs_path(box_group = "RES_Data", subfolder = "NMFS_trawl")

# Stratum Area Information File
stratum_area_path <- stringr::str_c(nmfs_path, "Metadata/strata_areas_km2.csv")
stratum_area      <- readr::read_csv(stratum_area_path, col_types = readr::cols())
stratum_area      <- dplyr::mutate(stratum_area, stratum = as.character(stratum))



####  2.  Set Constants:  ####

# Area covered by an albatross standard tow in km2
alb_tow_km2 <- 0.0384

# catchability coefficient - ideally should change for species guilds or functional groups. 
q <- 1





####  3. Stratum Area & Effort Ratios  ####

# Get Annual Stratum Effort, and Area Ratios
# number of tows in each stratum by year
# area of a stratum relative to total area of all stratum sampled that year


# a. Merge in the area of strata in km2 (excludes ones we do not care about via left join)
survdat_areas <- dplyr::left_join(survdat, stratum_area, by = "stratum") 


# b. Get Total area of all strata sampled in each year:
total_stratum_areas <- dplyr::group_by(survdat_areas, est_year) %>% 
  distinct(stratum, s_area_km2) %>% 
  summarise(tot_s_area =  sum(s_area_km2, na.rm = T), 
            .groups = "drop")


# c. Calculate individual strata area relative to total area that year
# i.e. stratio or stratum weights
survdat_areas <- dplyr::left_join(survdat_areas, total_stratum_areas, by = "est_year")
survdat_areas <- dplyr::mutate(survdat_areas, st_ratio = s_area_km2 / tot_s_area)


# We have total areas, now we want effort within each
# Number of unique tows per stratum, within each season
yr_strat_effort <- dplyr::group_by(survdat_areas, est_year, season, stratum) %>% 
  summarise(strat_ntows = dplyr::n_distinct(id), .groups = "drop")

# Plot effort:
yr_strat_effort %>% 
  group_by(est_year, season) %>% summarise(all_tows = sum(strat_ntows)) %>% 
  ggplot(aes(est_year, all_tows)) +
  geom_line(aes(color = season))



# Add those yearly effort counts back for later
# (area stratified abundance)
survdat_areas <- dplyr::left_join(
  survdat_areas, yr_strat_effort, 
  by = c("est_year", "season", "stratum"))





#--------- Getting Species Specific Abundance Totals --------

# Abundance and biomass across all sizes is measured once for each species
# Need tos trip out the repeated rows to avoid inflating the numbers

species_station_totals <- survdat_areas %>% 
  distinct(id, est_year, season, stratum, comname, abundance, biomass_kg, strat_ntows, st_ratio, tot_s_area)







#--------- Strata specific Abundance Densities. -------------------


# a. Catch / tow, for that year & season
stratified_abundance <-  species_station_totals %>% 
  dplyr::mutate(strata_abundance_cpue = abundance / strat_ntows)


# b. Stratified Mean Catch Rates
# Stratified mean abundance CPUE, weighted by the stratum areas
stratified_abundance <-  stratified_abundance %>% 
  dplyr::mutate(strat_mean_abund_s = strata_abundance_cpue * st_ratio)


# c. Stratified Totals
# convert from catch rate by area swept to total catch for entire stratum
# Depends on catchability (q) at this step, and the albatross area-towed
stratified_abundance <-  stratified_abundance %>% 
  dplyr::mutate(
    # Total Abundance
    strat_total_abund_s = round((strat_mean_abund_s * tot_s_area / alb_tow_km2) / q))






# ---------- Species Filtering. -------------


# Pick the different species out that we are using

species <- c(
  "acadian redfish",
  "alewife",
  "american lobster",
  "american plaice",
  "american shad",
  "atlantic cod",
  "atlantic hagfish",
  "atlantic herring",
  "atlantic mackerel",
  "atlantic rock crab",
  "black sea bass",
  "blackbelly rosefish",
  "butterfish",
  "chain dogfish",
  "cusk",
  "fawn cusk-eel",
  "fourbeard rockling",
  "fourspot flounder",
  "goosefish",
  "gulf stream flounder",
  "haddock",
  "jonah crab",
  "little skate",
  "longfin squid",
  "longhorn sculpin",
  "northern sand lance",
  "northern searobin",
  "northern shortfin squid",
  "ocean pout",
  "offshore hake",
  "pollock",
  "red hake",
  "rosette skate",
  "scup",
  "sea raven",
  "sea scallop",
  "silver hake",
  "smooth dogfish",
  "smooth skate",
  "spiny dogfish",
  "spotted hake",
  "summer flounder",
  "thorny skate",
  "white hake",
  "windowpane",
  "winter flounder",
  "winter skate",
  "witch flounder",
  "yellowtail flounder") %>% 
  sort() %>% 
  str_to_sentence()

# Capitalize gs flounder
species[which(species == "Gulf stream flounder")] <- "Gulf Stream flounder"


# Filter to just those species:
decadal_dat <- stratified_abundance %>% 
  mutate(comname = tolower(comname)) %>% 
  filter(comname %in% tolower(species))







# ---------- Annual Aggregations. ------------


# Do we take the mean across area-weighted catch rates? 
# or the total abundances estimated for the entire area?
annual_abundance_summary <- decadal_dat %>% 
  group_by(year = est_year, comname) %>% 
  summarise(
    estimated_abundance = sum(strat_total_abund_s, na.rm = T),
    area_wtd_density = mean(strat_mean_abund_s, na.rm = T),
    .groups = "drop")



# Catch Density:
test_species <- "little skate"


annual_abundance_summary %>% 
  filter(comname == test_species) %>% 
  ggplot(aes(year, area_wtd_density)) +
  geom_line() +
  geom_point() +
  theme_gmri() +
  labs(y = "Mean area-weighted CPUE", title = test_species)

# Stratified Total Abundance Estimate
annual_abundance_summary %>% 
  filter(comname == test_species) %>% 
  ggplot(aes(year, estimated_abundance)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma_format()) +
  theme_gmri() +
  labs(y = "Total Area-Stratified Abundance", title = test_species)




# Catch Density:
annual_abundance_summary %>% 
  filter(comname == "atlantic cod") %>% 
  ggplot(aes(year, area_wtd_density)) +
  geom_line() +
  geom_point() +
  #theme_gmri() +
  labs(y = "Mean area-weighted CPUE", title = "Atlantic Cod")











#------------  Design the Plot --------

# Do a trendline of the last 20 years
# Color based on direction and significance

plot_strat_abund <- function(species_x){
  
  # Pull the species
  one_species <- annual_abundance_summary %>% 
    filter(comname == tolower(species_x)) %>% 
    mutate(comname = toupper(comname), 
           abund_mill = estimated_abundance/1e6) %>% 
    filter(year %in% c(1970:2019))
  
  # Get the long-term mean
  mean_abund <- mean(one_species$estimated_abundance, na.rm = T)
  sd_abund <- sd(one_species$estimated_abundance, na.rm = T)
  
  # Get difference from mean
  one_species <- one_species %>% mutate(
    abund_scaled = (estimated_abundance - mean_abund)/sd_abund )
  
  
  # lm_coef <- lm(estimated_abundance ~ year, data = one_species) %>% coef() %>% as.numeric()
  # direction_col <- ifelse(lm_coef[2] > 0, gmri_cols("blue"), gmri_cols("orange"))
  ggplot(one_species, aes(year, abund_scaled)) +
    geom_line(color = gmri_cols("light gray"), linewidth = 0.5) +
    geom_point(color = "black", size = 0.5) +
    labs(title = species_x,
         #y = "Abundance Index"
         y = NULL,
         x = "")
}



# Run it for all of them:
abundance_figs <- map(species, plot_strat_abund) %>% 
  setNames(species)





# ----------- Saving -------------


# Patchwork: Pages of 20:
species_abund_1 <- patchworkGrob(wrap_plots(abundance_figs[1:20],  ncol = 4, nrow = 5, widths = 3, heights = 3))
species_abund_2 <- patchworkGrob(wrap_plots(abundance_figs[21:40], ncol = 4, nrow = 5, widths = 3, heights = 3))
species_abund_3 <- patchworkGrob(wrap_plots(abundance_figs[41:49], ncol = 4, nrow = 3, widths = 3, heights = 3))



# Apply a shared label to the y axis:
species_abund_1 <- gridExtra::grid.arrange(
  species_abund_1, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 16)))
species_abund_2 <- gridExtra::grid.arrange(
  species_abund_2, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 16)))
species_abund_3 <- gridExtra::grid.arrange(
  species_abund_3, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 16)))


####  Draft Submission Saving  ####
# Save the figures as individual pages:

# # # Save as single-page png
# ggsave(str_c(decadal_folder, "strat_abundance_p1.png"), species_abund_1, height = 12.5, width = 10, units ="in", dpi = "retina")
# ggsave(str_c(decadal_folder, "strat_abundance_p2.png"), species_abund_2, height = 12.5, width = 10, units ="in", dpi = "retina")
# ggsave(str_c(decadal_folder, "strat_abundance_p3.png"), species_abund_3, height = 7.5, width = 10, units ="in", dpi = "retina")
# 



####  Saving High Resolution  ####

# 500 DPI
# Change the Dimensions

# Where to put the figures
decadal_hires_folder <- cs_path("mills", "Projects/Decadal Variability/publication_figures/")


# Make them again with theme tweaks:
# From Carly
theme_ices <- function(...){
  theme_gmri() +
    theme(plot.title    = element_text(size = 8),
          axis.title    = element_text(size = 7),
          axis.text     = element_text(size = 6),
          panel.grid    = element_line(linewidth = 0.2),
          axis.line.x   = element_line(linewidth = 0.1),
          axis.ticks.x  = element_line(linewidth = 0.1),
          plot.margin   = margin(t = 8, b = 4, r = 8, l = 4),
          ...)
}

# Set it
theme_set(theme_ices())


# Run it for all of them:
abundance_figs <- map(species, plot_strat_abund) %>% 
  setNames(species)



# Patchwork: Pages of 20:
species_abund_1 <- patchworkGrob(wrap_plots(abundance_figs[1:20],  ncol = 4, nrow = 5, widths = 3, heights = 3))
species_abund_2 <- patchworkGrob(wrap_plots(abundance_figs[21:40], ncol = 4, nrow = 5, widths = 3, heights = 3))
species_abund_3 <- patchworkGrob(wrap_plots(abundance_figs[41:49], ncol = 4, nrow = 3, widths = 3, heights = 3))



# Apply a shared label to the y axis:
species_abund_1 <- gridExtra::grid.arrange(
  species_abund_1, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 8)))
species_abund_2 <- gridExtra::grid.arrange(
  species_abund_2, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 8)))
species_abund_3 <- gridExtra::grid.arrange(
  species_abund_3, 
  left = textGrob(expression(bold("Abundance Index")), rot = 90,
                  gp = gpar(col = "black", fontsize = 8)))



# These are supplemental figures: S15  a,b, & c
ggsave(str_c(decadal_hires_folder, "Figure_S15_a.pdf"),  species_abund_1, height = 225, width = 170, units ="mm", dpi = 500)
ggsave(str_c(decadal_hires_folder, "Figure_S15_b.pdf"),  species_abund_2, height = 225, width = 170, units ="mm", dpi = 500)
ggsave(str_c(decadal_hires_folder, "Figure_S15_c.pdf"), species_abund_3, height = 135, width = 170, units ="mm", dpi = 500)

