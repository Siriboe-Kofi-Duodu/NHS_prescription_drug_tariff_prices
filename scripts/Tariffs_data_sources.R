#Data for Tarif prices: sourced directly from the website

#Suppress all warnings for the entire script
options(warn = -1)


#Packages
library(readxl)
library(dplyr)
library(httr)
library(rvest)
library(jsonlite)



#1. Part_VIIIA drug tariff 

temp_file <- tempfile(fileext = ".xlsx")
GET(config$Link_part_VIIIA, write_disk(temp_file, overwrite = TRUE))

#Loaded the temp_file data. I added Year_month column. I divided the Basic Price by 100 because I want the unit to be pounds instead of pence
Part_VIIIA_tariff<- read_excel(temp_file,skip = 2)%>%
  mutate(Year_month=config$yyyymm,
         `Price(£)`=`Basic Price`/100) %>%
  select(Year_month,Medicine, `Pack size`,`VMP Snomed Code`,`VMPP Snomed Code`,`Drug Tariff Category`,`Price(£)`)  # The columns I need



#Data Manipulation
Part_VIIIA<-Part_VIIIA_tariff%>%
  rename(
    Year_Month=Year_month,
    Pack_Size=`Pack size`,
    VMP_Snomed_Code=`VMP Snomed Code`,
    VMPP_Snomed_Code=`VMPP Snomed Code`,
    Drug_Tariff_Category=`Drug Tariff Category`,
    Price=`Price(£)`
  )


#2. Concessionary Prices (CP)
#Link to all CPs data: http://bit.ly/422ZW8t


#Scrapping April concessionary prices
ym_cp<-read_html(config$cp_prices_link) %>%
  html_node("table") %>%         
  html_table(fill = TRUE) %>%
  slice(-1) %>%                      
  rename(Drug=X1,
         Pack_size=X2,
         Price_Concession=X3)%>%
  mutate(Year_month=config$yyyymm)


#Data Manipulation  
CP<-ym_cp%>%
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


#3.Specials tariff (Part VIIIB and Part VIIID) 


#Loading Part VIIIB Data sets 

#Loading the tariff prices
temp_file <- tempfile(fileext = ".xlsx")
GET(config$part_VIIIB_link, write_disk(temp_file, overwrite = TRUE))

Part_VIIIB_spec<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=config$specials_yyyymm) # Adding the tariff quarter


#Data manipulation
Part_VIIIB<-Part_VIIIB_spec%>%
  mutate(Drug_Category="Part_VIIIB")


#Loading Part VIIID Data sets

##Loading the tariff prices
temp_file <- tempfile(fileext = ".xlsx")
GET(config$part_VIIID_link, write_disk(temp_file, overwrite = TRUE))

Part_VIIID_spec<-read_excel(temp_file, skip = 2)%>%
  mutate(Quarter=config$specials_yyyymm) 


#Data Manipulation
Part_VIIID<-Part_VIIID_spec%>%
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


#4. Drug Tariff Part IX (Appliances)
#Link:https://bit.ly/45JnDVS


# Fetching the Part IX tariff
temp_file <- tempfile(fileext = ".xlsx")
GET(config$Part_IX_link, write_disk(temp_file, overwrite = TRUE))

Part_IX_a<- read_excel(temp_file)%>%
  mutate(Year_month=config$yyyymm)


#Data Manipulation
Part_IX<-Part_IX_a%>%
  select(`Suppier Name`,`VMP Name`,`AMP Name`,QTY,`UOM QTY`,Price,`Product Snomed Code`,
         `Pack Snomed Code`,GTIN,`Supplier Snomed Code`,`BNF 15`,Year_month)%>%
  mutate( Drug_Category="Part_IX",
          Price=Price/100)%>%
  rename(
    Supplier_Name=`Suppier Name`,
    VMP_Name=`VMP Name`,
    AMP_Name=`AMP Name`,
    UOM_QTY=`UOM QTY`,
    Product_Snomed_Code =`Product Snomed Code`,
    Pack_Snomed_Code =`Pack Snomed Code`,
    Supplier_Snomed_Code =`Supplier Snomed Code`,
    BNF=`BNF 15`
  )


#Logg if all the extraction are successfully 
logging::loginfo(
  sprintf(
    "Successful extraction of drug tariff data from NHS website for %d and specials medicine tariff for %s",
    config$yyyymm,
    config$specials_yyyymm
  )
)

