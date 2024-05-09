library("ggplot2")

# Genre Co-Occurrence Exploration:

#(Scrap) remove single genre elements
#genre_list <- train_df[sapply(train_df$genre_list, length) > 1, 'genre_list']
#genre_counts <- sapply(genre_list, length)

# Check for missing or empty values
missing_values <- sum(sapply(train_df$genre_list, function(x) any(is.na(x))))
empty_values <- sum(sapply(train_df$genre_list, function(x) length(x) == 0))

# Bar Plot of Occurrence Counts for Each Genre
genre_counts <- as.data.frame(table(unlist(train_df$genre_list)))
colnames(genre_counts) <- c("Genre", "Occurrences")
plot<-ggplot(genre_counts,
             aes(Genre,Occurrences)) + 
  geom_bar(stat = "identity")+
  geom_text(aes(label = signif(Occurrences)), nudge_y = 1000)
plot

# Co-occurrence Heatmap----------------------------------
# Initialize co-occurrence matrix
co_occurrence_matrix <- matrix(0, nrow = length(unique_genres), ncol = length(unique_genres), dimnames = list(unique_genres, unique_genres))

# For rows with only one genre, duplicate that element with itself
unique_genres <- unique(unlist(train_df$genre_list))
co_occurrence_genre_list <- train_df$genre_list %>% lapply(function(sublist) {
  if (length(sublist) == 0) {
    return(NULL) # Remove empty sublists
  } else if (length(sublist) == 1) {
    return(rep(sublist, 2)) # Duplicate single-element sublists
  } else {
    return(sublist) # Preserve sublists with two or more elements
  }
})

# Populate co-occurrence matrix
for (sublist in co_occurrence_genre_list) {
  print(sublist)
  if (length(sublist) == 2){
    co_occurrence_matrix[sublist[1], sublist[2]] <- co_occurrence_matrix[sublist[1], sublist[2]] + 1
    co_occurrence_matrix[sublist[2], sublist[1]] <- co_occurrence_matrix[sublist[2], sublist[1]] + 1
  }else{
    for (i in 1:(length(sublist) - 1)) {
      for (j in (i+1):length(sublist)) {
        print(sublist[i])
        print(sublist[j])
        co_occurrence_matrix[sublist[i], sublist[j]] <- co_occurrence_matrix[sublist[i], sublist[j]] + 1
        co_occurrence_matrix[sublist[j], sublist[i]] <- co_occurrence_matrix[sublist[j], sublist[i]] + 1
      }
    } 
  }
}

# Plot heatmap
#heatmap(co_occurrence_matrix, Rowv = NA, Colv = NA,col = heat.colors(10), scale = "none", margins = c(5, 10))
heatmap(co_occurrence_matrix, Rowv = NA, Colv = NA, col = cm.colors(max(co_occurrence_matrix)), scale = "none", main = "Co-occurrence of Genres")