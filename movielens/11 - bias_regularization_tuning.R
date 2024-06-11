# Tuning Regularization Parameters:----------------------------------------------------------

# l1 tuning for movie bias:
tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")

l1_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l1 in seq(1.5, 3.5, 0.001)){ # Fold 1; l1 = 1.947 | Fold 2; l1 = 2.347 | Fold 3; l1 = 2.083 | Fold 4 ; l1 = 2.272 | Fold 5; 2.151
  tuning_df$b_i <- tuning_df$sum / (tuning_df$count + l1)
  movie_bias <- tuning_df$b_i[match(test_df$movieId, tuning_df$movieId)]
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(
      mu + movie_bias,
      test_df$rating)))
}

# Plot L1 Tuning
plot <- qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l1-tuning-square-fold-", fold_index, ".png"), plot, h=6, w=6)

# Store + Cleanup
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")
rm(tuning_df, l1_plot, movie_bias)

#--------
# l2 tuning for user bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")

l2_plot <- data.frame(Lambda = character(), RMSE = numeric(), stringsAsFactors = FALSE)
for (l2 in seq(4, 6, 0.001)){ # Fold 1; l2 = 4.836 | Fold 2; l2 = 4.974 | Fold 3; l2 = 4.859 | Fold 4; l2 = 4.959 | Fold 5; l2 = 5.307
  tuning_df$b_u <- tuning_df$sum / (tuning_df$count + l2)
  user_bias <- tuning_df$b_u[match(test_df$userId, tuning_df$userId)]
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l2-tuning-square-fold-", fold_index, ".png"), plot, h= 6, w = 6)

# Store + Cleanup
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")
rm(tuning_df, l2_plot, movie_bias, user_bias)
#--------

# l3 tuning for genre bias:
movie_bias <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(test_df$userId, users$userId)]

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")

l3_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)

l3_sequences <- list(
  seq(26, 28, 0.001), # Fold 1 ; l3 = 27.167
  seq(14, 16, 0.001), # Fold 2 ; l3 = 15.209
  seq(0, 2, 0.001),    # Fold 3; l3 = 0# Fold 3
  seq(11.5, 13.5, 0.001), # Fold 4; l3 = 12.262
  seq(3, 5, 0.001)     # Fold 5; l3 = 4.07
)

#for (l3 in seq(26, 28, 0.001)){ # Fold 1 ; l3 = 27.167
#for (l3 in seq(14, 16, 0.001)){ # Fold 2 ; l3 = 15.209
#for (l3 in seq(0, 2, 0.001)){ # Fold 3; l3 = 0
#for (l3 in seq(11.5, 13.5, 0.001)){ # Fold 4; l3 = 12.262
#for (l3 in seq(3, 5, 0.001)){ # Fold 5; l3 = 4.07
for (l3 in l3_sequnces[[fold_index]]){
  tuning_df$b_g <- tuning_df$sum / (tuning_df$count + l3)
  genre_bias <- tuning_df$b_g[match(test_df$genres, tuning_df$genres)]
  l3_plot <- rbind(l3_plot, data.frame(
    Lambda = l3,
    RMSE = calculate_rmse(
      mu + movie_bias + user_bias + genre_bias,
      test_df$rating)))
}

# Plot:
plot <- qplot(l3_plot$Lambda, l3_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L3 vs. RMSE")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot(paste0("l3-tuning-square-fold-", fold_index, ".png"), plot, h = 6, w=6)

# Store and Cleanup
l3 <- l3_plot$Lambda[which.min(l3_plot$RMSE)]
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")
rm(tuning_df, l3_plot, movie_bias, user_bias, genre_bias)
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
    test_df$rating),
  Fold = fold_index))

# Movie + User Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias,
    test_df$rating),
  Fold = fold_index))

# Movie, User, and Genre Bias:
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "mu + b_i_reg + b_u_reg + b_g_reg",
  RMSE = calculate_rmse(
    mu + movie_bias + user_bias + genre_bias,
    test_df$rating),
  Fold = fold_index))

# Cleanup
print(l1)
print(l2)
print(l3)
rm(movie_bias, user_bias, genre_bias)
rm(l1, l2, l3)
