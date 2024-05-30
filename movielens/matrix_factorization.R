initialize <- function(rows, k, min_val, max_val) {
  random_values <- matrix(runif(rows * k, min = min_val, max = max_val), nrow = rows)
  return(random_values)
}

predict <- function(userId, movieId, P, Q){
  #print(paste0("User ", userId, " Movie ", movieId))
  
  # R hat i, j is the dot product of P row i, Q row j
  return (sum(P[as.character(userId), ]*Q[as.character(movieId), ]))
}

loss <- function(predicted, actual){
  return (actual - predicted)
}

set.seed(1)
P <- initialize(69878, 2, -1, 1)
rownames(P) = users$userId
Q <- initialize(10677, 2, -1, 1)
rownames(Q) = movies$movieId

#sgd <- function(train_df, P, Q, iterations = 100, subset_p = 0.1){
#  #TODO
#  # Iterate given number of times
#    # Pick a subset of the training df according to subset_p size
#    predicted <- predict(subset$userId, subset$movieId, P, Q)
#    loss <- loss(predicted, actual)
#    # Adjust the corresponding rows of P and Q - P[as.character(userId), ], Q[as.character(movieId), ] to better fit the prediction
#}

sgd <- function(train_df, P, Q, iterations = 10, subset_p = 0.01, learning_rate = 0.01, regularization_term = 1){
  num_samples <- nrow(train_df)
  num_subset <- round(num_samples * subset_p)
  
  for (iter in 1:iterations) {
    print(iter)
    # Pick a random subset of the training df
    subset_indices <- sample(num_samples, num_subset, replace = FALSE)
    subset <- train_df[subset_indices, ]
    
    # Predict ratings for the subset
    predicted <- mapply(predict, subset$userId, subset$movieId, MoreArgs = list(P = P, Q = Q))
    actual <- subset$r
    
    # Update P and Q using gradients
    for (i in 1:num_subset) {
      user_id <- as.character(subset$userId[i])
      movie_id <- as.character(subset$movieId[i])
      
      user_index <- match(user_id, rownames(P))
      movie_index <- match(movie_id, rownames(Q))
      
      print(paste("P: ",P[user_index, ], " Q: ", Q[movie_index, ]))
      
      error <- predicted[i] - actual[i]
      print(paste("Predicted: ", predicted[i], " Actual: ", actual[i], "Error: ",error))
      
      P[user_index, ] <- P[user_index, ] - learning_rate * (error * Q[movie_index, ] + regularization_term * P[user_index, ])
      Q[movie_index, ] <- Q[movie_index, ] - learning_rate * (error * P[user_index, ] + regularization_term * Q[movie_index, ])
    }
  }
  
  return(list(P = P, Q = Q))
}


# Takes about 10 minutes
predictions <- mapply(predict, test_df$userId, test_df$movieId, MoreArgs = list(P = P, Q = Q))
