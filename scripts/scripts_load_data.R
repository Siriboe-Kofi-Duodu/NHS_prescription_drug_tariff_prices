# Scripts.R
# Purpose: To create a SQLite database, define the schema, and load all datasets.
# This database is designed to help researchers explore key concepts in the PCA data,
# including how prescription records link to Drug Tariff prices and Concessionary prices.
# Although the example data here includes April and May 2025 for PCA, the schema
# and structure is intended to support a comprehensive dataset for research purposes.


library(readxl)
library(dplyr)
library(httr)
library(rvest)
library(jsonlite)
library(RSQLite)

#Creating the database
conn<-dbConnect(RSQLite::SQLite(), "../PCA_drug_tariffs.sqlite")


#Parsing schema.sql
sql<-paste(readLines("../schema.sql"), collapse = "\n")
statements<-strsplit(sql, ";")[[1]]
statements<-trimws(statements)
statements<-statements[nzchar(statements)]

for (stmt in statements) {
  dbExecute(conn, stmt)
}


#List of tables 
dbListTables(conn)


#Loading datasets for the database


#---------Part_VIIIA drug tariff ------------
# I sourced the data directly from the NHS BSA website: https://bit.ly/4ndqFYd

#Part_VIIIA drug tariff 

#May 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-04/Part%20VIIIA%20May%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

#Loaded the temp_file data. I added Year_month column. I divided the Basic Price by 100 because I want the unit to be pounds instead of pence
Part_VIIIA_May<- read_excel(temp_file,skip = 2)%>%
  mutate(Year_month=202505,
         `Price(£)`=`Basic Price`/100) %>%
  select(Year_month,Medicine, `Pack size`,`VMP Snomed Code`,`VMPP Snomed Code`,`Drug Tariff Category`,`Price(£)`)  # The columns I need




#April 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-03/Part%20VIIIA%20Apr%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIIA_April<-read_excel(temp_file,skip = 2) %>%
  mutate(Year_month=202504,
         `Price(£)`=`Basic Price`/100) %>%
  select(Year_month,Medicine, `Pack size`,`VMP Snomed Code`,`VMPP Snomed Code`,`Drug Tariff Category`,`Price(£)`)




#Joining Part_VIIIA_April and Part_VIIIA_May data sets as Part_VIIIA
Part_VIIIA<-rbind(Part_VIIIA_April,Part_VIIIA_May)%>%
 rename(
     Year_Month=Year_month,
     Pack_Size=`Pack size`,
     VMP_Snomed_Code=`VMP Snomed Code`,
     VMPP_Snomed_Code=`VMPP Snomed Code`,
     Drug_Tariff_Category=`Drug Tariff Category`,
     Price=`Price(£)`
  )



#---------Concessionary Prices (CP)----------------
#CP are drugs from the Part VIIIA drug tariff that are considered by CPE as having lower drug tariff prices.
#CPE then negotiate for a higher price for such drugs.
#Community Pharmacy England (CPE)
#Link to all CPs data: http://bit.ly/422ZW8t


#Scrapping April concessionary prices

apr_cp<-read_html("https://cpe.org.uk/our-news/April-2025-price-concessions-final-update/") %>%
  html_node("table") %>%         
  html_table(fill = TRUE) %>%
  slice(-1) %>%                      
  rename(Drug=X1,
         Pack_size=X2,
         Price_Concession=X3)%>%
  mutate(Year_month=202504)



# Scrapping May concessionary prices 

may_cp<-read_html("https://cpe.org.uk/our-news/may-2025-price-concessions-final-update/") %>%
  html_node("table") %>%         
  html_table(fill = TRUE) %>%
  slice(-1) %>%                      
  rename(Drug=X1,
         Pack_size=X2,
         Price_Concession=X3)%>%
  mutate(Year_month=202505)


#Joining the two datasets 
CP<-rbind(apr_cp,may_cp)%>%
  mutate(Drug = gsub("[^a-zA-Z0-9]+$", "", Drug)) #Removimg special characters 



#Adding concessionary prices(CP) to Part_VIIIA data set (matching by Year_month, Medicine/Drug and Pack size)
#Created column: "Reimbursement_price": if CP is missing (there is no CP) then use the tariff price (Price(£))
#Key Note 1: Only drugs on Part VIIIA tariff can go on concession.
#Key Note 2: NAs at column CP from the Part VIIIA table only means that the drug was not on concession that month.
#Key Note 3: If a drug goes on a concession and its granted, NHS reimburses contracted pharmacies by the concessionary price for drugs dispensed 
#Which means, if Concessionary price (CP) is granted, the tariff price will not be used for reimbursement.

Part_VIIIA<-Part_VIIIA %>%
  mutate(CP=CP$Price_Concession[match(paste0(Year_Month,Medicine,Pack_Size),paste0(CP$Year_month, CP$Drug, CP$Pack_size))],
         Reimbursement_Price =ifelse(is.na(CP)|CP=="",Part_VIIIA$Price,CP))
         
  


# --------Spot Check: Return "All good" if all Concessionary prices from the CP table were matched to Part VIIIA dataset else I want an error ------


#Filtering all CP (matched columns) from Part VIIIA
CP_check<-Part_VIIIA%>%
  filter(!is.na(CP))

#All good or error
if (all(paste0(CP$Drug, CP$Pack_size) %in% paste0(CP_check$Medicine, CP_check$Pack_Size))) {
  "All good"
} else {
  "error"
}


#---------Specials tariff (Part VIIIB and Part VIIID) ------------

#Specials are unlicensed drugs and they are both Part VIIIB and VIIID drug tariff
#Unlike Part VIIIA tariff which are updated monthly, specials tariff are updated quarterly. 



#Loading Part VIIIB Data sets 


#Feb 2025 tariff
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-01/Part%20VIIIB%20Feb%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIIB_Feb<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=202502) # Adding the tariff quarter

#May 2025 tariff
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-04/Part%20VIIIB%20May%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIIB_May<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=202505) # Adding tariff quarter



# Joining Part_VIIIB_Feb and Part_VIIIB_May
Part_VIIIB<-rbind(Part_VIIIB_Feb,Part_VIIIB_May)%>%
  mutate(Drug_Category="Part_VIIIB")



#Part VIIID Data sets 

#Feb 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-01/Part%20VIIID%20Feb%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIID_Feb<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=202502) 


#May 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-04/Part%20VIIID%20May%2025.xls.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_VIIID_May<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=202505)


# Joining Part_VIIIB_Feb and Part_VIIIB_May
Part_VIIID<-rbind(Part_VIIID_Feb,Part_VIIID_May)%>%
  mutate(Drug_Category="Part_VIIID")





#Joining Part_VIIID and Part_VIIIB

colnames(Part_VIIID)=colnames(Part_VIIIB)

specials<-rbind(Part_VIIID,Part_VIIIB)%>%
  mutate(`Basic Price`=`Basic Price`/100)%>%      ##I want the tariff price to be in £
  rename(Unit="...5",
         Pack_Size=`Pack size`,
         VMP_Snomed_Code=`VMP Snomed Code`,
         VMPP_Snomed_Code=`VMPP Snomed Code`,
         Price=`Basic Price`,
         Special_Container=`Spec Cont Ind`)


#-----------------Drug Tariff Part IX (Appliances)--------------------------

#Link:https://bit.ly/45JnDVS
#These are tariff prices set for products like dressing, strips etc.
#They are popularly known as appliances


# April 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-03/Drug%20Tariff%20Part%20IX%20April%202025.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_IX_apr25<- read_excel(temp_file)%>%
  mutate(Year_month=202404)

# May 2025
temp_file <- tempfile(fileext = ".xlsx")
GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-05/Drug%20Tariff%20Part%20IX%20May%202025_0.xlsx", write_disk(temp_file, overwrite = TRUE))

Part_IX_may25<- read_excel(temp_file)%>%
  mutate(Year_month=202405)


#colnames are equal
colnames(Part_IX_apr25)=colnames(Part_IX_may25)

#Joining Part_IX_apr25 and Part_IX_may25
Part_IX<-rbind(Part_IX_apr25,Part_IX_may25)%>%
  select(`Supplier Name`,`VMP Name`,`AMP Name`,QTY,`UOM QTY`,Price,`Product Snomed Code`,
         `Pack Snomed Code`,GTIN,`Supplier Snomed Code`,BNF)%>%
  mutate( Drug_Category="Part_IX",
          Price=Price/100)%>%
  rename(
    Supplier_Name=`Supplier Name`,
    VMP_Name=`VMP Name`,
    AMP_Name=`AMP Name`,
    UOM_QTY=`UOM QTY`,
    Product_Snomed_Code =`Product Snomed Code`,
    Pack_Snomed_Code =`Pack Snomed Code`,
    Supplier_Snomed_Code =`Supplier Snomed Code`
  )



#----------------- Prescription Cost Analysis (PCA) data  -----------------
#Metadata: https://bit.ly/4g8XRhh
#I will source the data using the NHS open data API
#API Endpoint: https://opendata.nhsbsa.net/api/3/action/
#Fetching the data might take awhile


#Getting the resources
data_name<-"prescription-cost-analysis-pca-monthly-data"
response<-GET(paste0("https://opendata.nhsbsa.net/api/3/action/package_show?id=", data_name))
resources<-fromJSON(content(response, "text"))$result$resources


#Wrapping in a function for reuse 
fetch_pca <- function(month_name, resources) {
  url <- resources$url[which(resources$name == month_name)]
  temp <- tempfile(fileext = ".csv")
  GET(url, write_disk(temp, overwrite = TRUE))
  read.csv(temp)
}

#I only need April 2025 and May 2025 datasets 
pca_apr<- fetch_pca("PCA_202504", resources)
pca_may<- fetch_pca("PCA_202505", resources)


##Joining pca_apr and pca_may and changing some data types 

pca_data<-rbind(pca_apr,pca_may)%>%
  mutate(SNOMED_CODE=as.character(SNOMED_CODE),
         REGION_CODE=as.character(REGION_CODE),
         ICB_CODE=as.character(ICB_CODE),
         BNF_PRESENTATION_CODE=as.character(BNF_PRESENTATION_CODE),
         BNF_CHEMICAL_SUBSTANCE_CODE=as.character(BNF_CHEMICAL_SUBSTANCE_CODE),
         BNF_SECTION_CODE=as.character(BNF_SECTION_CODE),
         BNF_PARAGRAPH_CODE=as.character(BNF_PARAGRAPH_CODE),
         BNF_CHAPTER_CODE=as.character(BNF_CHAPTER_CODE))




#PCA Data Manipulation.
#The hierarchy in the drug prescription groupings are:
#BNF Chapter->BNF Section->BNF Paragraph->Chemical Substance->BNF Presentation


#1. BNF Chapter
BNF_Chapter<-pca_data%>%
  distinct(BNF_CHAPTER_CODE,.keep_all = TRUE)%>%
  select(BNF_CHAPTER_CODE,BNF_CHAPTER)%>%
  rename(BNF_Chapter_Name=BNF_CHAPTER,
         BNF_Chapter_Code=BNF_CHAPTER_CODE)

#2. BNF Section
BNF_Section<-pca_data%>%
  distinct(BNF_SECTION_CODE,.keep_all = TRUE)%>%
  select(BNF_SECTION_CODE,BNF_SECTION,BNF_CHAPTER_CODE)%>%
  rename(BNF_Section_Name=BNF_SECTION,
         BNF_Section_Code=BNF_SECTION_CODE,
         BNF_Chapter_Code=BNF_CHAPTER_CODE)

#3. BNF_Paragraph
BNF_Paragraph<-pca_data%>%
  distinct(BNF_PARAGRAPH_CODE, .keep_all = TRUE)%>%
  select(BNF_PARAGRAPH_CODE,BNF_PARAGRAPH,BNF_SECTION_CODE)%>%
  rename(BNF_Paragraph_Name=BNF_PARAGRAPH,
         BNF_Paragraph_Code=BNF_PARAGRAPH_CODE,
         BNF_Section_Code=BNF_SECTION_CODE)

#Chemical Substance
Chemical_Substance<-pca_data%>%
  distinct(BNF_CHEMICAL_SUBSTANCE_CODE, .keep_all = TRUE)%>%
  select(BNF_CHEMICAL_SUBSTANCE_CODE,BNF_CHEMICAL_SUBSTANCE,BNF_PARAGRAPH_CODE)%>%
  rename(BNF_Chemical_Substance=BNF_CHEMICAL_SUBSTANCE,
         BNF_Chemical_Substance_Code=BNF_CHEMICAL_SUBSTANCE_CODE,
         BNF_Paragraph_Code=BNF_PARAGRAPH_CODE)



#BNF Presentation
BNF_Presentation<-pca_data%>%
  select( BNF_PRESENTATION_CODE,YEAR_MONTH,BNF_PRESENTATION_NAME,SNOMED_CODE,
         GENERIC_BNF_EQUIVALENT_CODE,GENERIC_BNF_EQUIVALENT_NAME,DISPENSER_ACCOUNT_TYPE,PREP_CLASS,PRESCRIBED_PREP_CLASS,
         UNIT_OF_MEASURE,SUPPLIER_NAME,BNF_CHEMICAL_SUBSTANCE_CODE,PHARMACY_ADVANCED_SERVICE,ITEMS,TOTAL_QUANTITY,NIC)%>%
  rename(Year_Month=YEAR_MONTH, 
         BNF_Presentation_Code=BNF_PRESENTATION_CODE,                                 # I am doing all these renaming because I do not want the heading to be all CAPS
         BNF_Presentation_Name=BNF_PRESENTATION_NAME,
         SNOMED_Code=SNOMED_CODE,
         Generic_BNF_Equivalent_Code=GENERIC_BNF_EQUIVALENT_CODE,
         Generic_BNF_Equivalent_Name= GENERIC_BNF_EQUIVALENT_NAME,
         Dispenser_Account_Type=DISPENSER_ACCOUNT_TYPE,
         Prep_Class=PREP_CLASS,
         Prescribed_Prep_Class=PRESCRIBED_PREP_CLASS,
         Items=ITEMS,
         Total_Quantity=TOTAL_QUANTITY,
         Unit_of_Measure=UNIT_OF_MEASURE,
         Supplier_Name=SUPPLIER_NAME,
         BNF_Chemical_Substance_Code=BNF_CHEMICAL_SUBSTANCE_CODE,
         Pharmacy_Advanced_Service=PHARMACY_ADVANCED_SERVICE) 


#Region_Name
Region<-pca_data%>%
  distinct(REGION_CODE,.keep_all = TRUE)%>%
  select(REGION_CODE,REGION_NAME)%>%
  rename(Region_Name=REGION_NAME,
         Region_Code=REGION_CODE)

##ICB 
ICB<-pca_data%>%
  distinct(ICB_CODE,.keep_all = TRUE)%>%
  select(ICB_CODE,ICB_NAME,REGION_CODE)%>%
  rename(ICB_Name=ICB_NAME,
         ICB_Code=ICB_CODE,
         Region_Code=REGION_CODE)




##-------------------------------BNF SNOMED MAPPING------------------------------------##
#LInk to dataset: https://bit.ly/4679bG8
#Snomed codes are used to identify drugs and it helps to be able to group drugs be on their.,
#Chemical substance, strength, formulations and or supplier
#The snomed codes are VMP,VMPP,AMP,AMPP
#Useful links: https://bit.ly/4679bG8, 



#Snomed mapping dataset 
temp_file<-tempfile(fileext = ".zip")

GET("https://www.nhsbsa.nhs.uk/sites/default/files/2025-07/BNF%20Snomed%20Mapping%20data%2020250718.zip", write_disk(temp_file, overwrite = TRUE))

#contents of zip file
contents<-unzip(temp_file, list = TRUE)

unzip(temp_file, exdir = tempdir())                         #unzipping and extracting the data
extracted<-list.files(tempdir(), full.names = TRUE)

#Reading the snomed codes and change of data types
snomed_codes<-readxl::read_excel(extracted[1])%>%
  mutate(`SNOMED Code`=as.character(`SNOMED Code`),
         `BNF Code`=as.character(`BNF Code`),
          VTM =as.character(VTM)
         )



#VMP (Generic concept)
VMP<-snomed_codes%>%
  filter(`VMP / VMPP/ AMP / AMPP`=="VMP")%>%
  select(`SNOMED Code`,`BNF Code`,`BNF Name`,VTM)%>%
  rename(VMP_Code=`SNOMED Code`,
         BNF_Code=`BNF Code`,
         BNF_Name =`BNF Name`,
         VTMID=VTM)

#VMPP
VMPP<-snomed_codes%>%
  filter(`VMP / VMPP/ AMP / AMPP`=="VMPP")%>%
  mutate(VMP_Code=VMP$VMP_Code[match(`BNF Code`,VMP$BNF_Code)])%>%
  select(`SNOMED Code`,VMP_Code,`DM+D: Product and Pack Description`,Pack,`Unit of Measure`,`Strength`)%>%
  rename(VMPP_Code=`SNOMED Code`,
         Unit_of_Measure=`Unit of Measure`,
         DM_D_Product_and_Pack_Description=`DM+D: Product and Pack Description`
  )

#AMP  
AMP<-snomed_codes%>%
  filter(`VMP / VMPP/ AMP / AMPP`=="AMP")%>%
  select(`SNOMED Code`,`BNF Code`,`BNF Name`,VTM)%>%
  rename(AMP_Code=`SNOMED Code`,
         BNF_Code=`BNF Code`,
         BNF_Name =`BNF Name`,
         VTMID=VTM)

##AMPP
AMPP<-snomed_codes%>%
  filter(`VMP / VMPP/ AMP / AMPP`=="AMPP")%>%
  mutate(AMP_Code=AMP$AMP_Code[match(`BNF Code`,AMP$BNF_Code)])%>%
  select(`SNOMED Code`,AMP_Code,`DM+D: Product and Pack Description`,Pack,`Unit of Measure`,`Strength`,`BNF Code`)%>%
  rename(AMPP_Code=`SNOMED Code`,
         Unit_of_Measure=`Unit of Measure`,
         BNF_Code=`BNF Code`,
         DM_D_Product_and_Pack_Description=`DM+D: Product and Pack Description`)


#VTM
VTM<-snomed_codes%>%
  distinct(VTM,.keep_all = TRUE)%>%
  select(VTM,`VTM Name`,`SNOMED Code`)%>%
  rename(VMP_Code=`SNOMED Code`,
         VTMID=VTM,
         VTM_Name=`VTM Name`)



#--------------------------Adding Columns to the BNF Presentation Table ------##
#These columns will be added to the BNF Presentation table
#Prescription_Type: Whether the drug was prescribed as a generic, brand or appliances.
#Drug category: Which drug tariff is the prescription coming from?
#Reimbursement Price: The tariff/concessionary price used for reimbursement.
#Note: If Reimbursement Price is NA, it means the product is not in the various drug tariffs.
#Market prices from suppliers are used for reimbursement in such cases.



#CATC
CATC<-Part_VIIIA%>%
  mutate(BNF_Code=VMP$BNF_Code[match(VMP_Snomed_Code, VMP$VMP_Code)])%>%
  filter(Drug_Tariff_Category=="Part VIIIA Category C")


#CATM
CATM<-Part_VIIIA%>%
  mutate(BNF_Code=VMP$BNF_Code[match(VMP_Snomed_Code, VMP$VMP_Code)])%>%
  filter(Drug_Tariff_Category=="Part VIIIA Category M")

#CATA
CATA<-Part_VIIIA%>%
  mutate(BNF_Code=VMP$BNF_Code[match(VMP_Snomed_Code, VMP$VMP_Code)])%>%
  filter(Drug_Tariff_Category=="Part VIIIA Category A")


#Specials (Part VIIID/Part VIIIB)
special_tariff<-specials%>%
  mutate(BNF_Code=VMP$BNF_Code[match(VMP_Snomed_Code, VMP$VMP_Code)])



#Adding "Prescription type" and "Reimbursement/Tariff prices"  to the BNF_Presentation table
BNF_Presentation <- BNF_Presentation %>%
  mutate(
    Prescription_Type = case_when(
      Prep_Class == "3" ~ "Brands",
      Prep_Class == "4" ~ "Appliances",
      TRUE~"Generics"
    ),
    Drug_Category= case_when(
      BNF_Presentation_Code %in% CATC$BNF_Code ~ "Category_C",
      BNF_Presentation_Code %in% CATM$BNF_Code ~ "Category_M",
      BNF_Presentation_Code %in% CATA$BNF_Code ~ "Category_A",
      BNF_Presentation_Code %in% special_tariff$BNF_Code ~ "Unlicensed_products",  # Unlicensed_products are specials (Part VIIIB and Part VIIID tariff)
      BNF_Presentation_Code %in% Part_IX$BNF ~ "Part_IX",
      TRUE ~ "Other"
    ),
    Reimbursement_Prices = case_when(
      BNF_Presentation_Code %in% CATC$BNF_Code ~ CATC$Reimbursement_Price[match(BNF_Presentation_Code,CATC$BNF_Code)],
      BNF_Presentation_Code %in% CATM$BNF_Code ~ CATM$Reimbursement_Price[match(BNF_Presentation_Code,CATM$BNF_Code)],
      BNF_Presentation_Code %in% CATA$BNF_Code ~ CATA$Reimbursement_Price[match(BNF_Presentation_Code,CATA$BNF_Code)],
      BNF_Presentation_Code %in% special_tariff$BNF_Code ~ special_tariff$Price[match(BNF_Presentation_Code,special_tariff$BNF_Code)],
      BNF_Presentation_Code %in% Part_IX$BNF ~ Part_IX$Price[match(BNF_Presentation_Code,Part_IX$BNF)]
    ))


#------------------Appending all the data to the database----

#List of tables 

dbWriteTable(conn, "specials_tariff",special_tariff,append=TRUE)
dbWriteTable(conn, "Part_VIIA_tariff",Part_VIIIA,append=TRUE)
dbWriteTable(conn, "Part_IX_tariff",Part_IX,append=TRUE)

dbWriteTable(conn, "BNF_Chapter",BNF_Chapter,append=TRUE)

dbWriteTable(conn, "BNF_Section",BNF_Section,append=TRUE)

dbWriteTable(conn, "BNF_Paragraph",BNF_Paragraph,append=TRUE)

dbWriteTable(conn, "Chemical_Substance",Chemical_Substance,append=TRUE)

dbWriteTable(conn, "BNF_Presentation",BNF_Presentation, append=TRUE)

dbWriteTable(conn, "Region",Region,append=TRUE)

dbWriteTable(conn, "ICB",ICB,append=TRUE)
dbWriteTable(conn, "VTM",VTM,append=TRUE)
dbWriteTable(conn, "VMP",VMP,append=TRUE)

dbWriteTable(conn, "VMPP",VMPP,append=TRUE)
dbWriteTable(conn, "AMP",AMP,append=TRUE)
dbWriteTable(conn, "AMPP",AMPP,append=TRUE)




#How to Query the database 
conn<-dbConnect(RSQLite::SQLite(), "PCA_drug_tariffs.sqlite")

#I want the reimbursement prices for drugs in the PCA data for April2025
pca_reimb<-dbGetQuery(conn,"SELECT Year_Month,BNF_Presentation_Name, Drug_Category,Reimbursement_Prices  
                            FROM BNF_Presentation 
                            WHERE Drug_Category !='Other' AND Year_Month=='202504' ")


#Disconnect
dbDisconnect(conn)


