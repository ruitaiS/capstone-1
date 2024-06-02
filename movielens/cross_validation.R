clean <- function(){
  # Remove Dataframes / Columns created by previous runs
}

split_train <- function (seed = 1, splits = 4){
  set.seed(seed)
  n <- nrow(train_df)
  shuffled_indices <- sample(n)
  subset_size <- ceiling(n / splits)
  indices_list <- split(shuffled_indices, ceiling(seq_along(shuffled_indices) / subset_size))
  set1 <- train_df[indices_list[[1]], ]
  set2 <- train_df[indices_list[[2]], ]
  set3 <- train_df[indices_list[[3]], ]
  set4 <- train_df[indices_list[[4]], ]
  
  return (list(set1, set2, set3, set4))
}

reassign <- function(index = 1){
  # Pick a new test set from the output of split_train
  # Then merge the remaining sets into a new train set
  # Remember to ensure no users / movies appear in the test set which do not appear in the train set
}



recalculate <- function(){
  rm(mu, genres, users, movies)
  # Recalculate mean and dataframes for the new train_df
  mu <- mean(train_df$rating)
  
  genres <- as.data.frame(table(unlist(train_df$genres))) %>%
    setNames(c("genres", "count")) %>%
    merge(genres, ., by = "genres", all.x = TRUE)
  
  users <- as.data.frame(table(train_df$userId)) %>%
    setNames(c("userId", "count")) %>%
    merge(users, ., by = "userId", all.x = TRUE)
  
  movies<- as.data.frame(table(train_df$movieId)) %>%
    setNames(c("movieId", "count")) %>%
    merge(movies, ., by = "movieId", all.x = TRUE)
  
  genres <- aggregate(data = train_df, rating ~ genres, FUN = mean) %>%
    setNames(c("genres", "avg_rating")) %>%
    merge(genres, ., by = "genres", all.x = TRUE)
  
  users <- aggregate(rating ~ userId, data = train_df, FUN = mean) %>%
    setNames(c("userId", "avg_rating")) %>%
    merge(users, ., by = "userId", all.x = TRUE)
  
  movies <- aggregate(rating ~ movieId, data = train_df, FUN = mean) %>%
    setNames(c("movieId", "avg_rating")) %>%
    merge(movies, ., by = "movieId", all.x = TRUE)
}