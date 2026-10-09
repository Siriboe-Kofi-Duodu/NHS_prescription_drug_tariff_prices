#Main Script to run to update the database: 

#Install dependencies
source("scripts/requirements.R")


#Read yaml file configuration (input file)
config_path<-file.path("input","config.yaml")
config<-yaml::read_yaml(config_path)

config["time_stamp"]<-format(Sys.Date(), "%Y%m%d")



#Setting up logging
logging::basicConfig(level = "INFO")

logging::addHandler(
  logging::writeToFile,
  file = file.path("outputs", "logs.log"),
  level = "INFO"
)


#Referencing data pipeline script
source("scripts/create_database.R")
source("scripts/Tariffs_data_sources.R")
source("scripts/Snomed_codes_data_source.R")
source("scripts/PCA_data.R")
source("scripts/data_pipeline.R")


#Feed the data to the Database
push_all(conn)



