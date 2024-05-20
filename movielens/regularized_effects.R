# Regularized Movie Bias b_i with regularization parameter l1
movie_bias <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum)
colnames(movie_bias) <- c("movieId", "sum")
movie_bias <- merge(movie_bias, movies[, c("movieId", "count")], by="movieId")

# Tuning L1
l1_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)
l1_values <- seq(-1, 1, 0.01)
for (l1 in l1_values){
    movie_bias$b_i <- movie_bias$sum / (movie_bias$count + l1)
    # Filter:
    movie_bias <- movie_bias %>%
      mutate(b_i = ifelse(count < 100, 0, b_i))
    bias <- movie_bias$b_i[match(test_df$movieId, movies$movieId)]
    predicted <- mu + bias
    l1_plot <- rbind(l1_plot, data.frame(
      Lambda = l1,
      RMSE = calculate_rmse(predicted, test_df$rating)))
}


qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda vs. RMSE")

l1 <- l1_plot$Lambda[which.min(l1_plot$RMSE)]




train_df <- merge(train_df, movie_bias, by = "movieId", all.x = TRUE)
movies <- merge(movies, movie_bias, by = "movieId", all.x = TRUE)
# Filter:
movies <- movies %>%
  mutate(b_i = ifelse(count < 100, 0, b_i))
rm(movie_bias)
# TODO: make a graph of this



#Test:
b_i_test <- movie_bias$sum / movie_bias$count
means <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
colnames(means) <- c("movieId", "mean")
sums <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum)
colnames(sums) <- c("movieId", "sum")
counts <- movies[, c("movieId", "count")]
df <- merge(sums, counts, by="movieId")
df <- merge(df, means, by="movieId")
df$calculated_mean <- df$sum / df$count
all.equal(df$calculated_mean, df$mean)
#Test: