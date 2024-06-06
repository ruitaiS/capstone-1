# Unregularized Movie Bias
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "b_i_0")) %>%
  merge(movies, by="movieId")
train_df <- merge(train_df, movies[,c('movieId', 'b_i_0')], by="movieId")

# Unregularized User Bias
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "b_u_0")) %>%
  merge(users, by="userId")
train_df <- merge(train_df, users[,c('userId', 'b_u_0')], by="userId")

# Unregularized Genre Bias
genres <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean) %>%
  setNames(c("genres", "b_g_0")) %>%
  merge(genres, by="genres")
train_df <- merge(train_df, genres[,c('genres', 'b_g_0')], by="genres")

# Predict with Unregularized Biases -----------------------------------------------------------------------------
movie_bias <- movies$b_i_0[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_0[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_0[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0 + b_g_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Plot
#density_values <- density(movies$b_i_0)
#store_plot("unregularized_movie_bias.png", plot = {
#  plot(density_values, main = "Density Plot of Unregularized Movie Effects", xlab = "b_i_0", ylab = "Density")
#  polygon(density_values, col = "lightblue", border = "black")
#  }, h=1000, w = 1000
#)
#rm(density_values)

# Plot
#density_values <- density(users$b_u_0)
#store_plot("unregularized_user_bias.png", plot = {
#  plot(density_values, main = "Density Plot of Unregularized User Effects", xlab = "b_u_0", ylab = "Density")
#  polygon(density_values, col = "lightblue", border = "black")
#}, h=1000, w = 1000
#)
#rm(density_values)

# Plot
#density_values <- density(genres$b_g_0)
#store_plot("unregularized_genre_bias.png", plot = {
#  plot(density_values, main = "Density Plot of Unregularized Genre Effects", xlab = "b_g_0", ylab = "Density")
#  polygon(density_values, col = "lightblue", border = "black")
#}, h=1000, w = 1000
#)
#rm(density_values)

# Cleanup
movies <- select(movies, subset = -b_i_0)
users <- select(users, subset = -b_u_0)
genres <- select(genres, subset = -b_g_0)
train_df <- select(train_df, subset = -c(b_i_0, b_u_0, b_g_0))
rm(movie_bias, user_bias, genre_bias)