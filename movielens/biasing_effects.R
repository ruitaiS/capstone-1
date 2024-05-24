# TODO: Time Bias
# TODO: Something still isn't quite right here.
# The regularized and non-regularized values for users and genres should be the same
# since l2 and l3 are optimized at 0. But they are not the same. Find out why.

# Unregularized Movie Bias
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "b_i_0")) %>%
  merge(movies, by="movieId")
train_df <- merge(train_df, movies[,c('movieId', 'b_i_0')], by="movieId")

# Plot
density_values <- density(movies$b_i_0)
store_plot("unregularized_movie_bias.png", plot = {
  plot(density_values, main = "Density Plot of Unregularized Movie Effects", xlab = "b_i_0", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")
  }, h=1000, w = 1000
)
rm(density_values)

# Unregularized User Bias
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "b_u_0")) %>%
  merge(users, by="userId")
train_df <- merge(train_df, users[,c('userId', 'b_u_0')], by="userId")

# Plot
density_values <- density(users$b_u_0)
store_plot("unregularized_user_bias.png", plot = {
  plot(density_values, main = "Density Plot of Unregularized User Effects", xlab = "b_u_0", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")
}, h=1000, w = 1000
)
rm(density_values)

# Unregularized Genre Bias
genres <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean) %>%
  setNames(c("genres", "b_g_0")) %>%
  merge(genres, by="genres")
train_df <- merge(train_df, genres[,c('genres', 'b_g_0')], by="genres")

# Plot
density_values <- density(genres$b_g_0)
store_plot("unregularized_genre_bias.png", plot = {
  plot(density_values, main = "Density Plot of Unregularized Genre Effects", xlab = "b_g_0", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")
}, h=1000, w = 1000
)
rm(density_values)

#----------
# Predict with Unregularized Biases
movie_bias <- movies$b_i_0[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_0[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_0[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating)))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating)))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0 + b_g_0",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating)))

# Cleanup
rm(movie_bias, user_bias, genre_bias)

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

for (l1 in seq(0, 1, 0.01)){
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
store_plot("movie_bias_tuning.png",
           qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
             xlab("Lambda") +
             ylab("RMSE") +
             ggtitle("Lambda L1 vs. RMSE"),
           h=1000, w = 1000
)

# Store
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")

# Plot Regularized Density
density_values <- density(movies$b_i_reg)
store_plot("regularized_movie_bias.png", plot = {
  plot(density_values, main = "Density Plot of Regularized Movie Effects", xlab = "b_i_reg", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")
}, h=1000, w = 1000
)
rm(density_values)

rm(tuning_df, l1, l1_plot, movie_bias)

#TODO: b_i_0 - b_i_reg vs. count plot

#--------
# l2 tuning for user bias:
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
for (l2 in seq(0, 1, 0.01)){
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
store_plot("user_bias_tuning.png",
           qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
             xlab("Lambda") +
             ylab("RMSE") +
             ggtitle("Lambda L2 vs. RMSE"),
           h = 1000, w = 1000
           )

l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]

# Store
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")

rm(tuning_df, l2, l2_plot, movie_bias, user_bias)

# Note: Even though l2 is optimized at 0, b_u_reg != b_u_0
# This is because we're basing it on b_i_reg, not b_i_0
#--------

# l3 tuning for genre bias:
tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
for (l3 in seq(0, 1, 0.01)){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
store_plot("genre_bias_tuning.png",
           qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
             xlab("Lambda") +
             ylab("RMSE") +
             ggtitle("Lambda L3 vs. RMSE"),
           h = 1000, w = 1000
)

l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]

# Store
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")

rm(tuning_df, l3, l3_plot, movie_bias, user_bias, genre_bias)

# Note: Like with l2, even though l3 is optimized at 0, b_g_reg != b_g_0
# This is because we're basing it on b_i_reg and b_u_reg, not b_i_0 and b_u_0

#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(test_df$genres, genres$genres)]

# Movie Bias Only:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(
    mu + movie_bias,
    test_df$rating)))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating)))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating)))

rm(movie_bias, user_bias, genre_bias)

# -----------