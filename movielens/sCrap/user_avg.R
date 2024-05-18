predicted <- sapply(test_df$userId, function(userId){
  users[users$userId == userId,]$avg_rating
})
rmse <- calculate_rmse(predicted, test_df$rating)
rmse # = 0.8764618

rm(predicted, rmse)