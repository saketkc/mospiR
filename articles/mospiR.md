# Getting Started with mospiR

mospiR downloads survey microdata from the [MoSPI Microdata
Portal](https://microdata.gov.in), India’s NSO repository. It wraps the
NADA API and manages authentication, pagination, and retries.

## Installation

``` r
remotes::install_github("saketkc/mospiR")
```

## API key

Register at <https://microdata.gov.in> and copy your key from **My
Profile → API Key**. Add it to `~/.Renviron`:

    MOSPI_KEY=your_key_here

Reload with `readRenviron("~/.Renviron")` or restart R.

``` r
library(mospiR)
api_key <- Sys.getenv("MOSPI_KEY")
```

## Listing datasets

[`list_datasets()`](https://saketkc.github.io/mospiR/reference/list_datasets.md)
fetches all pages and returns one data frame. Pass `query` to filter by
title (client-side, case-insensitive).

``` r
datasets <- list_datasets(api_key)
cat("Total datasets:", nrow(datasets), "\n")
#> Total datasets: 183
head(datasets[, c("idno", "title")], 6)
#>                                       idno
#> 1 DDI-IND-NSO-HSCHealth80R-Jan2025-Dec2025
#> 2         DDI-IND-NSO-PLFS-Jan2025-Dec2025
#> 3                  DDI-IND-NSO-ASI-2019-20
#> 4                  DDI-IND-NSO-ASI-2020-21
#> 5                  DDI-IND-NSO-ASI-2023-24
#> 6            DDI-IND-MOSPI-NSS-CMSE80-2025
#>                                                                title
#> 1           Survey on Household Social Consumption:Health(Jan-Dec25)
#> 2 Periodic Labour Force Survey (PLFS),Calendar Year 2025 (Jan-Dec25)
#> 3                                Annual Survey of Industries 2019-20
#> 4                                Annual Survey of Industries 2020-21
#> 5                                Annual Survey of Industries 2023-24
#> 6      Comprehensive Modular Survey on Education-NSS 80th Round-2025
```

``` r
plfs <- list_datasets(api_key, query = "labour force")
#> Waiting 3s for retry backoff ■■■■■■■■■■                      
#> Waiting 3s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■                  
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■   
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> Waiting 9s for retry backoff ■■■■■■■■                        
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■              
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■    
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> Error fetching dataset list: HTTP 401 Unauthorized.
plfs[, c("idno", "title")]
#>                                idno
#> 1  DDI-IND-NSO-PLFS-Jan2025-Dec2025
#> 2          DDI-IND-NSO-PLFS-2024-24
#> 3          DDI-IND-CSO-PLFS-2019-20
#> 4          DDI-IND-CSO-PLFS-2018-19
#> 5          DDI-IND-CSO-PLFS-2021-22
#> 6          DDI-IND-CSO-PLFS-2023-24
#> 7          DDI-IND-CSO-PLFS-2022-22
#> 8          DDI-IND-CSO-PLFS-2022-23
#> 9          DDI-IND-CSO-PLFS-2021-21
#> 10         DDI-IND-CSO-PLFS-2023-23
#> 11         DDI-IND-CSO-PLFS-2020-21
#> 12         DDI-IND-CSO-PLFS-2017-18
#>                                                                                                             title
#> 1                                              Periodic Labour Force Survey (PLFS),Calendar Year 2025 (Jan-Dec25)
#> 2  Periodic Labour Force Survey (PLFS), Key Employment Unemployment Indicators for (January 2024 - December 2024)
#> 3                                                        Periodic Labour Force Survey (PLFS), July 2019-June 2020
#> 4                                                        Periodic Labour Force Survey (PLFS), July 2018-June 2019
#> 5                                                        Periodic Labour Force Survey (PLFS), July 2021-June 2022
#> 6                                                        Periodic Labour Force Survey (PLFS), July 2023-June 2024
#> 7                                           Periodic Labour Force Survey (PLFS), Calendar Year 2022 (Jan22 Dec22)
#> 8                                                      Periodic Labour Force Survey (PLFS), July, 2022- June,2023
#> 9                                           Periodic Labour Force Survey (PLFS), Calendar Year 2021 (Jan21 Dec21)
#> 10                                          Periodic Labour Force Survey (PLFS), Calendar Year 2023 (Jan23 Dec23)
#> 11                                     Unit Level Data of Periodic Labour Force Survey (PLFS) July 2020-June 2021
#> 12                                                       Periodic Labour Force Survey (PLFS), July 2017-June 2018
```

## Listing files in a dataset

``` r
files <- list_files("DDI-IND-NSO-ASI-2019-20", api_key)
#> Waiting 3s for retry backoff ■■■■■■■■■■■■■■                  
#> Waiting 3s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 6s for retry backoff ■■■■■■                          
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■           
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> Waiting 9s for retry backoff ■■■■                            
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■                   
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■         
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> Error fetching file list for 'DDI-IND-NSO-ASI-2019-20': HTTP 401 Unauthorized.
files[, c("name", "size")]
#> NULL
```

## Downloading files

[`download_file()`](https://saketkc.github.io/mospiR/reference/download_file.md)
writes one file to `folder_path` and returns the local path invisibly.

``` r
path <- download_file(
  dataset_id  = "DDI-IND-NSO-ASI-2019-20",
  file_name   = "ASI_DATA_2019_20_CSV.zip",
  folder_path = "data/asi-2019-20",
  api_key     = api_key
)
```

[`download_dataset()`](https://saketkc.github.io/mospiR/reference/download_dataset.md)
downloads every file in the dataset:

``` r
paths <- download_dataset(
  dataset_id  = "DDI-IND-NSO-ASI-2019-20",
  folder_path = "data/asi-2019-20",
  api_key     = api_key
)
length(paths)
```

If the file name doesn’t match,
[`download_file()`](https://saketkc.github.io/mospiR/reference/download_file.md)
reports what’s available:

``` r
result <- download_file("DDI-IND-NSO-ASI-2019-20", "nonexistent.csv",
                        tempdir(), api_key)
#> Waiting 3s for retry backoff ■■■■■■■■■■                      
#> Waiting 3s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■     
#> Waiting 3s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■                   
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■    
#> Waiting 6s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> Waiting 9s for retry backoff ■■■■■■■■                        
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■               
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■     
#> Waiting 9s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 
#> File 'nonexistent.csv' not found in dataset 'DDI-IND-NSO-ASI-2019-20'.
#> Available files: ASI Instruction Manual.pdf, ASI Schedule 2019-20.pdf, ASI_DATA_2019_20_CSV.zip, ASI_DATA_2019_20_JSON.zip, ASI_DATA_2019_20_SAS.zip, ASI_DATA_2019_20_SPSS.zip, ASI_DATA_2019_20_STATA.zip, ASI_Summary_Result_2019_20.pdf, ASI_Volume_I_2019_20.pdf, ASI_Write_Up_2019_20.pdf, Codelist20.pdf, Concepts20.pdf, Merge20.pdf, Nic_2008.pdf, Note_Unit-level Data_ASI_2019_20.pdf, NPCMS_Master_2011_Rev.pdf, struc20.pdf, Table_1_Annual_Series_For_Principal_Characteristics_2019_2020.xls, Table_2_Principal_Characterstics_by_Major_Industry_Group_2019_2020.xls, Table_3_Principal_Characterstics_By_Major_States_2019_2020.xls, Table_4_Estimate_of_important_characteristics_by_State_2019_2020.xls, Table_5_Estimate_of_important_characteristics_by_3_digit_of_NIC_2008_2019_2020.xls, Table_6_Principal_Characteristics_by_Rural_Urban_2019_2020.xls, Table_7_Principal_Characterstics_by_Type_of_Organisation_2019_2020.xls, Tabulation_Programme_ASI_19_20.pdf
```

## HCES rounds

The portal has all rounds of the Household Consumer Expenditure Survey.
Filter by title, then download in a loop:

``` r
hces_all <- list_datasets(api_key, query = "consumer expenditure")
cat("Matching datasets:", nrow(hces_all), "\n")
#> Matching datasets: 26
hces_all[, c("idno", "title")]
#>                                                 idno
#> 1  DDI-IND-MOSPI-NSSO-68Rnd-Sch2.0-July2011-June2012
#> 2                     DDI-IND-NSSO-66-SCHEDULE-1.0T2
#> 3                     DDI-IND-NSSO-66-SCHEDULE-1.0T1
#> 4                              IND-NSSO-HCES-2007-v1
#> 5            DDI-IND-MOSPI-NSSO-63Rnd-Sch1.0-2006-07
#> 6            DDI-IND-MOSPI-NSSO-62Rnd-Sch1.0-2005-06
#> 7    DDI-IND-MOSPI-NSSO-61Rnd-Sch1-July2004-June2005
#> 8         DDI-IND-MOSPI-NSSO-60Rnd-Sch1-Jan-June2004
#> 9               DDI-IND-MOSPI-NSSO-59Rnd-Sch1.0-2003
#> 10              DDI-IND-MOSPI-NSSO-58Rnd-Sch1.0-2002
#> 11              DDI-IND-MOSPI-NSSO-57Rnd-Sch1.0-2001
#> 12   DDI-IND-MOSPI-NSSO-56Rnd-Sch1-July2000-June2001
#> 13   DDI-IND-MOSPI-NSSO-55Rnd-Sch1-July1999-June2000
#> 14              DDI-IND-MOSPI-NSSO-54Rnd-Sch1.0-1998
#> 15              DDI-IND-MOSPI-NSSO-53Rnd-Sch1.0-1997
#> 16              DDI-IND-MOSPI-NSSO-52Rnd-Sch1.0-1995
#> 17              DDI-IND-MOSPI-NSSO-51Rnd-Sch1.0-1994
#> 18           DDI-IND-MOSPI-NSSO-50Rnd-Sch1.0-1993-94
#> 19              DDI-IND-MOSPI-NSSO-49Rnd-Sch1.0-1993
#> 20              DDI-IND-MOSPI-NSSO-48Rnd-Sch1.0-1992
#> 21              DDI-IND-MOSPI-NSSO-47Rnd-Sch1.0-1991
#> 22              DDI-IND-MOSPI-NSSO-46Rnd-Sch1.0-1990
#> 23              DDI-IND-MOSPI-NSSO-45Rnd-Sch1.0-1989
#> 24              DDI-IND-MOSPI-NSSO-43Rnd-Sch1.0-1987
#> 25              DDI-IND-MOSPI-NSSO-38Rnd-Sch1.0-1983
#> 26 DDI-IND-MOSPI-NSSO-68Rnd-Sch1.0-July2011-June2012
#>                                                                                   title
#> 1  Household Consumer Expenditure, NSS 68th Round Sch1.0 Type 2 : July 2011 - June 2012
#> 2                                 Household Consumer Expenditure, July 2009 - June 2010
#> 3                         Household Consumer Expenditure  Type-1, July 2009 - June 2010
#> 4                            Household Consumer Expenditure Survey, July 2007-June 2008
#> 5                Household Consumer Expenditure, NSS 63rd Round : July 2006 - June 2007
#> 6                                 Household Consumer Expenditure, July 2005 - June 2006
#> 7                                Household Consumer Expenditure,  July 2004 - June 2005
#> 8                                       Household Consumer Expenditure, Jan - June 2004
#> 9                                   Household Consumer Expenditure, Jan 2003 - Dec 2003
#> 10                                Household Consumer Expenditure,  July 2002 - Dec 2002
#> 11               Household Consumer Expenditure, NSS 57th Round : July 2001 - June 2002
#> 12                                Household Consumer Expenditure, July 2000 - June 2001
#> 13                               Household Consumer Expenditure,  July 1999 - June 2000
#> 14                                      Household Consumer Expenditure, Jan - June 1998
#> 15                                       Household Consumer Expenditure, Jan - Dec 1997
#> 16                                Household Consumer Expenditure, July 1995 - June 1996
#> 17                                 Household Consumer Expenditure,July 1994 - June 1995
#> 18                                Household Consumer Expenditure, July 1993 - June 1994
#> 19                                      Household Consumer Expenditure, Jan - June 1993
#> 20                                       Household Consumer Expenditure, Jan - Dec 1992
#> 21                                     Household Consumer Expenditure,  July - Dec 1991
#> 22                                  Household Consumer Expenditure, July 1990 - Jun1991
#> 23                               Household Consumer Expenditure,  July 1989 - June 1990
#> 24                                Household Consumer Expenditure, July 1987 - June 1988
#> 25                               Household Consumer Expenditure, January-December, 1983
#> 26                       Household Consumer Expenditure, Type 1 : July 2011 - June 2012
```

``` r
for (id in hces_all$idno) {
  download_dataset(id, file.path("data", "hces", id), api_key)
}
```
