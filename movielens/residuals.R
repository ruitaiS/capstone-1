# Run movielens_setup.R, then biasing_effects.R prior to this file

# Residuals calculation / Prep for SVD:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genre_groups$b_g_reg[match(train_df$genres, genre_groups$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

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

compare_r(1, 300)

#---#
