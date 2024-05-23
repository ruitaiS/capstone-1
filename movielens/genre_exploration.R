
# Individual Genres 
#genre_count <- as.data.frame(table(unlist(train_df$genre_list)))
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