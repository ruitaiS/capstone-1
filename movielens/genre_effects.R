library("ggplot2")

# Genre Co-Occurrence Exploration:

#Scrap to remove single genre elements
#genre_list <- train_df[sapply(train_df$genre_list, length) > 1, 'genre_list']
#genre_counts <- sapply(genre_list, length)

# Check for missing or empty values
missing_values <- sum(sapply(train_df$genre_list, function(x) any(is.na(x))))
empty_values <- sum(sapply(train_df$genre_list, function(x) length(x) == 0))

# For rows with only one genre, duplicate that element with itself
genre_list <- train_df$genre_list %>% lapply(function(sublist) {
  if (length(sublist) == 0) {
    return(NULL) # Remove empty sublists
  } else if (length(sublist) == 1) {
    return(rep(sublist, 2)) # Duplicate single-element sublists
  } else {
    return(sublist) # Preserve sublists with two or more elements
  }
})


unique_genres <- unique(unlist(genre_list))
genre_counts <- as.data.frame(table(unlist(train_df$genre_list)))
colnames(genre_counts) <- c("Genre", "Occurrences")

# Bar Plot of Occurrence Counts for Each Genre
plot<-ggplot(genre_counts,
             aes(Genre,Occurrences)) + 
  geom_bar(stat = "identity")+
  geom_text(aes(label = signif(Occurrences)), nudge_y = 1000)
plot

# Visualize co-occurrence using a heatmap
heatmap(co_occurrence_matrix, Rowv = NA, Colv = NA, col = heat.colors(10), scale = "column", main = "Co-occurrence of Genres")
