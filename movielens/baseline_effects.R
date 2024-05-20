mu <- mean(train_df$rating)

# Movie Bias b_i
movie_bias <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
colnames(movie_bias) <- c("movieId", "b_i")
movies <- merge(movies, movie_bias, by = "movieId", all.x = TRUE)
rm(movie_bias)

# User Bias b_u
user_bias <- aggregate((rating-mu) ~ userId, data = train_df, FUN = mean)
colnames(user_bias) <- c("userId", "b_u")
users <- merge(users, user_bias, by = "userId", all.x = TRUE)
rm(user_bias)