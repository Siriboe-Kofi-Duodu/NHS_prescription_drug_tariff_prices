#Install renv
install.packages("renv")

#rnev
renv::init()

# Load your packages (replace with your actual packages if different)
library(readxl)
library(dplyr)
library(httr)
library(rvest)
library(jsonlite)
library(RSQLite)

# Snapshot the packages 
renv::snapshot()
