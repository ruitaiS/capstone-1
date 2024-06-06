ggplot(movies, aes(x = year, y = avg_rating)) +
  geom_point() +
  labs(title = "Average Ratings Over Years",
       x = "Year",
       y = "Average Rating") +
  theme_minimal() 

ggplot(train_df, aes(x = timestamp, y = rating, color = as.factor(movieId))) +
  geom_point() +            # Adds points
  labs(title = "Ratings Over Time by Movie",
       x = "Timestamp",
       y = "Rating",
       color = "Movie ID") + # Legend title
  theme_minimal()

#--------------------------------------------------------------------------------------

movieIds <- unique(train_df$movieId)

# Divide movieIds into groups of 5
movieId_groups <- split(movieIds, ceiling(seq_along(movieIds)/5))
movieId_groups <- movieId_groups[1:5]

# Function to create scatterplot for each group of movieIds
create_scatterplots <- function(group) {
  ggplot(data = subset(train_df, movieId %in% group), aes(x = timestamp, y = rating)) +
    geom_point() +
    labs(title = paste("MovieIds:", paste(group, collapse = ", ")),
         x = "Timestamp", y = "Rating") +
    theme_minimal()
}

# Create scatterplots for each group of movieIds
scatterplots_list <- lapply(movieId_groups, create_scatterplots)

for (i in 1:5) {
  print(scatterplots_list[[i]])
}