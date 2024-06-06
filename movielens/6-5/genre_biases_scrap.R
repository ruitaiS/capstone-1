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