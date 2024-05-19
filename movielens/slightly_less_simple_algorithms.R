similarity <- function (g1, r1, g2, r2, w = 1){
  # Euclidian distance between one-hot genre encoding vectors
  # Weighted difference between ratings of the two movies
  differences <- g1 - g2 + w(r1 - r2)
  squared_differences <- differences^2
  sum_squared_difference <- sum(squared_differences)
  distance <- sqrt(sum_squared_difference)
  return(distance)
}

# This is an unreasonably memory intensive approach
similarity_matrix <- matrix(0,
                            nrow = length(movies_knn$movieId),
                            ncol = length(movies_knn$movieId),
                            dimnames = list(movies_knn$movieId, movies_knn$movieId)
)

#--------------------
# Given a movie, create an ordered list of all the other movies based on similarity
# Pick the N most similar movies
  # Refinement: If the user has rated any of those movies, replace the average rating with the user's rating
# Predict the rating of that movie will be an average of those similar movies
  # Refinement: weight the average based on the similarity





movies_knn <- distinct(train_df, userId, movieId, genres_one_hot, rating, .keep_all=FALSE) %>% arrange(movieId)

# Given a user and a movie, return the avg of the most similar movies that user has rated

rm(movies_knn)