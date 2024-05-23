###############
# Initial Setup
###############

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(mlpack)) install.packages("mlpack")

library(mlpack)
library(tidyverse)
library(caret)
library("ggplot2")
library(tidyr)
library(dplyr)
library(lubridate)
options(timeout = 120)

# Set working directory to the directory containing this script
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Check for movies and ratings files
ratings_file = "../datasets/ml-10M100K/ratings.dat"
movies_file = "../datasets/ml-10M100K/movies.dat"
if(!(file.exists(ratings_file) & file.exists(movies_file))){
  # Download MovieLens 10M dataset:
  # https://grouplens.org/datasets/movielens/10m/
  # http://files.grouplens.org/datasets/movielens/ml-10m.zip
  download.file("https://files.grouplens.org/datasets/movielens/ml-10m.zip", "ml-10M100K.zip")
  unzip("ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/ratings.dat")
  unzip("ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/movies.dat")
  file.remove("ml-10M100K.zip")
}

###################################################
# Create main and final_holdout_test sets 
# Note: this process could take a couple of minutes
###################################################

ratings <- as.data.frame(str_split(read_lines(ratings_file), fixed("::"), simplify = TRUE),
                         stringsAsFactors = FALSE)
colnames(ratings) <- c("userId", "movieId", "rating", "timestamp")
ratings <- ratings %>%
  mutate(userId = as.integer(userId),
         movieId = as.integer(movieId),
         rating = as.numeric(rating),
         timestamp = as.integer(timestamp))

movies <- as.data.frame(str_split(read_lines(movies_file), fixed("::"), simplify = TRUE),
                        stringsAsFactors = FALSE)
colnames(movies) <- c("movieId", "title", "genres")
movies <- movies %>%
  mutate(movieId = as.integer(movieId))

movielens <- left_join(ratings, movies, by = "movieId")

# Create a rating Date column
movielens$date <- as_datetime(movielens$timestamp)

# Exploratory Test: Remove Movies with Fewer Than 5
#movielens <- movielens %>%
#  group_by(movieId) %>%
#  filter(n() >= 5) %>%
#  ungroup()

# Exploratory Test: Remove Users with Fewer than 100
#movielens <- movielens %>%
#  group_by(userId) %>%
#  filter(n() >= 100) %>%
#  ungroup()

# One-Hot Encode the Genres:
#movielens$genre_list <- strsplit(movielens$genres, "\\|")
#all_genres <- sort(unique(unlist(movielens$genre_list)))
#movielens$genres_one_hot <- lapply(movielens$genre_list,
#                                  function(genre_list){as.integer(all_genres %in% genre_list)})

# Final hold-out test set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(1) # if using R 3.5 or earlier
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
df <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in final hold-out test set are also in main set
final_holdout_test <- temp %>% 
  semi_join(df, by = "movieId") %>%
  semi_join(df, by = "userId")

# Add rows removed from final hold-out test set back into main set
removed <- anti_join(temp, final_holdout_test)
df <- rbind(df, removed)

rm(ratings, movies, test_index, temp, movielens, removed, all_genres)

#########################################################

# Train / Test DF Creation: -------------------------------------------------------

partition <- function (seed, subset_p = 1, test_p = 0.2){
  set.seed(seed)
  #Create a subset of the full training set to save calculation time if necessary
  subset_index <- createDataPartition(y = df$rating, times = 1, p = subset_p, list = FALSE)
  subset <- df[subset_index,]
  test_index <- createDataPartition(y = subset$rating, times = 1, p = test_p, list = FALSE)
  
  train_df <- subset[-test_index,]
  test_df <- subset[test_index,] %>% 
    semi_join(train_df, by = "movieId") %>%
    semi_join(train_df, by = "userId")
  train_df <- rbind(train_df, anti_join(subset[test_index,], final_holdout_test))
  return(list(train = train_df, test = test_df))
}


#Create train + test sets from a subset of the full train set
partitions <- partition(seed = 1, subset_p = 1)
train_df <- partitions$train
test_df <- partitions$test

#Create dfs for movies, users, and genres
#movies <- distinct(train_df, movieId, title, genres_one_hot, .keep_all=FALSE) %>% arrange(movieId)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))

users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))

genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))

# Cleanup
rm(movies_file, ratings_file, partition, partitions, df)
rm(final_holdout_test)

#--------------------------
# Movie, User, and Genre Statistics
#TODO: If time, fix this code so that it doesn't re-add the columns if they already exist

# Average of All Ratings
mu <- mean(train_df$rating)

# Add ratings counts by genre, user, and movie
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Add average ratings by genre, user, and movie
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
# ---------------------------------------------------------------------------------

# DF for Storing RMSE Results:
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

# RMSE Calculation Function:
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  differences <- predicted_ratings - actual_ratings
  squared_differences <- differences^2
  mean_squared_difference <- mean(squared_differences)
  rmse <- sqrt(mean_squared_difference)
  return(rmse)
}

# Plot Export Function:
store_plot <- function(filename, h = 1500, w = 1500, plot){
  png(file = paste("graphs/", filename, sep=""), height = h, width = w)
  print(plot)
  dev.off()
}



# Remove a column
# df <- subset(df, select = -column_name)


