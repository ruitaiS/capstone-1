library(Matrix)

initialize <- function(rows, k, min_val, max_val) {
  random_values <- matrix(runif(rows * k, min = min_val, max = max_val), nrow = rows)
  return(random_values)
}

set.seed(1)
P <- initialize(nrow(users), 2, -0.5, 0.5)
rownames(P) = users$userId
Q <- initialize(nrow(movies), 2, -0.5, 0.5)
rownames(Q) = movies$movieId

# Extract Values as columns ahead of time for efficiency
userIds <- as.character(train_df$userId)
movieIds <- as.character(train_df$movieId)
rs <- train_df$r


sgd <- function(train_df, P, Q,
                epochs = 10,
                regularization_term = 0.5,
                learning_rate = 0.1){
  for (epoch in 1:epochs){
    print(paste("Epoch: ", epoch))
    for (i in 1:nrow(train_df)) {
      userId <- userIds[i]
      movieId <- movieIds[i]
      actual_r <- rs[i]
      predicted_r <- sum(P[userId,]*Q[movieId,])
      #print(paste("P: ", P[userId,],
      #            "Q: ", Q[movieId,],
      #            "Product: ", P[userId,]*Q[movieId,]))
      #print(predicted_r)
      error <- actual_r - predicted_r
      abs <- abs(error)
      if (abs < 0.1){
        print("-------")  
      }else{
        print('')
      }
      
      if(is.nan(error) || is.infinite(error)){
        return ()
      }
      
      #P[userId, ] <- P[userId, ] - learning_rate * error * Q[movieId, ]
      #Q[movieId, ] <- Q[movieId, ] - learning_rate * error * P[userId, ]
      
      # Regularized
      P[userId, ] <- P[userId, ] - learning_rate * (error * Q[movieId, ] + regularization_term * P[userId, ])
      Q[movieId, ] <- Q[movieId, ] - learning_rate * (error * P[userId, ] + regularization_term * Q[movieId, ])
    }
  }
}

sgd(train_df, P, Q, learning_rate = 0.1, regularization_term = 0.25)


#-------
predicted_residuals <- mapply(function(userId, movieId){
  sum(P[userId,]*Q[movieId,])
}, as.character(test_df$userId), as.character(test_df$movieId))

movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

predictions <- mu + movie_bias + user_bias + genre_bias + predicted_residuals

rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Biasing + SGD",
  RMSE = calculate_rmse(
    predictions,
    test_df$rating)))