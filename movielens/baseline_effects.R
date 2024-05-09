#TODO:
#Caching results
#Genre specific effects
#Code for time binning

mu <- mean(train_df$rating)

#Regularization Parameters for b_i and b_u respectively
l1 <- 25
l2 <- 10

b_i <- function(movieId){
  print(movieId)
  movie_ratings <- train_df[train_df$movieId == movieId,]$rating
  return (sum(movie_ratings - mu) / (l1 + length(movie_ratings)))
}

b_i_cache <- data.frame(movieId = unique_movieIds, b_i = sapply(unique_movieIds, b_i))

b_u <- function(userId){
  print(userId)
  user_history <- train_df[train_df$userId == userId,]
  return (sum(user_history$rating - b_i_cache[b_i_cache$movieId == user_history$movieId, 'b_i'] - mu) / (l2 + length(user_history)))
}

b_u_cache = data.frame(userId = unique_userIds, b_u = sapply(unique_userIds, b_u))

predict_baseline <- function(movieId, userId){
  return (mu + b_i_cache[b_i_cache$movieId == movieId, 'b_i'] + b_u_cache[b_u_cache$userId == userId, 'b_u'])
}

baseline_predictions <- apply(test_df, 1, function (row){
  print(row[['movieId']])
  print(row[['userId']])
  #print(predict_baseline('1527', '6'))
  #print(predict_baseline(as.integer(row[['movieId']]), as.integer(row[['userId']])))
  return (predict_baseline(as.integer(row[['movieId']]), as.integer(row[['userId']])))
})

baseline_rmse <- calculate_rmse(baseline_predictions, test_df[order(test_df$userId), 'rating'])
#RMSE ~ 0.895, 0.939