Overview
This project provides a comprehensive database and resources for researchers interested in NHS drug prescriptions, reimbursements, drug tariff prices and concessionary prices in the UK. Gathering and linking relevant data can be challenging due to the complexity of this domain, which often require domain specific knowledge to interpret and utilize effectively.

The primary goal is to facilitate research by:

Linking the prescription with key pricing and reimbursement information.
Incorporating drug tariff prices (Part VIIIA, Part VIIIB, Part VIIID and Part IX).
Including concessionary prices.
Adding prescription type classifications to the PCA dataset for more granular analysis.
Providing reimbursement prices for drugs listed in the tariff.
Offer in-depth explanations of NHS prescribing, reimbursement, SNOMED codes, and tariff systems to build foundational knowledge.
Creating a relational database schema that simplifies querying for insights, such as cost trends, regional variations, or drug category analyses.

This database integrates data from sources like:
Drug tariff Parts VIIIA, IX, Part VIIIB, Part VIIID, and concessionary prices.
NHS Business Services Authority (BSA) prescription datasets. 
NHS Data Services for BNF SNOMED mapping


Researchers can easily perform analyses, such as:
  
Calculating total reimbursement costs by BNF chapter or region.
Comparing tariff prices vs. actual reimbursement amounts.
Identifying trends in prescription volumes by chemical substance or presentation.
Exploring regional differences in prescribing patterns via Integrated Care Boards (ICBs) and regions.

Data Sources and Linkages:
  
Prescription Data: Derived from NHS BSA PCA datasets, which include items prescribed, quantities, and costs.
Drug Tariff Prices: providing standard reimbursement prices for generic and branded drugs.
Concessionary Prices: For Part VIIIA drug tariffs where temporary concessions are granted.
Dm+d Integration: Links BNF codes to SNOMED CT codes for VMP/AMPs, enabling precise matching of products and packs.

Data is linked primarily via BNF codes, SNOMED codes, and year-month keys to ensure temporal accuracy (as prices change monthly/quarterly).

Important Notes:
  
All data is anonymized and aggregated where applicable to comply with NHS data governance.
I only used two months of data PCA, drug tariffs Part VIIIA, Part IX, Part VIIIB and Part VIIID to do this sample database. 
I have put the database PCA_drug_tariffs.sqlite in .gitignore because of the size, you will need to run scripts_load_data.R to create and load data into the database.

For in-depth knowledge:

BNF Hierarchy: Drugs are classified into Chapters (broad categories like Cardiovascular), Sections, Paragraphs, and Chemical Substances. Presentations are the specific forms (e.g., tablets) prescribed.
Reimbursement Process: Dispensers (e.g., pharmacies) are reimbursed based on the Drug Tariff. Category A/M/C prices apply to generics; For Part VIIIA drugs that goes on concession, their concessionary prices are used for reimbursement and not the tariff prices.
Concessions: Temporary price adjustments for some drugs in the Part VIIIA tariff whose tariff prices is believed to be very lower compared to the prices on the market.
Prescription Types:  Tells if the drug was prescribed as a generic, brand or as an appliance. 
dm+d: Standard for describing medicines; VMP is the generic level, AMP is branded, with packs (VMPP/AMPP) specifying sizes and units.

Database Setup
This project includes SQL scripts to create the database schema (see schema.sql in the repository). I recommend using SQLite for setup.

Installation

    1. Clone the repository:
   ```bash
   git clone https://github.com/Siriboe-Kofi-Duodu/NHS_prescriptions_drug_tariff.git
   
Set up R: 
  
o	Install R (version 4.2.2 or later) from CRAN.
o	Optionally, use RStudio for an IDE.

    2.	Install R dependencies: 
o	This project uses renv for reproducible dependency management. The required packages are: 
	dplyr (version 1.1.0) for data manipulation.
	httr (version 1.4.7) for HTTP requests.
	rvest (version 1.0.4) for web scraping.
	jsonlite (version 2.0.0) for JSON parsing.
	RSQLite (version 2.4.3) for SQLite database interactions.
o	Install renv: 

Language-R

install.packages("renv")
o	Restore the project’s dependencies from renv.lock: 

Language-R

renv::restore()

o	This installs all required packages at the correct versions.

  3.Set up the database: 
  
o	Run schema.sql in SQLite (or PostgreSQL if preferred).
o	You do not need to download any data as I sourced all the data from the website directly.
o	I used API to source the data, in a case of an update, only change the name of the year_month, example: PCA_202504, will be changed to PCA_202506, if you are updating the database with June data.
o	For concessionary prices, I scrapped the data from the Community Pharmacy England (CPE) website. You only need to change the link to the list of the final concessionary prices and the Year_Month.
o	For the drug tariffs (Part VIIIA, VIIID, VIIIB and IX), copy the link to the Excel file tariff prices you want to update. Note, if you copy the link to the CSV file instead, you may need to edit the code to read CSV files.
o	I have added all links to the datasets in the scripts_load_data.R

Database Schema

The database includes 15 tables for NHS prescription and tariff data (e.g., BNF_Presentation, Part_VIIIA ect). See schema.sql for the full schema with primary and foreign key details.
