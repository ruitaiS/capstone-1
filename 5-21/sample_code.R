library(tidyverse)
library(dslabs)
data("movielens")

set.seed(2006)
indexes <- split(1:nrow(movielens), movielens$userId)
test_ind <- sapply(indexes, function(ind) sample(ind, ceiling(length(ind)*.2))) |>
  unlist(use.names = TRUE) |> sort()
test_df <- movielens[test_ind,]
train_df <- movielens[-test_ind,]

test_df <- test_df |> 
  semi_join(train_df, by = "movieId")
train_df <- train_df |> 
  semi_join(test_df, by = "movieId")

#y <- select(train_df, movieId, userId, rating) |>
#  pivot_wider(names_from = movieId, values_from = rating) 
#rnames <- y$userId
#y <- as.matrix(y[,-1])
#rownames(y) <- rnames

#movie_map <- train_df |> select(movieId, title) |> distinct(movieId, .keep_all = TRUE)

RMSE <- function(true_ratings, predicted_ratings){
  sqrt(mean((true_ratings - predicted_ratings)^2))
}

mu <- mean(train_df$rating, na.rm = TRUE)

rmse_results <- tibble(method = "Just the average", RMSE = RMSE(test_df$rating, mu))

#- My Code ----
#Create dfs for movies, users, and genres
#movies <- distinct(train_df, movieId, title, genres_one_hot, .keep_all=FALSE) %>% arrange(movieId)
movies <- distinct(train_df, movieId, title, .keep_all=FALSE) %>% arrange(movieId)
movies$year <- as.integer(str_extract(movies$title, "(?<=\\()\\d{4}(?=\\))"))
users <- as.data.frame(sort(unique(train_df$userId)))
#genres <- as.data.frame(sort(unique(unlist(train_df$genre_list))))
genre_groups <- as.data.frame(sort(unique(unlist(train_df$genres))))
colnames(users) <- "userId"
#colnames(genres) <- "genre"
colnames(genre_groups) <- "genre"

# Code to check for missing or empty values in genres
# Not needed b/c we already confirmed same movieIds in both
#missing_values <- sum(sapply(train_df$genre_list, function(x) any(is.na(x))))
#empty_values <- sum(sapply(train_df$genre_list, function(x) length(x) == 0))

# Clear out partitions, df and final holdout (until needed)
rm(movies_file, ratings_file, partition, partitions, df)
#rm(final_holdout_test)

#--------------------------
# Movie, User, and Genre Statistics
#TODO: If time, fix this code so that it doesn't re-add the columns if they already exist
#TODO: Textbook uses movies rated five times or more, and users that with 100 ratings or more (Implement if time)

# Average of All Ratings
#mu <- mean(train_df$rating)

# Grouped genres
genre_group_count <- as.data.frame(table(unlist(train_df$genres)))
colnames(genre_group_count) <- c("genre", "count")
genre_groups <- merge(genre_groups, genre_group_count, by = "genre", all.x = TRUE)
rm(genre_group_count)

genre_group_rating_avg <- aggregate(
  data = train_df,
  rating ~ genres,
  FUN = mean)
colnames(genre_group_rating_avg) <- c("genre", "avg_rating")
genre_groups <- merge(genre_groups, genre_group_rating_avg, by = "genre", all.x = TRUE)
rm(genre_group_rating_avg)

user_rating_count <- as.data.frame(table(train_df$userId))
colnames(user_rating_count) <- c("userId", "count")
users <- merge(users, user_rating_count, by = "userId", all.x = TRUE)
rm(user_rating_count)

user_rating_avg <- aggregate(rating ~ userId, data = train_df, FUN = mean)
colnames(user_rating_avg) <- c("userId", "avg_rating")
users <- merge(users, user_rating_avg, by = "userId", all.x = TRUE)
rm(user_rating_avg)

movie_rating_counts <- as.data.frame(table(train_df$movieId))
colnames(movie_rating_counts) <- c("movieId", "count")
movies <- merge(movies, movie_rating_counts, by = "movieId", all.x = TRUE)
rm(movie_rating_counts)

movie_rating_avg <- aggregate(rating ~ movieId, data = train_df, FUN = mean)
colnames(movie_rating_avg) <- c("movieId", "avg_rating")
movies <- merge(movies, movie_rating_avg, by = "movieId", all.x = TRUE)
rm(movie_rating_avg)

#----

movie_bias <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
colnames(movie_bias) <- c("movieId", "b_i")
train_df <- merge(train_df, movie_bias, by = "movieId", all.x = TRUE)
movies <- merge(movies, movie_bias, by = "movieId", all.x = TRUE)
# Filter:
#movies <- movies %>%
#  mutate(b_i = ifelse(count < 100, 0, b_i))
rm(movie_bias)

# Their Plot:
qplot(movies$b_i, bins = 10, color = I("black"))


movies$predicted <- mu + movies$b_i
test_df <- left_join(test_df, movies[,c("movieId", "predicted")], by="movieId")
rmse_results <- rbind(rmse_results, data.frame(
  method = "b_i",
  RMSE = RMSE(test_df$rating, test_df$predicted)
))

#---
user_bias <- aggregate((rating-(b_i + mu)) ~ userId, data = train_df, FUN = mean)
colnames(user_bias) <- c("userId", "b_u")
train_df <- merge(train_df, user_bias, by = "userId", all.x = TRUE)
users <- merge(users, user_bias, by = "userId", all.x = TRUE)

b_u <- users$b_u[match(test_df$userId, users$userId)]
b_i <- movies$b_i[match(test_df$movieId, movies$movieId)]
test_df$predicted <- mu + b_i + b_u
rmse_results <- rbind(rmse_results, data.frame(
  method = "b_i + b_u",
  RMSE = RMSE(test_df$rating, test_df$predicted)
))

#---
movies <- merge(movies, aggregate((rating-mu) ~ movieId, data = train_df, FUN = sum) %>%
                  setNames(c("movieId", "sum")), by="movieId")
l1_values <- seq(0, 10, 0.1) #Their values
l1_plot <- data.frame(Lambda = character(),
                      RMSE = numeric(),
                      stringsAsFactors = FALSE)
for (l1 in l1_values){
  movies$b_i_reg <- movies$sum / (movies$count + l1)
  # Filter:
  #movie_bias <- movie_bias %>%
  #  mutate(b_i = ifelse(count < 5, 0, b_i))
  b_i <- movies$b_i_reg[match(test_df$movieId, movies$movieId)]
  predicted <- mu + b_i
  l1_plot <- rbind(l1_plot, data.frame(
    Lambda = l1,
    RMSE = calculate_rmse(test_df$rating,predicted)))
}


qplot(l1_plot$Lambda, l1_plot$RMSE, geom = "line")+
  xlab("Lambda") +
  ylab("RMSE") +
  ggtitle("Lambda L1 vs. RMSE")
