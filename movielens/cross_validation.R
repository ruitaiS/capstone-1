# ONLY RUN ONCE with the original train / test split created during setup -----------------------
# DO NOT REMOVE sets dataframe until Cross Validation is Complete

# Remove Dataframes / Columns created by previous runs
rm(mu, genres, movies, users, rmse_df)
test_df <- select(test_df, userId, movieId, rating, timestamp, title, genres, date)
train_df <- select(train_df, userId, movieId, rating, timestamp, title, genres, date)

seed <- 1
splits <- 4
set.seed(seed)
n <- nrow(train_df)
shuffled_indices <- sample(n)
subset_size <- ceiling(n / splits)
indices_list <- split(shuffled_indices, ceiling(seq_along(shuffled_indices) / subset_size))
set1 <- train_df[indices_list[[1]], ]
set2 <- train_df[indices_list[[2]], ]
set3 <- train_df[indices_list[[3]], ]
set4 <- train_df[indices_list[[4]], ]
set5 <- test_df
sets <- list(set1, set2, set3, set4, set5)
rm(n, seed, splits, shuffled_indices, subset_size, indices_list, train_df, test_df)
rm(set1, set2, set3, set4, set5)
#-------------------------------------------------------------------------------------

# Run Every Cross Validation-------------------------------------------------------
rm(mu, genres, movies, users, rmse_df, train_df, test_df)

# Set Index to 1-4 for Cross Validation
# 5 is the original test set created during setup
fold_index = 5
train_df <- do.call(rbind, sets[-fold_index])

# Ensure all movies and users in test set are also in the training set
# Remove from test_df rows without matching ids in train_df
test_df <- sets[[fold_index]] %>% 
  semi_join(train_df, by = "movieId") %>%
  semi_join(train_df, by = "userId")
# Add to train_df any removed rows
train_df <- rbind(train_df, anti_join(sets[[fold_index]], test_df))

# Reconstruct mean and dataframes for the new train_df
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
users <- as.data.frame(sort(unique(train_df$userId))) %>%
  setNames(c("userId"))
genres <- as.data.frame(sort(unique(unlist(train_df$genres)))) %>%
  setNames(c("genres"))

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

# Make a new RMSE df
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)