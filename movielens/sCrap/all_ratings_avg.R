predicted <- rep(mean(train_df$rating),length(test_df$rating))
rmse <- calculate_rmse(predicted, test_df$rating)
rmse # = 1.062161

rm(predicted, rmse)