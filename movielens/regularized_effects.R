# Regularized Movie Bias b_i with regularization parameter l1
movie_bias <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[, c("movieId", "count")], by="movieId")

# Tuning L1
l1_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)
l1_values <- seq(0, 1, 0.01)
for (l1 in l1_values){
    movie_bias$b_i <- movie_bias$sum / (movie_bias$count + l1)
    # Filter:
    movie_bias <- movie_bias %>%
      mutate(b_i = ifelse(count < 5, 0, b_i))
    bias <- movie_bias$b_i[match(test_df$movieId, movies$movieId)]
    predicted <- mu + bias
    l1_plot <- rbind(l1_plot, data.frame(
      Lambda = l1,
      RMSE = calculate_rmse(predicted, test_df$rating)))
}


qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")

# l1 = 0.08 if not filtering, 0.21 if filtering
l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]

#Store as column in train_df
movie_bias$b_i <- movie_bias$sum / (movie_bias$count + l1)
# Filter:
movie_bias <- movie_bias %>%
  mutate(filtered_b_i = ifelse(count < 100, 0, b_i))

movies <- merge(movies, movie_bias[, c("movieId", "b_i", "filtered_b_i")], by="movieId")
rm(movie_bias, l1, l1_plot, bias, l1_values, predicted)

#Regularized User Effects: -------------------------------------------------------
train_df <- merge(train_df, movies[, c("movieId", "b_i", "filtered_b_i")], by="movieId")
user_bias <- aggregate((rating-(mu + filtered_b_i)) ~ userId, data = train_df, FUN = sum) #TODO: Check filtered too
colnames(user_bias) <- c("userId", "sum")
user_bias <- merge(user_bias, users[, c("userId", "count")], by="userId")

# Tuning L2
l2_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)
l2_values <- seq(0, 10, 0.1)
for (l2 in l2_values){
  user_bias$b_u <- user_bias$sum / (user_bias$count + l2)
  # Filter:
  user_bias <- user_bias %>%
    mutate(filtered_b_u = ifelse(count < 100, 0, b_u))
  b_us <- user_bias$b_u[match(test_df$userId, user_bias$userId)]
  b_is <- movies$b_i[match(test_df$movieId, movies$movieId)]
  predicted <- mu + b_us + b_is
  l2_plot <- rbind(l2_plot, data.frame(
    Lambda = l2,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}


qplot(l2_plot$Lambda, l2_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L2 vs. RMSE")

# l1 = 0.08 if not filtering, 0.21 if filtering
l2 <- l2_plot$Lambda[which.min(l2_plot$RMSE)]

#Store as column in train_df
user_bias$b_u <- user_bias$sum / (user_bias$count + l2)
# Filter:
movie_bias <- movie_bias %>%
  mutate(filtered_b_i = ifelse(count < 100, 0, b_i))

movies <- merge(movies, movie_bias[, c("movieId", "b_i", "filtered_b_i")], by="movieId")
rm(movie_bias, l1, l1_plot, bias, l1_values, predicted)





# ---------------------------------

# Random Garbage vvvvvvv -----------------------------------------------
train_df <- merge(train_df, movie_bias, by = "movieId", all.x = TRUE)
movies <- merge(movies, movie_bias, by = "movieId", all.x = TRUE)
# Filter:
movies <- movies %>%
  mutate(b_i = ifelse(count < 100, 0, b_i))
rm(movie_bias)
# TODO: make a graph of this



#Test Code:
#b_i_test <- movie_bias$sum / movie_bias$count
#means <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
#colnames(means) <- c("movieId", "mean")
#sums <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum)
#colnames(sums) <- c("movieId", "sum")
#counts <- movies[, c("movieId", "count")]
#df <- merge(sums, counts, by="movieId")
#df <- merge(df, means, by="movieId")
#df$calculated_mean <- df$sum / df$count
#all.equal(df$calculated_mean, df$mean)
#Test: