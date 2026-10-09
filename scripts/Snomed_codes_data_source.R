#BNF SNOMED MAPPING: This feeds BNF SNOMED Codes to the database
#Data Source: https://bit.ly/4679bG8

#Suppress all warnings for the entire script
options(warn = -1)

#Packages 
library(readxl)
library(dplyr)
library(httr)
library(rvest)
library(jsonlite)


#Snomed mapping dataset 
temp_file<-tempfile(fileext = ".zip")

GET(config$Snomed_codes_link, write_disk(temp_file, overwrite = TRUE))

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

logging::loginfo("Snomed Codes Successfully extracted from NHS website")



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

