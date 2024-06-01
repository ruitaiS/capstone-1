# Ratings Count Analysis




# BS / Scrap------------------------

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

#----------
# Percentile Analysis
density_values <- density(users$count)
plot(density_values, main = "Density Plot of Rating Counts", xlab = "Remainder", ylab = "Density")
polygon(density_values, col = "lightblue", border = "black")



#---------
# user_percentile <- users
# user_percentiles$percentile <- ecdf(users$count)(users$count) * 100

ratings_count_percentile <- function(n) {
  ecdf_values <- ecdf(users$count)
  return(ecdf_values(n) * 100)
}

# Plot rating counts against percentile
n <- seq(0, max(users$count), by = 1)
percentiles <- sapply(n, ratings_count_percentile)
plot_data <- data.frame(
  n = n,
  percentile = percentiles)

ggplot(plot_data, aes(x = n, y = percentile)) +
  geom_line(color = "blue") +
  labs(title = "Percentile of Rating Counts",
       x = "Rating Count",
       y = "Percentile") +
  theme_minimal()




#-------

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

