# Individual Genres 
genres_individual <- as.data.frame(table(unlist(strsplit(train_df$genres, "\\|"))))
colnames(genres_individual) <- c("genre", "count")


#For Below Barplot only (Re-run individual genres section afterwards to reset)
genres_individual$genre <- as.character(genres_individual$genre)
genres_individual$genre[genres_individual$genre == "(no genres listed)"] <- "None"
genres_individual$genre <- as.factor(genres_individual$genre) 

# Genre Counts Barplot
plot <- ggplot(genres_individual, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = count), nudge_y = 50000) +  # Corrected label assignment
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),          # General text size
    plot.title = element_text(size = unit(20, "mm")),    # Title text size
    axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
    axis.text = element_text(size = unit(8, "mm"))      # Axis text size
  )

store_plot("genre_counts_barplot.png", plot, w=13)

# Co-Occurrence Heat Map
train_df <- train_df %>%
  mutate(genre_list = strsplit(as.character(genres), "\\|"))

co_occurrence_genre_list <- train_df$genre_list %>% lapply(function(genre_list) {
  if (length(genre_list) == 0) {
    # Remove empty genre_lists (Probably unnecessary)
    return(NULL)
  } else if (length(genre_list) == 1) {
    # Duplicate for single genre movies (eg. [Action] becomes [Action, Action])
    return(rep(genre_list, 2)) 
  } else {
    # Preserve genre_list with two or more elements
    return(genre_list)
  }
})

# Initialize co-occurrence matrix with the genre names as indices
co_occurrence_matrix <- matrix(0, nrow = length(genres_individual$genre), ncol = length(genres_individual$genre), dimnames = list(rev(genres_individual[order(-genres_individual$count), ]$genre), genres_individual[order(-genres_individual$count), ]$genre))
#co_occurrence_half_matrix <- matrix(0, nrow = length(unique_genres), ncol = length(unique_genres), dimnames = list(rev(unique_genres), unique_genres))

# Populate co-occurrence matrix
for (genre_list in co_occurrence_genre_list) {
  if (length(genre_list) == 2){
    co_occurrence_matrix[genre_list[1], genre_list[2]] <- co_occurrence_matrix[genre_list[1], genre_list[2]] + 1
    co_occurrence_matrix[genre_list[2], genre_list[1]] <- co_occurrence_matrix[genre_list[2], genre_list[1]] + 1
    #co_occurrence_half_matrix[genre_list[1], genre_list[2]] <- co_occurrence_half_matrix[genre_list[1], genre_list[2]] + 1
  }else{
    for (i in 1:(length(genre_list) - 1)) {
      for (j in (i+1):length(genre_list)) {
        co_occurrence_matrix[genre_list[i], genre_list[j]] <- co_occurrence_matrix[genre_list[i], genre_list[j]] + 1
        co_occurrence_matrix[genre_list[j], genre_list[i]] <- co_occurrence_matrix[genre_list[j], genre_list[i]] + 1
        #co_occurrence_half_matrix[genre_list[i], genre_list[j]] <- co_occurrence_half_matrix[genre_list[i], genre_list[j]] + 1
      }
    } 
  }
}
rm(genre_list, i, j)

row_normalized_co_occurrence<- t(apply(co_occurrence_matrix, 1, function(x) x / sum(x)))

# Plot heatmap
store_plot("normalized_genre_co_occurrence_heatmap.png",
  heatmap(row_normalized_co_occurrence, #sqrt(co_occurrence_matrix + 1) Transform values for better visibility
          Rowv = NA, 
          Colv = NA, 
          col = rev(heat.colors(256)),  # Use a different color palette for better visibility
          scale = "none",  # Avoid scaling to prevent distortion
          main = "Row-Normalized Co-occurrence") +
    theme_minimal()+
    theme(
      text = element_text(size = unit(2, "mm")),          # General text size
      plot.title = element_text(size = unit(20, "mm")),    # Title text size
      axis.title = element_text(size = unit(15, "mm")),    # Axis titles text size
      axis.text = element_text(size = unit(10, "mm"))      # Axis text size
    ), h = 6, w = 6
)

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