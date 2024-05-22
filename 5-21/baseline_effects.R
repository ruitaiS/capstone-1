# Movie Bias b_i
movie_bias <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
colnames(movie_bias) <- c("movieId", "b_i")
movies <- merge(movies, movie_bias, by = "movieId", all.x = TRUE)
# Filter:
movies <- movies %>%
  mutate(b_i = ifelse(count < 100, 0, b_i))
rm(movie_bias)
train_df <- merge(train_df, movie_bias, by = "movieId", all.x = TRUE)
# TODO: make a graph of this

# User Bias b_u
user_bias <- aggregate((rating-(b_i + mu)) ~ userId, data = train_df, FUN = mean)
colnames(user_bias) <- c("userId", "b_u")
train_df <- merge(train_df, user_bias, by = "userId", all.x = TRUE)
users <- merge(users, user_bias, by = "userId", all.x = TRUE)
# Filter:
users <- users %>%
  mutate(b_u = ifelse(count < 5, 0, b_u))
rm(user_bias)
# TODO: make a graph of this

# Genre Bias (Method A)
# (A) Each cluster of genres is considered "one" instance
genre_bias <- aggregate((rating-(b_i + b_u + mu)) ~ genres, data = train_df, FUN = mean)
colnames(genre_bias) <- c("genre", "b_g")
genre_groups <- merge(genre_groups, genre_bias, by = "genre", all.x = TRUE)
# Filter:
genre_groups <- genre_groups %>%
  mutate(b_g = ifelse(count < 1000, 0, b_g))
# TODO: Filter users and movies too
#train_df <- merge(train_df, genre_bias, by = "genres", all.x = TRUE)
rm(genre_bias)
# TODO: make a graph of this

# Genre Bias (Method B)
#TODO: This is too slow
# (B) Each member of a genre cluster is split into its own entry
# The genre bias for a movie is a weighted average of it's genres
#genre_bias <- aggregate((rating-(b_i + b_u + mu)) ~ genre_list,
#                        data = train_df%>%
#                          unnest(genre_list),
#                        FUN = mean)
#colnames(genre_bias) <- c("genre", "b_g")
#genres <- merge(genres, genre_bias, by = "genre", all.x = TRUE)
#train_df$b_g <- sapply(train_df$genre_list, function(genre_list){
#  matching_effects <- genres$b_g[!is.na(match(genres$genre, genre_list))]
#  return(mean(matching_effects))
#})
#rm(genre_bias)
# TODO: make a graph of this
