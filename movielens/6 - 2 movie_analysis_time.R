plot <- ggplot(movies, aes(x = year, y = avg_rating)) +
  geom_point() +
  labs(title = "Average Movie Rating By Release Year",
       x = "Release Year",
       y = "Average Movie Rating") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
store_plot("movie_rating_by_release_year.png", plot)

#ggplot(train_df, aes(x = timestamp, y = rating, color = as.factor(movieId))) +
#  geom_point() +            # Adds points
#  labs(title = "Ratings Over Time by Movie",
#       x = "Timestamp",
#       y = "Rating",
#       color = "Movie ID") + # Legend title
#  theme_minimal()

#--------------------------------------------------------------------------------------
#movieIds <- unique(train_df$movieId)

# Divide movieIds into groups of 5
#movieId_groups <- split(movieIds, ceiling(seq_along(movieIds)/5))
#movieId_groups <- movieId_groups[1:5]

# Function to create scatterplot for each group of movieIds
#create_scatterplots <- function(group) {
#  ggplot(data = subset(train_df, movieId %in% group), aes(x = timestamp, y = rating)) +
#    geom_point() +
#    labs(title = paste("MovieIds:", paste(group, collapse = ", ")),
#         x = "Timestamp", y = "Rating") +
#    theme_minimal()
#}

# Create scatterplots for each group of movieIds
#scatterplots_list <- lapply(movieId_groups, create_scatterplots)

#for (i in 1:5) {
#  print(scatterplots_list[[i]])
#}

# Cleanup
rm(movieIds, movieId_groups, create_scatterplots, scatterplots_list)