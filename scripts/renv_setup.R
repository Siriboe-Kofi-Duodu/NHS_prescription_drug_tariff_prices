#Install renv
install.packages("renv")

#rnev
renv::init()

# Loading packages 
library(readxl)
library(dplyr)
library(httr)
library(rvest)
library(jsonlite)
library(RSQLite)

# Snapshotting the packages 
renv::snapshot()
