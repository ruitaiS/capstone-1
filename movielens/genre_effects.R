library("ggplot2")

# Genre Co-Occurrence Exploration:

#(Scrap) remove single genre elements
#genre_list <- train_df[sapply(train_df$genre_list, length) > 1, 'genre_list']
#genre_counts <- sapply(genre_list, length)

# Check for missing or empty values
missing_values <- sum(sapply(train_df$genre_list, function(x) any(is.na(x))))
empty_values <- sum(sapply(train_df$genre_list, function(x) length(x) == 0))



# Bar Plot of Occurrence Counts for Each Genre------------------------------------------
genre_counts <- as.data.frame(table(unlist(train_df$genre_list)))
colnames(genre_counts) <- c("Genre", "Count")
genre_counts <- genre_counts[order(genre_counts$Count), ]

# Plotting
plot <- ggplot(genre_counts, aes(x = reorder(Genre, Count), y = Count)) + 
  geom_bar(stat = "identity") +
  geom_text(aes(label = signif(Count, digits = 3)), nudge_y = 1000) +  # Corrected label assignment
  labs(x = "Genre", y = "Count", title = "Genre Counts Barplot")

# Save as PDF
pdf(file = "Graphs/genre_counts_barplot.pdf", height = 8, width = 15)
print(plot)
dev.off()
#----------
#genre_counts <- as.data.frame(table(unlist(train_df$genre_list)))
#colnames(genre_counts) <- c("Genre", "Count")
#genre_counts <- genre_counts[order(genre_counts$Count), ]
#plot<-ggplot(genre_counts,
#             aes(Genre,Count)) + 
#  geom_bar(stat = "identity")+
#  geom_text(aes(label = signif(Count)), nudge_y = 1000)
#pdf(file ="Graphs/genre_counts_barplot.pdf",
#    height = 8,
#    width = 12)
#plot
#dev.off()

#----------

# Co-occurrence Heatmap----------------------------------
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

# Initialize co-occurrence matrix
co_occurrence_matrix <- matrix(0, nrow = length(unique_genres), ncol = length(unique_genres), dimnames = list(rev(unique_genres), unique_genres))
co_occurrence_half_matrix <- matrix(0, nrow = length(unique_genres), ncol = length(unique_genres), dimnames = list(rev(unique_genres), unique_genres))

# Populate co-occurrence matrix
for (sublist in co_occurrence_genre_list) {
  print(sublist)
  if (length(sublist) == 2){
    co_occurrence_matrix[sublist[1], sublist[2]] <- co_occurrence_matrix[sublist[1], sublist[2]] + 1
    co_occurrence_matrix[sublist[2], sublist[1]] <- co_occurrence_matrix[sublist[2], sublist[1]] + 1
    
    co_occurrence_half_matrix[sublist[1], sublist[2]] <- co_occurrence_half_matrix[sublist[1], sublist[2]] + 1
  }else{
    for (i in 1:(length(sublist) - 1)) {
      for (j in (i+1):length(sublist)) {
        print(sublist[i])
        print(sublist[j])
        co_occurrence_matrix[sublist[i], sublist[j]] <- co_occurrence_matrix[sublist[i], sublist[j]] + 1
        co_occurrence_matrix[sublist[j], sublist[i]] <- co_occurrence_matrix[sublist[j], sublist[i]] + 1
        
        co_occurrence_half_matrix[sublist[i], sublist[j]] <- co_occurrence_half_matrix[sublist[i], sublist[j]] + 1
      }
    } 
  }
}

# Plot heatmap
#heatmap(co_occurrence_matrix, Rowv = NA, Colv = NA,col = heat.colors(10), scale = "none", margins = c(5, 10))
#pdf(file = "Graphs/genre_co_occurrence_heatmap.pdf",
#    width = 12,
#    height = 12)
#heatmap(co_occurrence_matrix, Rowv = NA, Colv = NA, col = cm.colors(max(co_occurrence_matrix)), scale = "none", main = "Co-occurrence of Genres")
#dev.off()


#-------
pdf(file = "Graphs/genre_co_occurrence_heatmap.pdf",
    width = 12,
    height = 12)
heatmap(log10(co_occurrence_matrix + 1), 
        Rowv = NA, 
        Colv = NA, 
        col = rev(heat.colors(256)),  # Use a different color palette for better visibility
        scale = "none",  # Avoid scaling to prevent distortion
        #symm = TRUE,  # Explicitly specify that the matrix is symmetric
        main = "Co-occurrence of Genres")
dev.off()

#------
#Most Frequently Co-Occurring Genres
co_occurrence_df <- as.data.frame(as.table(co_occurrence_half_matrix))
colnames(co_occurrence_df) <- c("Genre1", "Genre2", "Count")
co_occurrence_df <- co_occurrence_df[order(-co_occurrence_df$Count), ]
co_occurrence_df <- co_occurrence_df[co_occurrence_df$Count != 0, ]
print(tail(co_occurrence_df, 10))
