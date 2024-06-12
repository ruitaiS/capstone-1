movie_bias <- movies$b_i_reg[match(final_holdout_test$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(final_holdout_test$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(final_holdout_test$genres, genres$genres)]
predictions <- mu + movie_bias + user_bias + genre_bias

rmse <- calculate_rmse(predictions, final_holdout_test$rating)

rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Final RMSE",
  RMSE = rmse,
  Fold = fold_index))