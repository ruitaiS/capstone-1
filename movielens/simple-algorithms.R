# Random Guessing --------------------------------
# Randomly guess ratings
set.seed(1)
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Random Guess",
  RMSE = calculate_rmse(
    sample(seq(0, 5, 0.5), size=nrow(test_df), replace=TRUE),
    test_df$rating)))

# Avg All ---------------------------------
# Always predict the average of all ratings in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Avg All",
  RMSE = calculate_rmse(
    rep(mu,length(test_df$rating)),
    test_df$rating)))

plot <- ggplot(train_df, aes(x = rating)) +
  geom_histogram(binwidth = 0.5, fill = "lightblue", color = "black") +
  labs(title = "Histogram of Rating Frequencies",
       x = "Rating",
       y = "Frequency") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("rating_histogram.png", plot)

# User Avg ----------------------------------------
# Always predict the user's average rating in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User Avg",
  RMSE = calculate_rmse(
    users$avg_rating[match(test_df$userId, users$userId)],
    test_df$rating)))

# Movie Avg --------------------------------------
# Always predict the movie's average rating in the training set
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Movie Avg",
  RMSE = calculate_rmse(
    movies$avg_rating[match(test_df$movieId, movies$movieId)],
    test_df$rating)))

# User Movie Ensemble -----------------------------------------------------
user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]

# Equal weighting from User Avg. and the Movie Avg.
predicted <- (user_avg + movie_avg) / 2
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User and Movie Avg, Equal Weight Ensemble",
  RMSE = calculate_rmse(predicted, test_df$rating)))

# User Movie Weighted Ensemble Exploration
# Check which weight optimizes the RMSE
w_plot <- data.frame(w = numeric(),
                     RMSE = numeric(),
                     stringsAsFactors = FALSE)
for (w in seq(0.2, 0.6, 0.0001)) {
  predicted <- w*user_avg + (1-w)*movie_avg
  w_plot <- rbind(w_plot, data.frame(
    w = w,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

store_plot("weighted_ensemble_tuning.png",
           qplot(w_plot$w, w_plot$RMSE, geom = "line")+
             xlab("W") +
             ylab("RMSE") +
             ggtitle("User / Movie Average Weighted Ensemble Optimization")+
             theme_minimal()+
             theme(
               text = element_text(size = unit(2, "mm")),          # General text size
               plot.title = element_text(size = unit(20, "mm")),    # Title text size
               axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
               axis.text = element_text(size = unit(10, "mm"))      # Axis text size
             ))

# Store RMSE for Optimized Weighting
# w = 0.4255 gives RMSE 0.9076019
w <- w_plot$w[which.min(w_plot$RMSE)]
predicted <- (w*user_avg + (1-w)*movie_avg)
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = paste("User and Movie Avg Weighted Ensemble, w = ", w),
  RMSE = calculate_rmse(predicted, test_df$rating)))

# Cleanup
rm(user_avg, movie_avg, predicted, w, w_plot)

#-----------------------------------------
# User Movie Average Cutoff Exploration:
# Use equal weights, unless fewer than k ratings (can use percentile instead of a number)
# Then switch over to movie or user avg

# Cutoffs don't seem to be very fruitful. Increasing just seems to increase the error.
# Might be a consequence of the data, but I'm a lil short on time to explore this rabbit hole
#user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
#movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]
#user_rating_count <- users$count[match(test_df$userId, users$userId)]
#movie_rating_count <- movies$count[match(test_df$movieId, movies$movieId)]
#k_values = seq(0, 30,1)
#w_values <- seq(0.42, 0.44, 0.001)

#for (k in k_values) {
#  for (w in w_values) {
#  predicted <- ifelse(user_rating_count > k, w*user_avg + (1-w)*movie_avg, movie_avg)
#  rmse_df <- rbind(rmse_df, data.frame(
#    Algorithm = paste("User Movie Weighted Ensemble, w = ", w, " user rating count cutoff = ", k),
#    RMSE = calculate_rmse(predicted, test_df$rating)))
#  }
#}

#rm(k, k_values, w, w_values, user_avg, movie_avg, user_rating_count, movie_rating_count, predicted)

# Remove these from rmse df:
#rmse_df <- head(rmse_df, 26)

# Genre Avg --------------------------------------------------
set.seed(1)
predicted <- sapply(test_df$genres, function(genre_string){
  return (genres[genres$genres == genre_string,]$avg_rating)
})
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "Genre Avg",
  RMSE = calculate_rmse(predicted, test_df$rating)))