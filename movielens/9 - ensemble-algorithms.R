user_avg <- users$avg_rating[match(test_df$userId, users$userId)]
movie_avg <- movies$avg_rating[match(test_df$movieId, movies$movieId)]

# User Movie Ensemble -----------------------------------------------------

# Equal weighting from User Avg. and the Movie Avg.
predicted <- (user_avg + movie_avg) / 2
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = "User and Movie Avg, Equal Weight Ensemble",
  RMSE = calculate_rmse(predicted, test_df$rating),
  Fold = fold_index))

# User Movie Weighted Ensemble Exploration -------------------------------

# Check which weight optimizes the RMSE
w_plot <- data.frame(w = numeric(), RMSE = numeric())
for (w in seq(0.2, 0.6, 0.0001)) {
  predicted <- w*user_avg + (1-w)*movie_avg
  w_plot <- rbind(w_plot, data.frame(
    w = w,
    RMSE = calculate_rmse(predicted, test_df$rating)))
}

plot <- qplot(w_plot$w, w_plot$RMSE, geom = "line")+
  xlab("w") +
  ylab("RMSE") +
  ggtitle("User Movie Average Weighted Ensemble Optimization")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )

print(plot)
#store_plot("weighted_ensemble_tuning.png", plot)

# Store RMSE for Optimized Weighting
# w = 0.4255 gives RMSE 0.9076019
w <- w_plot$w[which.min(w_plot$RMSE)]
predicted <- (w*user_avg + (1-w)*movie_avg)
rmse_df <- rbind(rmse_df, data.frame(
  Algorithm = paste("User Movie Avg Weighted Ensemble, w = ", w),
  RMSE = calculate_rmse(predicted, test_df$rating),
  Fold = fold_index))

# Cleanup
rm(user_avg, movie_avg, predicted, w, w_plot, plot)

#-----------------------------------------
# User Movie Average Cutoff Exploration:
# Use equal weights, unless fewer than k ratings (can use percentile instead of a number)
# Then switch over to movie or user avg

# Cutoffs don't seem to be very fruitful. Increasing just seems to increase the error.
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