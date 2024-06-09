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

# Cleanup
rm(predicted)