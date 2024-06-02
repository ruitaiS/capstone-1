user_percentiles <- users %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  mutate(rating_percentile = percent_rank(avg_rating)*100) %>%
  mutate(decile = ntile(count, 10))%>%
  mutate(count_percentile_group = ifelse(decile == 10, "upper", "lower"))

users <- merge(users, user_percentiles[, c("userId", "count_percentile_group")], by = "userId", all.x = TRUE)

# Plot Count Percentiles
plot <- ggplot(users, aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Cumulative Density of Rating Counts",
       x = "Count",
       y = "Percentile of Users") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("cum_density.png", plot)

# Create a box-and-whisker plot for each decile
plot <- ggplot(user_percentiles, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "Rating Counts by Decile",
       x = "Decile",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("box-whisker-decile.png", plot)

# Plot Count Percentiles
plot <- ggplot(user_percentiles[user_percentiles$count_percentile<=90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Rating Counts CDF (Bottom 90%)",
       x = "Count",
       y = "Percentile of Users") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("counts_cdf_bottom90.png", plot)

plot <- ggplot(user_percentiles[user_percentiles$count_percentile>90,], aes(x = count)) +
  stat_ecdf(aes(y = after_stat(..y..) * 100), geom = "step", color = "blue") +
  labs(title = "Rating Counts CDF (Top 10%)",
       x = "Count",
       y = "Percentile of Users") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("counts_cdf_top10.png", plot)

bottom90 <- users %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  filter(count_percentile <= 90) %>%
  mutate(decile = ntile(count, 10))

top10 <- users %>%
  mutate(count_percentile = percent_rank(count) * 100) %>%
  filter(count_percentile > 90) %>%
  mutate(decile = ntile(count, 10))

# Create a box-and-whisker plot for each decile
plot <- ggplot(bottom90, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "Rating Counts by Decile (Bottom 90%)",
       x = "Decile",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("box-whisker-count-decile-bottom90.png", plot)

plot <- ggplot(top10, aes(x = as.factor(decile), y = count)) +
  geom_boxplot(fill = "blue", alpha = 0.7) +
  labs(title = "Rating Counts by Decile (Top 10%)",
       x = "Decile",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(10, "mm"))      # Axis text size
  )
store_plot("box-whisker-count-decile-top10.png", plot)

# Average Rating Density Plot
density_values <- density(users$avg_rating)
store_plot("avg_rating_density.png", {
  plot(density_values, main = "Density Plot of Average Rating", xlab = "Average Rating", ylab = "Density")
  polygon(density_values, col = "lightblue", border = "black")  
})
