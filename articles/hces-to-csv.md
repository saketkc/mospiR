# Working with HCES Nesstar files using nesstarR

NSS rounds 64, 66, and 68 come as `.Nesstar` binaries packed inside
`.rar` archives. This vignette covers downloading one round with mospiR,
extracting the archive, and reading the data with
[nesstarR](https://github.com/saketkc/nesstarR).

## Prerequisites

``` r
remotes::install_github("saketkc/mospiR")
remotes::install_github("saketkc/nesstarR")
```

``` r
library(mospiR)
library(nesstarR)
```

## Download from the portal

``` r
api_key <- Sys.getenv("MOSPI_KEY")

download_dataset(
  "DDI-IND-NSSO-66-SCHEDULE-1.0T2",
  file.path("data", "hces", "DDI-IND-NSSO-66-SCHEDULE-1.0T2"),
  api_key
)
```

The download is a `.rar` archive, about 54 MB for NSS 66 T2.

## Extract the archive

`unar` (macOS/Linux) and `unrar` (Windows) both work. Either must be on
your `PATH`.

``` r
rar_file <- file.path(
  "data", "hces", "DDI-IND-NSSO-66-SCHEDULE-1.0T2",
  "Nss66_1.0-type2_new format.rar"
)
system2("unar", c("-o", dirname(rar_file), shQuote(rar_file)))
```

Extraction produces a folder with the `.Nesstar` binary, `ddi.xml`
(variable metadata), and supporting documents.

## Parse the Nesstar file

[`nesstar_parse()`](https://rdrr.io/pkg/nesstarR/man/nesstar_parse.html)
reads the binary header without loading any row data. Data loads only
when you call
[`nesstar_read_dataset()`](https://rdrr.io/pkg/nesstarR/man/nesstar_read_dataset.html)
on a specific dataset number.

``` r
nb <- nesstar_parse(nesstar_path)
nb
#> <nesstar_binary>
#>  File      : nss66_consumer_expenditure_type_2.Nesstar 
#>  Datasets  : 9
```

## Dataset structure

A single `.Nesstar` file holds multiple datasets, one per schedule
block.

``` r
nesstar_datasets(nb)
#>   dataset_number row_count variable_count
#> 1             18    100794             49
#> 2             19    100794             50
#> 3             20    468205             40
#> 4             21   4813463             33
#> 5             22   1217060             30
#> 6             23    365912             29
#> 7             24   2145291             29
#> 8             25   3076552             36
#> 9             26   3173462             29
```

Dataset 21 is the food block: 4.8 million item-level rows across roughly
100,000 households.

## Variable listing

``` r
vars <- nesstar_variables(nb, dataset_number = 21)
vars[, c("name", "variable_id", "width_value")]
#>                    name variable_id width_value
#> 1                 HH_ID        1724           9
#> 2           centre_code        1694           3
#> 3     FSU_Serial_number        1695           5
#> 4                 Round        1696           2
#> 5       Schedule_Number        1697           3
#> 6                Sample        1698           1
#> 7                Sector        1699           1
#> 8                 State        1725           2
#> 9                Region        1700           3
#> 10       State_District        1726           4
#> 11              Stratum        1702           2
#> 12          Sub_Stratum        1703           1
#> 13        Schedule_type        1704           1
#> 14            Sub_Round        1705           1
#> 15           Sub_Sample        1706           1
#> 16       FOD_Sub_Region        1707           4
#> 17         hg_sb_Number        1708           1
#> 18 Second_Stage_Stratum        1709           1
#> 19               HHS_no        1710           2
#> 20                Level        1711           2
#> 21               Filler        1712           2
#> 22            Item_code        1713           3
#> 23          HP_Quantity        1714           8
#> 24             HP_Value        1715           5
#> 25       Total_Quantity        1716           8
#> 26          Total_Value        1717           5
#> 27          Source_Code        1718           1
#> 28             Ok_stamp        1719           1
#> 29                Blank        1720           1
#> 30                  NSS        1721           2
#> 31                  NSC        1722           3
#> 32                  MLT        1723           8
#> 33           Multiplier        1727           8
```

Key columns in the food block:

| Column           | Meaning                                         |
|------------------|-------------------------------------------------|
| `HH_ID`          | Household identifier                            |
| `State`          | State code (2-digit)                            |
| `State_District` | District code (4-digit: state × 100 + district) |
| `Item_code`      | Food item code (NSS 66 coding)                  |
| `Total_Value`    | Household monthly expenditure (Rs)              |
| `Multiplier`     | Survey weight                                   |

## Read a dataset

``` r
food <- nesstar_read_dataset(nb, dataset_number = 21)
cat("Rows:", nrow(food), "| Columns:", ncol(food), "\n")
#> Rows: 4813463 | Columns: 33
head(food[, c("HH_ID", "State", "State_District",
              "Item_code", "Total_Value", "Multiplier")])
#>       HH_ID State State_District Item_code Total_Value Multiplier
#> 1 844471101    01           0109       101          96    105.925
#> 2 844471101    01           0109       102         200    105.925
#> 3 844471101    01           0109       107         153    105.925
#> 4 844471101    01           0109       108         210    105.925
#> 5 844471101    01           0109       111           4    105.925
#> 6 844471101    01           0109       129         663    105.925
```

## Quick check: cereal spending by sector

Weighted mean monthly expenditure on cereals (item codes 101-128), rural
vs. urban:

``` r
cereals    <- food[food$Item_code >= 101 & food$Item_code <= 128, ]
hh_cereals <- aggregate(Total_Value ~ HH_ID + Sector + Multiplier,
                        data = cereals, FUN = sum)
rural <- hh_cereals[hh_cereals$Sector == 1, ]
urban <- hh_cereals[hh_cereals$Sector == 2, ]

cat(sprintf(
  "Weighted mean cereal expenditure (Rs/month):\n  Rural: %.0f\n  Urban: %.0f\n",
  weighted.mean(rural$Total_Value, rural$Multiplier, na.rm = TRUE),
  weighted.mean(urban$Total_Value, urban$Multiplier, na.rm = TRUE)
))
#> Weighted mean cereal expenditure (Rs/month):
#>   Rural: 682
#>   Urban: 713
```

## Export to CSV

[`nesstar_export()`](https://rdrr.io/pkg/nesstarR/man/nesstar_export.html)
writes one CSV per dataset to `output_dir`.

``` r
output_dir <- file.path(tempdir(), "nss66t2")
nesstar_export(nb, output_dir = output_dir, compress = FALSE)
#> Wrote: nss66_consumer_expenditure_type_2_ds18.csv (100794 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds19.csv (100794 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds20.csv (468205 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds21.csv (4813463 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds22.csv (1217060 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds23.csv (365912 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds24.csv (2145291 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds25.csv (3076552 rows)
#> Wrote: nss66_consumer_expenditure_type_2_ds26.csv (3173462 rows)
list.files(output_dir)
#> [1] "nss66_consumer_expenditure_type_2_ds18.csv"
#> [2] "nss66_consumer_expenditure_type_2_ds19.csv"
#> [3] "nss66_consumer_expenditure_type_2_ds20.csv"
#> [4] "nss66_consumer_expenditure_type_2_ds21.csv"
#> [5] "nss66_consumer_expenditure_type_2_ds22.csv"
#> [6] "nss66_consumer_expenditure_type_2_ds23.csv"
#> [7] "nss66_consumer_expenditure_type_2_ds24.csv"
#> [8] "nss66_consumer_expenditure_type_2_ds25.csv"
#> [9] "nss66_consumer_expenditure_type_2_ds26.csv"
```

Pass `compress = TRUE` for `.csv.gz` output.

## Round reference

| Round       | idno                                                | Period  | Format  |
|-------------|-----------------------------------------------------|---------|---------|
| NSS 57th    | `DDI-IND-MOSPI-NSSO-57Rnd-Sch1.0-2001`              | 2001    | CSV zip |
| NSS 58th    | `DDI-IND-MOSPI-NSSO-58Rnd-Sch1.0-2002`              | 2002    | CSV zip |
| NSS 59th    | `DDI-IND-MOSPI-NSSO-59Rnd-Sch1.0-2003`              | 2003    | CSV zip |
| NSS 60th    | `DDI-IND-MOSPI-NSSO-60Rnd-Sch1-Jan-June2004`        | 2004    | CSV zip |
| NSS 61st    | `DDI-IND-MOSPI-NSSO-61Rnd-Sch1-July2004-June2005`   | 2004-05 | CSV zip |
| NSS 62nd    | `DDI-IND-MOSPI-NSSO-62Rnd-Sch1.0-2005-06`           | 2005-06 | CSV zip |
| NSS 63rd    | `DDI-IND-MOSPI-NSSO-63Rnd-Sch1.0-2006-07`           | 2006-07 | CSV zip |
| NSS 64th    | `IND-NSSO-HCES-2007-v1`                             | 2007-08 | Nesstar |
| NSS 66th T1 | `DDI-IND-NSSO-66-SCHEDULE-1.0T1`                    | 2009-10 | Nesstar |
| NSS 66th T2 | `DDI-IND-NSSO-66-SCHEDULE-1.0T2`                    | 2009-10 | Nesstar |
| NSS 68th T1 | `DDI-IND-MOSPI-NSSO-68Rnd-Sch1.0-July2011-June2012` | 2011-12 | Nesstar |
| NSS 68th T2 | `DDI-IND-MOSPI-NSSO-68Rnd-Sch2.0-July2011-June2012` | 2011-12 | Nesstar |

Rounds 57-63 unzip to CSVs. Rounds 64, 66, and 68 need nesstarR.
