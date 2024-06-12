# Find residuals after using tuned values for l1, l2, l3

l1 <- (1.947 + 2.347 + 2.083 + 2.272 + 2.151) / 5
l2 <- (4.836 + 4.974 + 4.859 + 4.959 + 5.307) / 5
l3 <- (27.167 + 15.209 + 12.262 + 4.07) / 5
mu <- mean(train_df$rating)

tuning_df <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
  setNames(c("movieId", "sum")) %>%
  merge(movies[,c('movieId', 'count')], by="movieId")
movies$b_i_reg <- tuning_df$sum / (tuning_df$count + l1)
train_df <- merge(train_df, movies[,c('movieId', 'b_i_reg')], by="movieId")

tuning_df <- aggregate((rating-(mu+b_i_reg)) ~ userId, data = train_df, FUN = sum) %>%
  setNames(c("userId", "sum")) %>%
  merge(users[,c('userId', 'count')], by="userId")
users$b_u_reg <- tuning_df$sum / (tuning_df$count + l2)
train_df <- merge(train_df, users[,c('userId', 'b_u_reg')], by="userId")

tuning_df <- aggregate((rating-(mu+b_i_reg+b_u_reg)) ~ genres, data = train_df, FUN = sum) %>%
  setNames(c("genres", "sum")) %>%
  merge(genres[,c('genres', 'count')], by="genres")
genres$b_g_reg <- tuning_df$sum / (tuning_df$count + l3)
train_df <- merge(train_df, genres[,c('genres', 'b_g_reg')], by="genres")

# Cleanup
rm(l1, l2, l3, tuning_df)

# Residuals calculation:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(train_df$genres, genres$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

#-----------------------------

# Plotting the Residuals Density Plot
#density_values <- density(train_df$r)
#plot(density_values, main = "Density Plot of Remaining Variation", xlab = "Remainder", ylab = "Density")
#polygon(density_values, col = "lightblue", border = "black")

# Comparing Residuals of Two Movies
#compare_r <- function(movieId1, movieId2){
#  subset <- merge(train_df[train_df$movieId == movieId1, c('movieId', 'userId', 'title', 'r')],
#                  train_df[train_df$movieId == movieId2, c('movieId', 'userId', 'title', 'r')],
#                  by = "userId")
#  title1 <- unique(subset$title.x)[1]
#  title2 <- unique(subset$title.y)[1]
#  
#  ggplot(subset, aes(x = r.x, y = r.y)) +
#    geom_point() +
#    xlab(paste(title1, " Residuals")) +
#    ylab(paste(title2, " Residuals")) +
#    ggtitle(paste("Comparison of Residuals for", title1, "and", title2))
#}