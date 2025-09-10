## Overview

This project provides a comprehensive database and resources for researchers interested in NHS drug prescriptions, reimbursements, drug tariff prices and concessionary prices in the UK. Gathering and linking relevant data can be challenging due to the complexity of this domain, which often require domain specific knowledge to interpret and utilize effectively.

## The primary goal is to facilitate research by:

Linking the NHS prescription data with key pricing and reimbursement information.

Incorporate drug tariff prices (Part VIIIA, Part VIIIB, Part VIIID and Part IX).

Incorporate concessionary prices.

Add prescription type classifications to the PCA dataset for more granular analysis.

Provide reimbursement prices for drugs listed in the tariff.

Offer in-depth explanations of NHS prescribing, reimbursement, SNOMED codes, and tariff systems to build foundational knowledge.

Create a relational database schema that simplifies querying for insights.


## Data Sources and Linkages:
  
[Prescription Data](http://bit.ly/3VoUERf): Derived from NHS BSA PCA datasets, which include items prescribed, quantities, and costs.

[Drug Tariff Price]( https://bit.ly/4ndqFYd): Provides standard reimbursement prices for generic and branded drugs.

[Concessionary Prices](http://bit.ly/422ZW8t): For Part VIIIA drug tariffs where temporary concessions are granted.

[Dm+d](https://dmd-browser.nhsbsa.nhs.uk/): Links BNF codes to SNOMED (VMP/VMPP/AMP/AMPP), enabling precise matching of products and packs.

Data is linked primarily via BNF Presentation codes, SNOMED codes, and year-month keys.


## For in-depth knowledge:

BNF Hierarchy: Drugs are classified into Chapters (broad categories like Cardiovascular), Sections, Paragraphs, and Chemical Substances.

BNF Presentations: are the specific forms of drugs prescribed (e.g., tablets, capsules).

Reimbursement Process: Dispensers (e.g., pharmacies) are reimbursed based on the Drug Tariff prices. 

Concessionary Prices: Temporary price adjustments for some drugs in the Part VIIIA tariff whose tariff prices is believed to be lower compared to their market prices.

Market Prices: How much suppliers (manufacturers, wholesalers etc) sells their drugs for.

For drugs in Part VIIIA tariff, their oncessionay prices are used for reimbursement, however, the tariff prices are used if the drug was not on concession or their concessionary price was not granted.

Prescription Types:  Tells if a drug was prescribed as a generic, brand or as an appliance. 

dm+d: Standard for describing medicines; VMP is the generic level, AMP is branded.
VMPP/AMPP specify pack sizes and units.

## Database Setup

This project includes SQL scripts to create the database schema see `schema.sql` in the repository. I recommend using SQLite for setup.

###### Installation

 Clone the repository:
 
   ```bash
   git clone https://github.com/Siriboe-Kofi-Duodu/NHS_prescriptions_drug_tariff.git
  ```

###### Download and Install R: 

Install R (version 4.2.2 or later) from CRAN.

Optionally, use RStudio for an IDE.


  ###### Install R dependencies:

This project uses renv for reproducible dependency management. The required packages are:

- dplyr (version 1.1.0) for data manipulation.

- httr (version 1.4.7) for HTTP requests.

- rvest (version 1.0.4) for web scraping.

- jsonlite (version 2.0.0) for JSON parsing.

- RSQLite (version 2.4.3) for SQLite database interactions.

```r
Language-R

# Install renv: 

install.packages("renv")

# Restore the project’s dependencies from renv.lock:

renv::restore()
```

  ###### Set up the database: 
  
- Run `schema.sql` in SQLite (or PostgreSQL if preferred).

- You do not need to download any data as I sourced all the data from the website directly.

###### How to update the database with new data.

I used two months of PCA data, drug tariffs Part VIIIA, Part IX, Part VIIIB and Part VIIID to create this sample database.

Update of the database is needed should more data be required. 


- PCA data
  
I sourced the PCA data via the NHS Open data API.

To update the PCA data, change the variable name `pca_apr` and year_month `PCA_202504` from the below codes to suite the year_month you are interested in.

Example: To load May 2025 PCA data, I will change the variable name to `pca_may` and the year_month to `PCA_202505` to get a final fetch call `pca_may<- fetch_pca("PCA_202505", resources)`

```r
#Loading PCA data

#Getting the resources 
data_name<-"prescription-cost-analysis-pca-monthly-data"

response<GET(paste0("https://opendata.nhsbsa.net/api/3/action/package_show?id=", data_name))
resources<-fromJSON(content(response, "text"))$result$resources

#Wrapping in a function for reuse 

fetch_pca <- function(month_name, resources) {
   url <-resources$url[which(resources$name == month_name)]
  temp <- tempfile(fileext = ".csv")
  GET(url, write_disk(temp, overwrite = TRUE))
  read.csv(temp)
}

#Fetchting April data
pca_apr<- fetch_pca("PCA_202504", resources)
```
  
- Concessionsry Prices data

I scraped the data from the website [Community Pharmacy England (CPE)](http://bit.ly/422ZW8t)  

To update the concessionsary prices data, change the variable name `apr_cp` and year-month `April-2025` from `apr_cp<-read_html("https://cpe.org.uk/our-news/April-2025-price-concessions-final-update/")` in the line of codes below.

Example: Updating with May concessionary prices will be `may_cp<-read_html("https://cpe.org.uk/our-news/May-2025-price-concessions-final-update/")`

Remember to also change the year_month in the `Mutate()` call to the year_month of the concessionary prices (CP) you are updating. The `Mutate()` call for May CP data will be `mutate(Year_month=202505)`


```r
#Scrapping April concessionary prices

apr_cp<-read_html("https://cpe.org.uk/our-news/April-2025-price-concessions-final-update/") %>%
  html_node("table") %>%         
  html_table(fill = TRUE) %>%
  slice(-1) %>%                      
  rename(Drug=X1,
         Pack_size=X2,
         Price_Concession=X3)%>%
  mutate(Year_month=202504)
 ``` 

- Drug Tariff Prices and SNOMED Codes

For the drug tariff prices (Part VIIIA, VIIID, VIIIB and IX), copy the link to the excel file on the NHS BSA website, replace the new link with the old in `scripts_load_data.R`

Note, if you copy the link to the CSV file instead, you may need to edit the code to read CSV files.

The [Snomed code](https://bit.ly/4n8lSqQ) data is usually published as a zip file, however the process to update the data is the same as the drug tariff prices.

All you need is to get the new link to the Snomed codes, and change it with the old in the `scripts_load_data.R`. 


Example: To update [Part VIIIA drug tariff prices](https://bit.ly/4ndqFYd) , click on "Part VIIIA", right click on the excel file for your preferred month and copy the link. 

Replace the new link `https://www.nhsbsa.nhs.uk/sites/default/files/2025-04/Part%20VIIIA%20May%2025.xls.xlsx` with the old `https://www.nhsbsa.nhs.uk/sites/default/files/2025-03/Part%20VIIIA%20Apr%2025.xls.xlsx` in the codes below. 

```r
#April 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-03/Part%20VIIIA%20Apr%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIIA_April<-read_excel(temp_file,skip = 2)
```

## Important Notes:
When updating the database with new data, check the "year_months" in the `mutate()` calls and the variable names in the `rbind()` calls to ensure they are updated to include your new data.

I have put the database `PCA_drug_tariffs.sqlite` in `.gitignore` because of the size, you will need to run `scripts_load_data.R` to create and load data into the database.

### Database Schema

The database includes 15 tables for NHS prescription and tariff data (e.g., BNF_Presentation, Part_VIIIA ect). See `schema.sql` for the full schema with primary and foreign key details.
