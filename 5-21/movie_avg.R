predicted <- sapply(test_df$movieId, function(movieId){
  movies[movies$movieId == movieId,]$avg_rating
})
rmse <- calculate_rmse(predicted, test_df$rating)
rmse # = 0.9283148

rm(predicted, rmse)