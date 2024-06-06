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
                regularization_term = 0.05,
                learning_rate = 0.01){
  for (epoch in 1:epochs){
    print(epoch)
    
    #Shuffle:
    set.seed(123)
    shuffled_indices <- sample(seq_along(userIds))
    
    userIds <- userIds[shuffled_indices]
    movieIds <- movieIds[shuffled_indices]
    rs <- rs[shuffled_indices]
    
    for (i in 1:nrow(train_df)) {
      predicted_r <- sum(P[userIds[i],]*Q[movieIds[i],])
      #print(predicted_r)
      error <- rs[i] - predicted_r
      if(is.nan(error) || is.infinite(error)){
        print(paste("Epoch: ", epoch,
                    "Iteration: ", i,
                    "P: ", P[userIds[i],],
                    "Q: ", Q[movieIds[i],],
                    "Product: ", P[userIds[i],]*Q[movieIds[i],],
                    "Error: ", error))
        return ()
      }
      #TODO: Update the real Ps and Qs; this seems internal to the function only
      P[userIds[i], ] <- P[userIds[i], ] - learning_rate * (error * Q[movieIds[i], ] + regularization_term * P[userIds[i], ])
      Q[movieIds[i], ] <- Q[movieIds[i], ] - learning_rate * (error * P[userIds[i], ] + regularization_term * Q[movieIds[i], ])
    }
  }
  return(list(P = P, Q = Q))
}

print("lr 0.005, rt 0.05")
set.seed(1)
P <- initialize(nrow(users), 2, -0.5, 0.5)
rownames(P) = users$userId
Q <- initialize(nrow(movies), 2, -0.5, 0.5)
rownames(Q) = movies$movieId
s1 <- sgd(train_df, P, Q, epochs = 20, learning_rate = 0.005, regularization_term = 0.05)

print("lr 0.1, rt 0.875")
set.seed(1)
P <- initialize(nrow(users), 2, -0.5, 0.5)
rownames(P) = users$userId
Q <- initialize(nrow(movies), 2, -0.5, 0.5)
rownames(Q) = movies$movieId
s2 <- sgd(train_df, P, Q, epochs = 20, learning_rate = 0.1, regularization_term = 0.875)

print("lr 0.1, rt 1")
set.seed(1)
P <- initialize(nrow(users), 2, -0.5, 0.5)
rownames(P) = users$userId
Q <- initialize(nrow(movies), 2, -0.5, 0.5)
rownames(Q) = movies$movieId
s3 <- sgd(train_df, P, Q, epochs = 20, learning_rate = 0.1, regularization_term = 1)

print("lr 0.1, rt 1.125")
set.seed(1)
P <- initialize(nrow(users), 2, -0.5, 0.5)
rownames(P) = users$userId
Q <- initialize(nrow(movies), 2, -0.5, 0.5)
rownames(Q) = movies$movieId
s4 <- sgd(train_df, P, Q, epochs = 20, learning_rate = 0.1, regularization_term = 1.125)

#-------
predicted_residuals <- mapply(function(userId, movieId){
  sum(s1$P[userId,]*s1$Q[movieId,])
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