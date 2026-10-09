#Create_Database (parsing the schema.sql)

library(RSQLite)

#Creating the database
db_path <- file.path(getwd(), "database.sqlite")
conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)

#Parsing schema.sql
sql<-paste(readLines("schema.sql"), collapse = "\n")
statements<-strsplit(sql, ";")[[1]]
statements<-trimws(statements)
statements<-statements[nzchar(statements)]

for (stmt in statements) {
  dbExecute(conn, stmt)
}


#Log successful creation of the database
logging::loginfo("schema.sql successfully parsed and database created")

