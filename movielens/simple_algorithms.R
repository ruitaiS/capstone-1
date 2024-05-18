# Random Guessing --------------------------------
# Randomly guess ratings
set.seed(1)
predicted <- sample(seq(0, 5, 0.5), size=nrow(test_df), replace=TRUE)
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Random Guess",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Avg All ---------------------------------
# Always predict the average of all ratings in the training set
predicted <- rep(mean(train_df$rating),length(test_df$rating))
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Avg All",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# User Avg ----------------------------------------
# Always predict the user's average rating in the training set
predicted <- users$avg_rating[match(test_df$userId, users$userId)]
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User Avg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Movie Avg --------------------------------------
# Always predict the movie's average rating in the training set
predicted <- movies$avg_rating[match(test_df$movieId, movies$movieId)]
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Movie Avg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# User Movie Simple Average
# Gives the average output from the User Avg. and the Movie Avg. algorithms
user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]
predicted <- (user_avg + movie_avg) / 2
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Simple User / Movie Avg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# User Movie Weighted Average Exploration
# Turns out that equal weighting, k = 0.5, is actually about as good as it gets
# did some more fine tuning, and 0.425, 0.426 gives rmse 0.9076020
# progress is progress
w_values <- seq(0.42, 0.44, 0.001)
for (w in w_values) {
  predicted <- w*user_avg + (1-w)*movie_avg
  rmse_df <- rbind(rmse_df, data.frame(
    Algorithm = paste("User / Movie Avg, w = ", w),
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

# User Movie Average Cutoff Exploration:
# Use equal weights, unless fewer than k ratings (can use percentile instead of a number)
# Then switch over to movie or user avg

# Cutoffs don't seem to be very fruitful. Increasing just seems to increase the error.
# Might be a consequence of the data, but I'm a lil short on time to explore this rabbit hole
user_rating_count <- users$count[match(test_df$userId, users$userId)]
movie_rating_count <- movies$count[match(test_df$movieId, movies$movieId)]
k_values = seq(0, 30,1)
w_values <- seq(0, 1, 0.1)

for (k in k_values) {
  for (w in w_values) {
  predicted <- ifelse(movie_rating_count > k, w*user_avg + (1-w)*movie_avg, user_avg)
  rmse_df <- rbind(rmse_df, data.frame(
    Algorithm = paste("User / Movie Avg, w = ", w, " cutoff = ", k),
    RMSE = calculate_rmse(predicted, test_df$rating)))
  }
}

# Cleanup and Display ---
rm(predicted, movie_avg, user_avg, k, k_values, movie_rating_count, user_rating_count, w, w_values)
rmse_df


# Genre Avg --------------------------------------------------
#set.seed(1)
#predicted <- sapply(test_df$genre_list, function(genre_list){
#  #TODO: More complicated per-genre weighting
#  ratings <- sapply(genre_list, function(genre){
#    genres[genres$genre == genre,]$avg_rating
#  })
#  return (mean(ratings))
#})
#rmse <- calculate_rmse(predicted, test_df$rating)
##rmse # = 1.048989
#
#rm(predicted, rmse)