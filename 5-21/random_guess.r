set.seed(1)
predicted <- sample(seq(0, 5, 0.5), size=nrow(test_df), replace=TRUE)
rmse <- calculate_rmse(predicted, test_df$rating)
#rmse # = 2.151092

rm(predicted, rmse)