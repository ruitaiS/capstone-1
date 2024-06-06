movie_models <- train_df %>%
  group_by(movieId) %>%
  nest() %>%
  mutate(model = map(data, ~ lm(rating ~ timestamp, data = .x))) %>%
  select(movieId, model)
movie_models <- setNames(movie_models$model, movie_models$movieId)

predict_ratings <- function(grouped_test_df, movie_models) {
  predictions <- list()
  # Batch predictions for each unique movieId
  for (movieId in names(grouped_test_df)) {
    model <- movie_models[[as.character(movieId)]]
    
    # Check if the model exists
    if (!is.null(model)) {
      # If the model exists, predict for all rows with this movieId
      predictions[[movieId]] <- predict(model, newdata = data.frame(timestamp = grouped_test_df[[movieId]]$timestamp))
    } else {
      # If the model doesn't exist, return an error message
      stop("Model for movieId ", movieId, " not found.")
    }
  }
  return(predictions)
}

# Sort Test Set by movieId so order matches the groups
test_df <- test_df[order(test_df$movieId), ]
# Group test_df by movieId
grouped_test_df <- split(test_df, test_df$movieId)
predictions <- predict_ratings(grouped_test_df, movie_models)
predictions <- unname(unlist(predictions, recursive = TRUE))
#----

for (movieId in names(grouped_test_df)) {
  model <- movie_models[[as.character(movieId)]]
  print(model)
}