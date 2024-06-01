user_percentiles <- users %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  mutate(rating_percentile = percent_rank(avg_rating)*100) %>%
  mutate(decile = ntile(count, 10))

# Plot Count Percentiles
plot <- ggplot(users, aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Cumulative Density of Rating Counts",
       x = "Count",
       y = "Percentile of Users Below Count") +
  theme_minimal()+
  theme(
    text = element_text(size = 20),          # General text size
    plot.title = element_text(size = 35),    # Title text size
    axis.title = element_text(size = 30),    # Axis titles text size
    axis.text = element_text(size = 25)      # Axis text size
  )

store_plot("cum_density.png", h=1500, w=1500, plot)

# Histogram
ggplot(users, aes(x = count)) +
  geom_histogram(binwidth = 5, fill = "blue", color = "black", alpha = 0.7) +
  labs(title = "Histogram of Count Values",
       x = "Count",
       y = "Frequency") +
  theme_minimal()

# Create a box-and-whisker plot for each decile
ggplot(user_percentiles, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "Box-and-Whisker Plot by Decile",
       x = "Decile",
       y = "Count") +
  theme_minimal()
