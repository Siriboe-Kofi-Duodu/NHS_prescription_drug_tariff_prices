# Scripts.R
# Purpose: Load PCA data via API to be fed into database.sqlite)

library(dplyr)
library(httr)
library(jsonlite)




#---Prescription Cost Analysis (PCA) data  
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

PCA_yyyymm<-paste0("PCA_", config$yyyymm)



#Choose the year_month you want to update: PCA_yyyymm (change this in Main.R)
pca_ym<- fetch_pca(PCA_yyyymm, resources)


logging::loginfo(
  sprintf(
    "Successfully extracted PCA data for %d using NHS API",
    config$yyyymm
  ))


logging::loginfo("PCA_data.R: Cleaning and data validating the PCA data")
##Joining pca_apr and pca_may and changing some data types 
pca_data<-pca_ym%>%
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


logging::loginfo("PCA_data.R: Data validated and Cleaned")