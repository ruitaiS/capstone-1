# Individual Genres 
test_df <- train_df
test_df$genre_list <- strsplit(test_df$genres, "\\|")
genres_individual <- as.data.frame(table(unlist(train_df$genre_list)))
#colnames(genre_count) <- c("genre", "count")
#genres <- merge(genres, genre_count, by = "genre", all.x = TRUE)
#rm(genre_count)

#genre_rating_avg <- aggregate(
#  data = train_df %>%
#    unnest(genre_list),
#  rating ~ genre_list,
#  FUN = mean)
#colnames(genre_rating_avg) <- c("genre", "avg_rating")
#genres <- merge(genres, genre_rating_avg, by = "genre", all.x = TRUE)
#rm(genre_rating_avg)

#TODO: Above ----------------------

density_values <- density(genres$b_g_0)
plot(density_values, main = "Density Plot of Unregularized Genre Effects", xlab = "b_g_0", ylab = "Density")
polygon(density_values, col = "lightblue", border = "black")

# TODO: Text on this graph is too small
# Create a density plot for each unique value in 'genres'
explore_df <- train_df
explore_df$genres <- as.factor(explore_df$genres)
store_plot("genre_unreg_residuals_density.png",
           ggplot(explore_df, aes(x = b_g_0, fill = genres)) +
             geom_density(alpha = 0.5) +  # Add density plots with semi-transparent fills
             labs(title = "Density Plot of Ratings by Genre", x = "Rating", y = "Density") +
             theme_minimal() +
             guides(fill = FALSE),
           h = 1500, w = 1500
           )

#------
explore_df <- train_df
explore_df$genres <- as.factor(explore_df$genres)

# TODO: Text on this graph is too small
# Create a density plot for each unique value in 'genres'
store_plot("genre_unreg_residuals_density.png",
           ggplot(explore_df, aes(x = rating, fill = genres)) +
             geom_density(alpha = 0.5) +  # Add density plots with semi-transparent fills
             labs(title = "Density Plot of Ratings by Genre", x = "Rating", y = "Density") +
             theme_minimal() +
             guides(fill = FALSE),
           h = 1500, w = 1500
)