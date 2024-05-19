# User Rating Count Vs. Occurrence Frequency
plot <- ggplot(users, aes(x = count)) +
  geom_histogram(binwidth = 1, color = "black", fill = "blue") +
  labs(title = "Histogram of User Rating Counts",
       x = "Rating Count",
       y = "Number of Users") +
  theme_minimal()

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

