# Plot rating counts against percentile
ratings_count_percentile <- function(n) {
  ecdf_values <- ecdf(users$count)
  return(ecdf_values(n) * 100)
}

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

rm(plot, plot_data, n, percentiles, ratings_count_percentile)

# User Rating Count Vs. Occurrence Frequency
count_frequency <- as.data.frame(table(users$count))
colnames(count_frequency) = c("count", "users")
#x_breaks <- seq(0, max(count_frequency$count), by = 1000)
plot <- ggplot(count_frequency, aes(x = count, y = users)) +
  geom_bar(stat = "identity", color = "black", fill = "blue") +
  labs(title = "Histogram of User Rating Counts",
       x = "Rating Count",
       y = "Number of Users") +
  #scale_x_continuous(breaks = x_breaks) +
  theme_minimal()

# Print the plot
print(plot)

pdf(file = "graphs/ratings_counts_histogram.pdf", height = 8, width = 15)
print(plot)
dev.off()
rm(plot)

# Bar Plot of Occurrence Counts for Each Genre------------------------------------------
plot <- ggplot(genres, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = signif(count, digits = 3)), nudge_y = 1000) +  # Corrected label assignment
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")

pdf(file = "graphs/genre_counts_barplot.pdf", height = 8, width = 15)
print(plot)
dev.off()
rm(plot)

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

