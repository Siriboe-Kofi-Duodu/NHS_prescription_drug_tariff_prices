## Overview
This project extracts and links data using the NHS API where available. Where API access is not available, direct links to the relevant data sources are used. The project establishes a database and an analytical pipeline to populate and maintain it.
The project links data from various sources using NHS SNOMED codes, supporting further research and analysis. It may also serve as a useful resource for those interested in learning about automated reproducible analytical pipelines (RAP) and SQL.
All data used are publicly available on the NHS website, so no manual data downloads are required.

<h>The project extracts and links these data</h2> 


[Prescription Data (PCA)](https://www.nhsbsa.nhs.uk/prescription-data/dispensing-data/prescription-cost-analysis-pca-data)


[Drug Tariff](https://www.nhsbsa.nhs.uk/pharmacies-gp-practices-and-appliance-contractors/drug-tariff/drug-tariff-part-viii)


[Concessionary Prices](https://cpe.org.uk/funding-and-reimbursement/reimbursement/price-concessions/archive/)


[Snomed Codes](https://dmd-browser.nhsbsa.nhs.uk/)



## Important Note
Because of the size, I have put the database in .gitignore. You will find it in the parent folder when you clone the repository.

Because I have already created the database, rerunning the same set of code will reproduce a duplicate of the data, and you will get an error due to constraints on duplication. 
If you intend to rerun the code, ensure you delete the `database.sql` after cloning or you update the `config.yaml` to get a new set of data.

## Database Setup 
This project uses SQL scripts to create a SQLite database schema (see `schema.sql` in the repository). 

### Clone the repository:
Clone the project to your local machine using the url.
   ```bash
   git clone https://github.com/Siriboe-Kofi-Duodu/NHS_prescription_drug_tariff_prices
```

## How to run and update the database

All data sources are sourced directly from the NHS website. The `input/config.yaml` file contains all data sources links.To update a data source, you only need to modify the relevant variables and URL in the `input/config.yaml` file. 
Below are the guide on how to update the variable names and the link. 

### 1. Year_Month
- `yyyymm<-202504`; change the `202504` to the month you want to update.
Updating `yyyymm<-202504` will change the year month used to call the PCA data via the NHS API in the `scripts/PCA_data.R`.

- `specials_yyyymm<-202502`; This is the Year_Month for only special products (Part VIIIB and Part VIIID).Special medicines are published only quarterly on the NHS website, that is why I provided a separate Year_Month for the two.

### 2.Part_VIIIA data source 
To update the database with a new Part_VIIIA data, only change the  link in the `config.yaml`. You will get an excel link to the various months on the [NHS website](https://www.nhsbsa.nhs.uk/pharmacies-gp-practices-and-appliance-contractors/drug-tariff/drug-tariff-part-viii)
Do download the Excel version as I only read the Excel version. If you prefer to use the CSV format, update this line of code  `temp_file <- tempfile(fileext = ".xlsx")` in the `scripts/Tariffs_data_sources.R line 18`

```r
#The link to change in the config.yaml
Link_part_VIIIA<-"https://www.nhsbsa.nhs.uk/sites/default/files/2025-04/Part%20VIIIA%20May%2025.xls.xlsx"
```

- Follow this same idea to update the rest of the links in the `input/config.yaml`

### Run the main.R:
After successfully updating the yaml file, run the `main.R` file, which will configure the links and update the database.



### Query the database 
Example on how to query the database.


```r
#Get the list of tables in the database
dbListTables(conn)

#Run a simple select statement
dbGetQuery(conn, "SELECT * FROM AMP LIMIT 10")
```

- Ensure you have always connected to the database before running a query, `conn <- DBI::dbConnect(RSQLite::SQLite(), "../database.sqlite")`

