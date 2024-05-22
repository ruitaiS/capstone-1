predicted <- sapply(test_df$genre_list, function(genre_list){
  #TODO: More complicated per-genre weighting
  ratings <- sapply(genre_list, function(genre){
    genres[genres$genre == genre,]$avg_rating
  })
  return (mean(ratings))
})
rmse <- calculate_rmse(predicted, test_df$rating)
rmse # = 1.048989

rm(predicted, rmse)