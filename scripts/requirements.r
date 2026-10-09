# Install dependencies
if (!requireNamespace("librarian", quietly = TRUE)) {
  install.packages("librarian", quiet = TRUE)
}

if(!requireNamespace("librarian")) install.packages("librarian", quiet=TRUE)

requirements<-c(
    "logging",
    "yaml",
    "readxl",
    "dplyr",
    "httr",
    "rvest",
    "jsonlite",
    "RSQLite"
)

#Suppress warnings
suppressWarnings(librarian::stock(requirements))

