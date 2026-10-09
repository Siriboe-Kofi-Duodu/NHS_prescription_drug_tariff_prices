#Final pipeline that feeds all the data to the database

#Suppress all warnings for the entire script
options(warn = -1)

#Packages 
library(DBI)
library(RSQLite)



#DATA MANIPULATION FROM THE VARIOUS SOURCES

#Adding Columns to the BNF Presentation Table ------##
#These columns will be added to the BNF Presentation table
#Prescription_Type: Whether the drug was prescribed as a generic, brand or appliances.
#Drug category: Which drug tariff is the prescription coming from?
#Reimbursement Price: The tariff/concessionary price used for reimbursement.
#Note: If Reimbursement Price is NA, it means the product is not in the various drug tariffs.



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


#Changing some datatypes 
CATC$Reimbursement_Price<-is.numeric(CATC$Reimbursement_Price)
CATM$Reimbursement_Price<-is.numeric(CATM$Reimbursement_Price)
CATA$Reimbursement_Price<-is.numeric(CATA$Reimbursement_Price)


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


#Connect to database
conn <- DBI::dbConnect(RSQLite::SQLite(), "../database.sqlite")
logging::loginfo("Database connection active")

#Feed all data to the database

push_all<-function(conn){
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
}






