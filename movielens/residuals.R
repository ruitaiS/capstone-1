# Run movielens_setup.R, then biasing_effects.R prior to this file

# Residuals calculation / Prep for SVD:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(train_df$genres, genres$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

# Re-index the movieIds and userIds so they match their position in the matrix
#users$userIndex <- as.numeric(factor(users$userId))
#movies$movieIndex <- as.numeric(factor(movies$movieId))
#train_df$movieIndex <- as.numeric(factor(train_df$movieId))
#train_df$userIndex <- as.numeric(factor(train_df$userId))
#train_df$movieIndex <- as.numeric(factor(train_df$movieId))

# Test Only: Check that the indices are all consecutive, and all match
#all(diff(sort(users$userIndex)) == 1)
#all(diff(sort(movies$movieIndex)) == 1)
#all(diff(sort(unique(train_df$userIndex))) == 1)
#all(diff(sort(unique(train_df$movieIndex))) == 1)
#all(users$userIndex[match(train_df$userId, users$userId)] == train_df$userIndex)
#all(movies$movieIndex[match(train_df$movieId, movies$movieId)] == train_df$movieIndex)

# Test Only: Look up indices from ids in test_df
#users$userIndex[match(test_df$userId, users$userId)]
#movies$movieIndex[match(test_df$movieId, movies$movieId)]

fill_missing_A <- function(i, u){
  # TODO: Default Values for residuals on missing user/movie combinations
  # a) Fill in the missing ratings using the user / movie ensemble,
  # and subtract (mu + movie_bias + user_bias + genre_bias)
  
  # b) Use mu - (movie_bias + user_bias + genre_bias).
  # Mathematically I'm not sure how to justify this choice, but intuitively it seems promising
  # It might no be correct though. The residuals represent the deviation from the mean, minus biasing factors
  # This equation only gives the mean minus biasing factors.
  
  # c) Fill the missing ratings with mu, and subtract (mu + movie_bias + user_bias + genre_bias),
  # yielding r = -movie_bias - user_bias - genre_bias.
  
  # d) Fill in the missing ratings with some other value
  # and subtract (mu + movie_bias + user_bias + genre_bias)
  
  # e) b, c, d are all specific instances of the more general
  # r = alpha - (movie_bias + user_bias + genre_bias)
  # You can just tune for alpha
  
  return (0)
}

# Free up memory space
train_df <- subset(train_df, select = -c(title, timestamp, rating, date, b_i_reg, b_u_reg, b_g_reg))
movies <- subset(movies, select = -c(count, year))
users <- subset(users, select = -count)
genres <- subset(genres, select = -count)

# Test only:
train_df <- head(train_df, 1000)

# Create the residuals matrix (~8gb of memory lol)
residuals_matrix <- matrix(-1,
                           nrow = length(unique(train_df$userId)),
                           ncol = length(unique(train_df$movieId)), 
                           dimnames = list(sort(unique(train_df$userId)), sort(unique(train_df$movieId))))

train_df$userId <- factor(train_df$userId, levels = rownames(residuals_matrix))
train_df$movieId <- factor(train_df$movieId, levels = colnames(residuals_matrix))
residuals_matrix[as.matrix(train_df[, c("userId", "movieId")])] <- train_df$r

# TODO: Check this indexes properly / retrieves the value at the correct index by id



# Fun Functions (Do Not Run) -----------------------------

# Plotting the Residuals Density Plot
density_values <- density(train_df$r)
plot(density_values, main = "Density Plot of Remaining Variation", xlab = "Remainder", ylab = "Density")
polygon(density_values, col = "lightblue", border = "black")

# Comparing Residuals of Two Movies
compare_r <- function(movieId1, movieId2){
  subset <- merge(train_df[train_df$movieId == movieId1, c('movieId', 'userId', 'title', 'r')],
                  train_df[train_df$movieId == movieId2, c('movieId', 'userId', 'title', 'r')],
                  by = "userId")
  title1 <- unique(subset$title.x)[1]
  title2 <- unique(subset$title.y)[1]
  
  ggplot(subset, aes(x = r.x, y = r.y)) +
    geom_point() +
    xlab(paste(title1, " Residuals")) +
    ylab(paste(title2, " Residuals")) +
    ggtitle(paste("Comparison of Residuals for", title1, "and", title2))
}