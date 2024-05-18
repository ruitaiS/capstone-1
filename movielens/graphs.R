# User Rating Count Vs. Rating Avg
ggplot(users, aes(x = avg_rating, y = count)) +
  geom_point() +
  labs(title = "Scatterplot of Count vs Avg Rating",
       x = "Average Rating",
       y = "Count") +
  theme_minimal()

#Movie Rating Count Vs. Rating Avg
ggplot(movies, aes(x = avg_rating, y = count)) +
  geom_point() +
  labs(title = "Scatterplot of Count vs Avg Rating",
       x = "Average Rating",
       y = "Count") +
  theme_minimal()

#Movie Rating Vs. Timestamp (useless/unreadable)
ggplot(train_df, aes(x = timestamp, y = rating)) +
  geom_point() +
  labs(title = "Rating Vs. Time",
       x = "Timestamp",
       y = "Rating") +
  theme_minimal()

