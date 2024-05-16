# Genre Average Rating by User
unique_genres <- unique(unlist(train_df$genre_list))

count_user_ratings <- function(userId){
  ratings <- train_df[train_df$userId == userId, "rating"]
  print(paste("Ratings by ", userId, " : ", length(ratings)))
  return (length(ratings))
}

calc_user_avg <- function(userId){
  ratings <- train_df[train_df$userId == userId, "rating"]
  print(paste(userId, " avg : ", mean(ratings)))
  return (mean(ratings))
}

calc_genre_avg <- function(userId, genre){
  ratings <- train_df %>%
    filter(train_df$userId == userId & genre %in% train_df$genre_list) %>%
    select(rating)
  
  string <- paste(userId, " ", genre, " avg : ", mean(ratings$rating))
  print(string)
  return (mean(ratings$rating))
}

#sampled_users <- sample(unique_userIds, 1000, replace = FALSE)
sampled_users <- unique_userIds
user_genre_avgs <- data.frame(
  userId = sampled_users
)


user_genre_avgs$ratings_count = sapply(user_genre_avgs$userId, count_user_ratings)
user_genre_avgs$ratings_count_percentile <- ecdf(user_genre_avgs$ratings_count)(user_genre_avgs$ratings_count) * 100

ratings_count_percentile <- function(n){
  ecdf_values <- ecdf(user_genre_avgs$ratings_count)
  print(ecdf_values(n) * 100) 
}

ratings_count_percentile(5)

# Get the top 10 highest values
sorted_df <- user_genre_avgs[order(user_genre_avgs$ratings_count, decreasing = TRUE), ]
highest_10 <- head(sorted_df$ratings_count, 500)

# Plot the percentile graph
ggplot(user_genre_avgs, aes(x = ratings_count, y = ratings_count_percentile)) +
  geom_line(color = "skyblue") +
  labs(x = "Ratings Count", y = "Percentile of Users") +
  ggtitle("Percentile of Users by Ratings Count") +
  theme_minimal()


user_genre_avgs$overall_avg = sapply(user_genre_avgs$userId, calc_user_avg)

user_genre_avgs$action_avg = sapply(user_genre_avgs$userId, function(userId){
  calc_genre_avg(userId, "Action")
})


# Number of Ratings per Genre, by User

