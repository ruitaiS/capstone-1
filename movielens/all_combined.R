# edx_template.R

##########################################################
# Create edx and final_holdout_test sets 
##########################################################

# Note: this process could take a couple of minutes

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")

library(tidyverse)
library(caret)

# MovieLens 10M dataset:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip

options(timeout = 120)

# Slightly modified from template code for directory structuring
# Set working directory to the directory containing this script
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
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

# Final hold-out test set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(1) # if using R 3.5 or earlier
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in final hold-out test set are also in edx set
final_holdout_test <- temp %>% 
  semi_join(edx, by = "movieId") %>%
  semi_join(edx, by = "userId")

# Add rows removed from final hold-out test set back into edx set
removed <- anti_join(temp, final_holdout_test)
edx <- rbind(edx, removed)

# Slightly Modified Cleanup
rm(ratings, movies, test_index, temp, movielens, removed, movies_file, ratings_file)

# setup.R ----------------------------------------------------------------------------

if(!require(ggplot2)) install.packages("ggplot2", repos = "http://cran.us.r-project.org")
if(!require(tidyr)) install.packages("tidyr", repos = "http://cran.us.r-project.org")
if(!require(dplyr)) install.packages("dplyr", repos = "http://cran.us.r-project.org")
if(!require(lubridate)) install.packages("lubridate", repos = "http://cran.us.r-project.org")
if(!require(purrr)) install.packages("purrr", repos = "http://cran.us.r-project.org")
if(!require(reshape2)) install.packages("reshape2", repos = "http://cran.us.r-project.org")

library(ggplot2)
library(tidyr)
library(dplyr)
library(lubridate)
library(purrr)
library(reshape2)

# Make sure the same movies and users are in both sets
consistency_check <- function(test, train){
  # Note it makes the test set smaller
  updated_test <- test %>% 
    semi_join(train, by = "movieId") %>%
    semi_join(train, by = "userId")
  updated_train <- rbind(train, anti_join(test, updated_test))
  return (list(updated_test, updated_train))
}

# K-fold Cross Validation; k = 5
set.seed(2, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(2) # if using R 3.5 or earlier
folds <- createFolds(edx$rating, k = 5, list = TRUE, returnTrain = FALSE)
generate_splits <- function(index){
  return (consistency_check(edx[folds[[index]],], edx[-folds[[index]],]))
}

# RMSE Calculation Function:
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  errors <- predicted_ratings - actual_ratings
  squared_errors <- errors^2
  mean_of_squared_errors <- mean(squared_errors)
  rmse <- sqrt(mean_of_squared_errors)
  return(rmse)
}

# Function to write plots to file
store_plot<- function(filename, plot, h = 6, w = 12) {
  res <- 300
  height <- h * res
  width <- w * res
  png(file = paste("graphs/", filename, sep = ""), height = height, width = width, res = res)
  print(plot)
  dev.off()
}

# DF for Storing Results:
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      Fold = numeric(),
                      stringsAsFactors = FALSE)

# prepare_data.R ----------------------------------------------------------------------------

# ------------------------------------------------------------------
# Use full Edx Set
# (Used for user, genre, movie analysis sections)
train_df <- edx

# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#---------------------------------------------------------------------------

# user_analysis.R

user_percentiles <- users %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  mutate(rating_percentile = percent_rank(avg_rating)*100) %>%
  mutate(decile = ntile(count, 10))%>%
  mutate(user_percentile_group = ifelse(decile == 10, "upper", "lower"))

# Plot Count Percentiles-------------------------------------------------------------------
#plot <- ggplot(users, aes(x = count)) +
#  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
#  labs(title = "Cumulative Density of Rating Counts",
#       x = "Count",
#       y = "Percentile of Users") +
#  theme_minimal()+
#  theme(
#    text = element_text(size = unit(2, "mm")),
#    plot.title = element_text(size = unit(20, "mm")),
#    axis.title = element_text(size = unit(15, "mm")),
#    axis.text = element_text(size = unit(10, "mm"))
#  )
#print(plot)
#store_plot("cum_density.png", plot)
#rm(plot)

# Create a box-and-whisker plot for each decile--------------------------------------------
plot <- ggplot(user_percentiles, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "User Rating Counts by Decile",
       x = "Decile",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("box-whisker-decile_users.png", plot)
rm(plot)

# Bottom 90% CDF----------------------------------------------------------------------------
plot <- ggplot(user_percentiles[user_percentiles$count_percentile<=90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "User Rating Counts CDF (Bottom 90%)",
       x = "Count",
       y = "Percentile of Users") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("counts_cdf_bottom90_users.png", plot, h = 6, w = 6)
rm(plot)

# Top 10% CDF----------------------------------------------------------------------------
plot <- ggplot(user_percentiles[user_percentiles$count_percentile>90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "User Rating Counts CDF (Top 10%)",
       x = "Count",
       y = "Percentile of Users") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("counts_cdf_top10_users.png", plot, h = 6, w = 6)
rm(plot)

# Average Rating Density Plot----------------------------------------------------------------------------
#density_values <- density(users$avg_rating)
#store_plot("avg_rating_density_users.png", {
#  plot(density_values, main = "Density Plot of User's Average Ratings", xlab = "Average Rating", ylab = "Density")
#  polygon(density_values, col = "lightblue", border = "black")  
#})
#rm(density_values)

# Cleanup
rm(user_percentiles)

# ------------------------------------------------------------------------------

# genre_analysis.R

# Individual Genres 
genres_individual <- as.data.frame(table(unlist(strsplit(train_df$genres, "\\|"))))
colnames(genres_individual) <- c("genre", "count")

# Unnecessarily complex way to change "(no genres listed)" to "None"
# so the bar plot labels don't overlap
plot_df <- genres_individual
plot_df$genre <- as.character(plot_df$genre) # Convert to character because can't directly edit factors
plot_df$genre[genres_individual$genre == "(no genres listed)"] <- "None"
plot_df$genre <- as.factor(plot_df$genre) # Convert back to factor because you can't plot characters

# Genre Counts Barplot
plot <- ggplot(plot_df, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = count), nudge_y = 80000) +
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(8, "mm"))
  )
print(plot)
#store_plot("genre_counts_barplot.png", plot, w=13)
rm(plot, plot_df)

# Co-Occurrence Heat Map -----------------------------------------------------------
co_occurrence_genre_list <- train_df$genres %>% lapply(function(genres) {
  genre_list <- unlist(strsplit(as.character(genres), "\\|"))
  if (length(genre_list) == 0) {
    # Remove empty genre_lists (Probably unnecessary)
    return(NULL)
  } else if (length(genre_list) == 1) {
    # Duplicate for single genre movies (eg. [Action] becomes [Action, Action])
    return(rep(genre_list, 2)) 
  } else {
    # Preserve genre_list with two or more elements
    return(genre_list)
  }
})

# Initialize co-occurrence matrix with the genre names as indices
co_occurrence_matrix <- matrix(0,
                               nrow = length(genres_individual$genre),
                               ncol = length(genres_individual$genre),
                               dimnames = list(rev(genres_individual[order(-genres_individual$count), ]$genre),
                                               genres_individual[order(-genres_individual$count), ]$genre))

# Populate co-occurrence matrix
for (genre_list in co_occurrence_genre_list) {
  if (length(genre_list) == 2){
    co_occurrence_matrix[genre_list[1], genre_list[2]] <- co_occurrence_matrix[genre_list[1], genre_list[2]] + 1
    co_occurrence_matrix[genre_list[2], genre_list[1]] <- co_occurrence_matrix[genre_list[2], genre_list[1]] + 1
  }else{
    for (i in 1:(length(genre_list) - 1)) {
      for (j in (i+1):length(genre_list)) {
        co_occurrence_matrix[genre_list[i], genre_list[j]] <- co_occurrence_matrix[genre_list[i], genre_list[j]] + 1
        co_occurrence_matrix[genre_list[j], genre_list[i]] <- co_occurrence_matrix[genre_list[j], genre_list[i]] + 1
      }
    } 
  }
}
rm(genre_list, i, j)

# Optionally Normalize the rows and pass it into the heatmap function
#co_occurrence_matrix<- t(apply(co_occurrence_matrix, 1, function(x) x / sum(x)))

# Plot
reversed <- co_occurrence_matrix[, ncol(co_occurrence_matrix):1]
plot_df <- melt(sqrt(reversed + 1))
plot <- ggplot(plot_df, aes(x=Var1, y=Var2, fill=value)) +
  geom_tile() +
  scale_fill_gradientn(colors = rev(heat.colors(256))) +
  labs(title = "Genre Co-occurrence", x = NULL, y = NULL) +
  guides(fill = FALSE) +
  theme_minimal() +
  theme(
    text = element_text(size = 8),
    plot.title = element_text(size = 20),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 10),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(plot)
#store_plot("genre_co_occurrence_heatmap.png", plot, h = 6, w = 6)
#store_plot("normalized_genre_co_occurrence_heatmap.png", plot, h = 6, w = 6)

# Cleanup
rm(genres_individual, plot_df, co_occurrence_genre_list, co_occurrence_matrix, row_normalized_matrix, reversed, plot)

#################################################################################
# movie_analysis.R
#################################################################################
plot <- ggplot(movies, aes(x = year, y = avg_rating)) +
  geom_point() +
  labs(title = "Average Movie Rating By Release Year",
       x = "Release Year",
       y = "Average Movie Rating") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("movie_rating_by_release_year.png", plot)

# Cleanup
rm(movieIds, movieId_groups, create_scatterplots, scatterplots_list)

#################################################################################
# ratings_analysis.R
#################################################################################

plot <- ggplot(train_df, aes(x = rating)) +
  geom_histogram(binwidth = 0.5, fill = "lightblue", color = "black") +
  geom_vline(aes(xintercept = mu), color = "red", linetype = "dashed", size = 1) +
  labs(title = "Histogram of Ratings",
       x = "Rating",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("rating_histogram.png", plot)
rm(plot)

#################################################################################
# Reset Data for Fold 1
#################################################################################

fold_index = 1

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 1
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# simple_algorithms.R
#################################################################################

# Random Guessing --------------------------------
# Randomly guess ratings
set.seed(3, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(3) # if using R 3.5 or earlier
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Random Guess",
  RMSE = calculate_rmse(
    sample(seq(0, 5, 0.5), size=nrow(test_df), replace=TRUE),
    test_df$rating),
  Fold = fold_index))

# Avg All ---------------------------------
# Always predict the average of all ratings in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Avg All",
  RMSE = calculate_rmse(
    rep(mu,length(test_df$rating)),
    test_df$rating),
  Fold = fold_index))

# Genre Avg --------------------------------------------------
predicted <- sapply(test_df$genres, function(genre_string){
  return (genres[genres$genres == genre_string,]$avg_rating)
})
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Genre Avg",
  RMSE = calculate_rmse(predicted, test_df$rating),
  Fold = fold_index))

# User Avg ----------------------------------------
# Always predict the user's average rating in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User Avg",
  RMSE = calculate_rmse(
    users$avg_rating[match(test_df$userId, users$userId)],
    test_df$rating),
  Fold = fold_index))

# Movie Avg --------------------------------------
# Always predict the movie's average rating in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Movie Avg",
  RMSE = calculate_rmse(
    movies$avg_rating[match(test_df$movieId, movies$movieId)],
    test_df$rating),
  Fold = fold_index))

# User Movie Equal Weight Ensemble -----------------------------------------------------
user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]
predicted <- (user_avg + movie_avg) / 2
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User and Movie Avg, Equal Weight Ensemble",
  RMSE = calculate_rmse(predicted, test_df$rating),
  Fold = fold_index))

# Cleanup
rm(user_avg, movie_avg, predicted)

#################################################################################
# ensemble_tuning.R
#################################################################################

user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]

# Tune weight to optimize the RMSE
w_plot <- data.frame(w = numeric(), RMSE = numeric())
for (w in seq(0.2, 0.6, 0.0001)) {
  predicted <- w*user_avg + (1-w)*movie_avg
  w_plot <- rbind(w_plot, data.frame(
    w = w,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

plot <- qplot(w_plot$w, w_plot$RMSE, geom = "line")+
  xlab("w") +
  ylab("RMSE") +
  ggtitle("User Movie Average Weighted Ensemble Optimization")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot("weighted_ensemble_tuning.png", plot)

# Store RMSE for Optimized Weighting -----------------------------------------
# w = 0.4255 gives RMSE 0.9076019
w <- w_plot$w[which.min(w_plot$RMSE)]
predicted <- (w*user_avg + (1-w)*movie_avg)
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = paste("User Movie Avg Weighted Ensemble, w = ", w),
  RMSE = calculate_rmse(predicted, test_df$rating),
  Fold = fold_index))

# Cleanup
rm(user_avg, movie_avg, predicted, w, w_plot, plot)

#################################################################################
# unregularized_biasing_effects.R
#################################################################################

# Unregularized Movie Bias
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "b_i_0")) %>%
  merge(movies, by="movieId")
train_df <- merge(train_df, movies[,c('movieId', 'b_i_0')], by="movieId")

# Unregularized User Bias
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "b_u_0")) %>%
  merge(users, by="userId")
train_df <- merge(train_df, users[,c('userId', 'b_u_0')], by="userId")

# Unregularized Genre Bias
genres <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean) %>%
  setNames(c("genres", "b_g_0")) %>%
  merge(genres, by="genres")
train_df <- merge(train_df, genres[,c('genres', 'b_g_0')], by="genres")

# Predict with Unregularized Biases -----------------------------------------------------------------------------
movie_bias <- movies$b_i_0[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_0[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_0[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0 + b_g_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
movies <- select(movies, subset = -b_i_0)
users <- select(users, subset = -b_u_0)
genres <- select(genres, subset = -b_g_0)
train_df <- select(train_df, subset = -c(b_i_0, b_u_0, b_g_0))
rm(movie_bias, user_bias, genre_bias)

#################################################################################
# bias_regularization_tuning.R
#################################################################################

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

for (l3 in l3_sequences[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)

#################################################################################
# Reset Data for Fold 2
#################################################################################

fold_index = 2

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 2
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# Bias Regularization on Fold 2
#################################################################################

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

for (l3 in l3_sequences[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)

#################################################################################
# Reset Data for Fold 3
#################################################################################

fold_index = 3

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 2
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# Bias Regularization on Fold 3
#################################################################################

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

for (l3 in l3_sequences[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)

#################################################################################
# Reset Data for Fold 4
#################################################################################

fold_index = 4

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 2
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# Bias Regularization on Fold 4
#################################################################################

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

for (l3 in l3_sequences[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)

#################################################################################
# Reset Data for Fold 5
#################################################################################

fold_index = 5

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 2
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# Bias Regularization on Fold 5
#################################################################################

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

for (l3 in l3_sequences[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)

#################################################################################
# Reset Data for Final Residuals and Results Calculation
# Note as mentioned in the report, training was accidentally done on fold_index 1
# rather than the full edx set. That sequence is preserved here
#################################################################################

fold_index = 1

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)

# Reset for fold 2
# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)

#################################################################################
# residuals.R
#################################################################################

l1 <- (1.947 + 2.347 + 2.083 + 2.272 + 2.151) / 5
l2 <- (4.836 + 4.974 + 4.859 + 4.959 + 5.307) / 5
l3 <- (27.167 + 15.209 + 12.262 + 4.07) / 5
mu <- mean(train_df$rating)

tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")

tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")

# Cleanup
rm(l1, l2, l3, tuning_df)

# Residuals calculation:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(train_df$genres, genres$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

#################################################################################
# final_rmse.R
#################################################################################
movie_bias <- movies$b_i_reg[match(final_holdout_test$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(final_holdout_test$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(final_holdout_test$genres, genres$genres)]
predictions <- mu + movie_bias + user_bias + genre_bias

rmse <- calculate_rmse(predictions, final_holdout_test$rating)