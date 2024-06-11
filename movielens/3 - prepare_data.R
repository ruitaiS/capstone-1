# Run This For K-Fold: (Pick New Index Each Run) -------------------

fold_index = 1

splits <- generate_splits(fold_index)
test_df <- splits[[1]]
train_df <- splits[[2]]
rm(splits, mu, users, movies, genres)
# ------------------------------------------------------------------
# Run This to use full Edx Set
# For sections 4, 5, 12
#train_df <- edx
# ------------------------------------------------------------------

# Always Run The Below Code:

# Average of All Ratings
mu <- mean(train_df$rating)

# Movies (year, count, avg_rating)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
movies<- as.data.frame(table(train_df$movieId)) %>%
  setNames(c("movieId", "count")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)
movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
  setNames(c("movieId", "avg_rating")) %>%
  merge(movies, ., by = "movieId", all.x = TRUE)

# Users (count, avg_rating)
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
users <- as.data.frame(table(train_df$userId)) %>%
  setNames(c("userId", "count")) %>%
  merge(users, ., by = "userId", all.x = TRUE)
users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
  setNames(c("userId", "avg_rating")) %>%
  merge(users, ., by = "userId", all.x = TRUE)

# Genres (count, avg_rating)
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))
genres <- as.data.frame(table(unlist(train_df$genres))) %>%
  setNames(c("genres", "count")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
  setNames(c("genres", "avg_rating")) %>%
  merge(genres, ., by = "genres", all.x = TRUE)
