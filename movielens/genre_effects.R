#library("ggplot2")

# Bar Plot of Occurrence Counts for Each Genre------------------------------------------
# Store counts as new column in genre df
genre_counts <- as.data.frame(table(unlist(train_df$genre_list)))
colnames(genre_counts) <- c("genre", "count")
genres <- merge(genres, genre_counts, by = "genre", all.x = TRUE)
rm(genre_counts)

# Plot and save pdf
plot <- ggplot(genres, aes(x = reorder(genre, count), y = count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = signif(count, digits = 3)), nudge_y = 1000) +  # Corrected label assignment
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")

pdf(file = "graphs/genre_counts_barplot.pdf", height = 8, width = 15)
print(plot)
dev.off()
rm(plot)
#----------

# Co-occurrence Heatmap----------------------------------
# TODO: Comment the code here
# TODO: Normalize the heatmap. Here it skews towards movies with more views.
# I don't think it's as simple as dividing everything by the total count
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
co_occurrence_matrix <- matrix(0, nrow = length(genres$genre), ncol = length(genres$genre), dimnames = list(rev(genres[order(-genres$count), ]$genre), genres[order(-genres$count), ]$genre))
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

# Plot heatmap
pdf(file = "graphs/genre_co_occurrence_heatmap2.pdf",
    width = 12,
    height = 12)
heatmap(sqrt(co_occurrence_matrix + 1), # Transform values for better visibility
        Rowv = NA, 
        Colv = NA, 
        col = rev(heat.colors(256)),  # Use a different color palette for better visibility
        scale = "none",  # Avoid scaling to prevent distortion
        main = "Co-occurrence of Genres")
dev.off()
#------
#Most Frequently Co-Occurring Genres
#co_occurrence_df <- as.data.frame(as.table(co_occurrence_half_matrix))
#colnames(co_occurrence_df) <- c("Genre1", "Genre2", "Count")
#co_occurrence_df <- co_occurrence_df[order(-co_occurrence_df$Count), ]
#co_occurrence_df <- co_occurrence_df[co_occurrence_df$Count != 0, ]
#print(tail(co_occurrence_df, 10))
<<<<<<< HEAD

rm(co_occurrence_genre_list, co_occurrence_matrix)
=======
>>>>>>> 6ca09c173e554694ab0b327143cf3e07d3ac0a3a
