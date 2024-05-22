#----------
# Predict with Effects instead of Averages
movie_bias <- movies$b_i[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u[match(test_df$userId, users$userId)]
genre_bias <- genre_groups$b_g[match(test_df$genres, genre_groups$genre)]
predicted <- mu + movie_bias# + user_bias + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Only Movie Effects",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Tweak effect weighting
a_values = seq(0.5, 1.5, 0.1)
b_values <- seq(0.5, 1.5, 0.1)
for (a in a_values) {
  for (b in b_values) {
    predicted <- mu + a*movie_bias + b*user_bias
    rmse_df <- rbind(rmse_df, data.frame(
      Algorithm = paste("User / Movie Effects, a = ", a, " b = ", b),
      RMSE = calculate_rmse(predicted, test_df$rating)))
  }
}



# User / movie effects, final holdout
#TODO: Train on the full training set too; not just the partitioned one
movie_bias <- movies$b_i[match(final_holdout_test$movieId, movies$movieId)]
user_bias <- users$b_u[match(final_holdout_test$userId, users$userId)]
predicted <- mu + movie_bias + user_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Simple User / Movie Effects, final_holdout",
  RMSE = calculate_rmse(predicted, final_holdout_test$rating)))

# Cleanup and Display ---
rm(predicted, movie_avg, user_avg, k, k_values, movie_rating_count, user_rating_count, w, w_values)
rmse_df


