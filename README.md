# Multispecies population-scale emergence of climate change signals in an ocean warming hotspot

### About:

This is the home of supporting data/code used in the creation of figures and supplements in "Multispecies population-scale emergence of climate change signals in an ocean warming hotspot", accepted for publication in ICES Journal of Marine Science.

This repository will be updated when the publication is publicly available.

### Repository Organization:

#### Data

The `Data` directory contains data access to summary results of our analyses.

Northeast US Trawl Survey data used for these analyses is publicly available and may be obtained directly from the National Marine Fisheries Service, Northeast Fisheries Science Center. For further inquiries please reach out or submit an issue via github.

Sea surface temperature data has not been included (for size reasons) and may be obtained from: 
> https://www.ncei.noaa.gov/products/optimum-interpolation-sst

#### R

The `R` directory contains the minimum code and documentation to recreate the figures and supplements included in this publication within two folders; `Distribution Analyses` and `Figures`.


##### Distribution Analyses
To replicate the distribution analyses, run the scripts in the following order;

-   `clean_trawl_data.R`
-   `t_testing.R`
-   `strata_effort.R`
-   `stratum_16_t_testing.R`
-   `signif_comparison.R`


##### Figures 
These scripts should be run following the `Distribution Analyses`. The order in which these scripts are run is not important.

#### Processed Data
Running the `Distribution Analyses` scripts will yield multiple `.rds` files within the `Processed Data` directory. These files are necessary for replicating the figures within the publication and supplement.

### Funding

### Collaborators
