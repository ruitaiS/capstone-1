# TODO: Time Bias
# TODO: Something still isn't quite right here.
# The regularized and non-regularized values for users and genres should be the same
# since l2 and l3 are optimized at 0. But they are not the same. Find out why.

# Unregularized Movie Bias
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "b_i_0")) %>%
  merge(movies, by="movieId")
train_df <- merge(train_df, movies[,c('movieId', 'b_i_0')], by="movieId")
# TODO: Plot

# Unregularized User Bias
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "b_u_0")) %>%
  merge(users, by="userId")
train_df <- merge(train_df, users[,c('userId', 'b_u_0')], by="userId")
# TODO: Plot

# Unregularized Genre Group Bias
genre_groups <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean) %>%
  setNames(c("genres", "b_g_0")) %>%
  merge(genre_groups, by="genres")
train_df <- merge(train_df, genre_groups[,c('genres', 'b_g_0')], by="genres")
# TODO: Plot

#----------
# Predict with Unregularized Biases
movie_bias <- movies$b_i_0[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_0[match(test_df$userId, users$userId)]
genre_bias <- genre_groups$b_g_0[match(test_df$genres, genre_groups$genres)]

# Movie Bias Only:
predicted <- mu + movie_bias# + user_bias + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Movie + User Bias:
predicted <- mu + movie_bias + user_bias# + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Movie, User, and Genre Bias:
predicted <- mu + movie_bias + user_bias + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_0 + b_u_0 + b_g_0",
  RMSE = calculate_rmse(predicted, test_df$rating)))

rm(movie_bias, user_bias, genre_bias, predicted)

# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l1_values <- seq(0, 1, 0.01)
for (l1 in l1_values){
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  predicted <- mu + movie_bias
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

# TODO: Export
qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")

l1 <- l1_values[which.min(l1_plot$RMSE)]

# Store
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")

rm(tuning_df, l1, l1_values, l1_plot, movie_bias, predicted)

#--------
# l2 tuning for user bias:
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l2_values <- seq(0, 1, 0.01)
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
for (l2 in l2_values){
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  predicted <- mu + movie_bias + user_bias
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

# TODO: Export
qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")

l2 <- l2_values[which.min(l2_plot$RMSE)]

# Store
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")

rm(tuning_df, l2, l2_values, l2_plot, movie_bias, user_bias, predicted)
#--------
# l3 tuning for genre bias:
tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genre_groups[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_values <- seq(0, 1, 0.01)
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
for (l3 in l3_values){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  predicted <- mu + movie_bias + user_bias + genre_bias
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

# TODO: Export
qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")

l3 <- l3_values[which.min(l3_plot$RMSE)]

# Store
genre_groups$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genre_groups[,c('genres', 'b_g_reg')], by="genres")

rm(tuning_df, l3, l3_values, l3_plot, movie_bias, user_bias, genre_bias, predicted)

#----------
# Predict with Regularized Biases
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]
genre_bias <- genre_groups$b_g_reg[match(test_df$genres, genre_groups$genres)]

# Movie Bias Only:
predicted <- mu + movie_bias# + user_bias + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Movie + User Bias:
predicted <- mu + movie_bias + user_bias# + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Movie, User, and Genre Bias:
predicted <- mu + movie_bias + user_bias + genre_bias
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(predicted, test_df$rating)))

rm(movie_bias, user_bias, genre_bias, predicted)

# -----------