###############
# Initial Setup
###############

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")

library(tidyverse)
library(caret)
library("ggplot2")
library(tidyr)
library(dplyr)
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

# One-Hot Encode the Genres:
movielens$genre_list <- strsplit(movielens$genres, "\\|")
all_genres <- sort(unique(unlist(movielens$genre_list)))
movielens$genres_one_hot <- lapply(movielens$genre_list,
                                  function(genre_list){as.integer(all_genres %in% genre_list)})

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
movies <- distinct(train_df, movieId, title, genres_one_hot, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
users <- as.data.frame(sort(unique(train_df$userId)))
genres <- as.data.frame(sort(unique(unlist(train_df$genre_list))))
colnames(users) <- "userId"
colnames(genres) <- "genre"

# Code to check for missing or empty values in genres
# Not needed b/c we already confirmed same movieIds in both
#missing_values <- sum(sapply(train_df$genre_list, function(x) any(is.na(x))))
#empty_values <- sum(sapply(train_df$genre_list, function(x) length(x) == 0))

# Clear out partitions, df and final holdout (until needed)
rm(movies_file, ratings_file, partition, partitions, df)
rm(final_holdout_test)

#--------------------------
# Movie, User, and Genre Statistics
#TODO: If time, fix this code so that it doesn't re-add the columns if they already exist

#TODO: Might need to do the full list 
genre_count <- as.data.frame(table(unlist(train_df$genre_list)))
colnames(genre_count) <- c("genre", "count")
genres <- merge(genres, genre_count, by = "genre", all.x = TRUE)
rm(genre_count)

genre_rating_avg <- aggregate(
  data = train_df %>%
    unnest(genre_list),
  rating ~ genre_list,
  FUN = mean)
colnames(genre_rating_avg) <- c("genre", "avg_rating")
genres <- merge(genres, genre_rating_avg, by = "genre", all.x = TRUE)
rm(genre_rating_avg)

user_rating_count <- as.data.frame(table(train_df$userId))
colnames(user_rating_count) <- c("userId", "count")
users <- merge(users, user_rating_count, by = "userId", all.x = TRUE)
rm(user_rating_count)

user_rating_avg <- aggregate(rating ~ userId, data = train_df, FUN = mean)
colnames(user_rating_avg) <- c("userId", "avg_rating")
users <- merge(users, user_rating_avg, by = "userId", all.x = TRUE)
rm(user_rating_avg)

movie_rating_counts <- as.data.frame(table(train_df$movieId))
colnames(movie_rating_counts) <- c("movieId", "count")
movies <- merge(movies, movie_rating_counts, by = "movieId", all.x = TRUE)
rm(movie_rating_counts)

movie_rating_avg <- aggregate(rating ~ movieId, data = train_df, FUN = mean)
colnames(movie_rating_avg) <- c("movieId", "avg_rating")
movies <- merge(movies, movie_rating_avg, by = "movieId", all.x = TRUE)
rm(movie_rating_avg)
# ---------------------------------------------------------------------------------

# DF for Storing RMSE Results:
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

#RMSE Calculation Function:
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  differences <- predicted_ratings - actual_ratings
  squared_differences <- differences^2
  mean_squared_difference <- mean(squared_differences)
  rmse <- sqrt(mean_squared_difference)
  return(rmse)
}



