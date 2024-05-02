# Set the working directory to the directory containing the script
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

if(!file.exists("../datasets/ml-10M100K/ratings.dat") | !file.exists("../datasets/ml-10M100K/movies.dat")){
  if(!file.exists("../datasets/ml-10M100K.zip"))
    download.file("https://files.grouplens.org/datasets/movielens/ml-10m.zip", "../datasets/ml-10M100K.zip")
  
  unzip("../datasets/ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/ratings.dat")
  unzip("../datasets/ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/movies.dat")
  
  file.remove("../datasets/ml-10M100K.zip")
}