movie_percentiles <- movies %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  mutate(rating_percentile = percent_rank(avg_rating)*100) %>%
  mutate(decile = ntile(count, 10))%>%
  mutate(movie_percentile_group = ifelse(decile == 10, "upper", "lower"))

# Plot Count Percentiles-------------------------------------------------------------------
plot <- ggplot(movies, aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Cumulative Density of Rating Counts",
       x = "Count",
       y = "Percentile of Movies") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("cum_density_movies.png", plot)
rm(plot)

# Create a box-and-whisker plot for each decile--------------------------------------------
plot <- ggplot(movie_percentiles, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "Movie Rating Counts by Decile",
       x = "Decile",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("box-whisker-decile_movies.png", plot)
rm(plot)

# Bottom 90% CDF----------------------------------------------------------------------------
plot <- ggplot(movie_percentiles[movie_percentiles$count_percentile<=90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Movie Rating Counts CDF (Bottom 90%)",
       x = "Count",
       y = "Percentile of Movies") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("counts_cdf_bottom90_movies.png", plot, h = 6, w = 6)
rm(plot)

# Top 10% CDF----------------------------------------------------------------------------
plot <- ggplot(movie_percentiles[movie_percentiles$count_percentile>90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Movie Rating Counts CDF (Top 10%)",
       x = "Count",
       y = "Percentile of Movies") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("counts_cdf_top10_movies.png", plot, h = 6, w = 6)
rm(plot)

# Average Rating Density Plot----------------------------------------------------------------------------
density_values <- density(movies$avg_rating)
store_plot("avg_rating_density_movies.png", {
  plot(density_values, main = "Density Plot of Average Movie Ratings", xlab = "Average Rating", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")  
})
rm(density_values)

# Cleanup----------------------------------------------------------------------------
rm(movie_percentiles)