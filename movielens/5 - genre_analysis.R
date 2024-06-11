# Individual Genres 
genres_individual <- as.data.frame(table(unlist(strsplit(train_df$genres, "\\|"))))
colnames(genres_individual) <- c("genre", "count")

# Unnecessarily complex way to change "(no genres listed)" to "None"
# so the bar plot labels don't overlap
plot_df <- genres_individual
plot_df$genre <- as.character(plot_df$genre) # Convert to character because can't directly edit factors
plot_df$genre[genres_individual$genre == "(no genres listed)"] <- "None"
plot_df$genre <- as.factor(plot_df$genre) # Convert back to factor because you can't plot characters

# Genre Counts Barplot
plot <- ggplot(plot_df, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = count), nudge_y = 80000) +
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")+
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(8, "mm"))
  )
print(plot)
#store_plot("genre_counts_barplot.png", plot, w=13)
rm(plot, plot_df)

# Co-Occurrence Heat Map -----------------------------------------------------------
co_occurrence_genre_list <- train_df$genres %>% lapply(function(genres) {
  genre_list <- unlist(strsplit(as.character(genres), "\\|"))
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
co_occurrence_matrix <- matrix(0,
                               nrow = length(genres_individual$genre),
                               ncol = length(genres_individual$genre),
                               dimnames = list(rev(genres_individual[order(-genres_individual$count), ]$genre),
                                               genres_individual[order(-genres_individual$count), ]$genre))

# Populate co-occurrence matrix
for (genre_list in co_occurrence_genre_list) {
  if (length(genre_list) == 2){
    co_occurrence_matrix[genre_list[1], genre_list[2]] <- co_occurrence_matrix[genre_list[1], genre_list[2]] + 1
    co_occurrence_matrix[genre_list[2], genre_list[1]] <- co_occurrence_matrix[genre_list[2], genre_list[1]] + 1
  }else{
    for (i in 1:(length(genre_list) - 1)) {
      for (j in (i+1):length(genre_list)) {
        co_occurrence_matrix[genre_list[i], genre_list[j]] <- co_occurrence_matrix[genre_list[i], genre_list[j]] + 1
        co_occurrence_matrix[genre_list[j], genre_list[i]] <- co_occurrence_matrix[genre_list[j], genre_list[i]] + 1
      }
    } 
  }
}
rm(genre_list, i, j)
 
# Optionally Normalize the rows and pass it into the heatmap function
#co_occurrence_matrix<- t(apply(co_occurrence_matrix, 1, function(x) x / sum(x)))

# Plot
reversed <- co_occurrence_matrix[, ncol(co_occurrence_matrix):1]
plot_df <- melt(sqrt(reversed + 1))
plot <- ggplot(plot_df, aes(x=Var1, y=Var2, fill=value)) +
  geom_tile() +
  scale_fill_gradientn(colors = rev(heat.colors(256))) +
  labs(title = "Genre Co-occurrence", x = NULL, y = NULL) +
  guides(fill = FALSE) +
  theme_minimal() +
  theme(
    text = element_text(size = 8),
    plot.title = element_text(size = 20),
    axis.title = element_text(size = 15),
    axis.text = element_text(size = 10),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(plot)
#store_plot("genre_co_occurrence_heatmap.png", plot, h = 6, w = 6)
#store_plot("normalized_genre_co_occurrence_heatmap.png", plot, h = 6, w = 6)

# Cleanup
rm(genres_individual, plot_df, co_occurrence_genre_list, co_occurrence_matrix, row_normalized_matrix, reversed, plot)