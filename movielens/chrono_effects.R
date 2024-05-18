# By Movie

# Time Binning Ratings in train_df

min(train_df$timestamp)
max(train_df$timestamp)

df <- train_df

df$date <- as.Date(df$timestamp, origin = "1970-01-01")

# Extract week from the date
df$week <- lubridate::week(df$date)

# Group by movieId and week, calculate average rating
avg_ratings <- df %>%
  group_by(movieId, week) %>%
  summarise(avg_rating = mean(rating, na.rm = TRUE)) %>%
  ungroup()

# Plot the average ratings against each other
ggplot(avg_ratings, aes(x = week, y = avg_rating, color = as.factor(movieId))) +
  geom_line() +
  labs(title = "Average Ratings by Week for Each Movie",
       x = "Week",
       y = "Average Rating",
       color = "Movie ID") +
  theme_minimal()




---

# ? What is the trend for popularity (rating / period) over time?
# ? What is the trend for movie ratings over time?
	# ? Is this generally linear? Is it worth binning?


# By Genre

# ? Are some genres more popular during certain times of the year?
# ? Are some genres more highly rated during certain times of the year?
