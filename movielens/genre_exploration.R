# Individual Genres 
genres_individual <- as.data.frame(table(unlist(strsplit(train_df$genres, "\\|"))))
colnames(genres_individual) <- c("genre", "count")
genres_individual$genre <- as.character(genres_individual$genre)
genres_individual$genre[genres_individual$genre == "(no genres listed)"] <- "None"
genres_individual$genre <- as.factor(genres_individual$genre) 


plot <- ggplot(genres_individual, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = count, nudge_y = 50000)) +  # Corrected label assignment
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(8, "mm"))      # Axis text size
  )

store_plot("genre_counts_barplot.png", plot)
pdf(file = "graphs/pdf", height = 8, width = 15)

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