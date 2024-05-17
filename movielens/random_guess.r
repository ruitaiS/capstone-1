set.seed(1)
predicted <- sample(seq(0, 5, 0.5), size=length(test_df$rating), replace=TRUE)
rmse <- calculate_rmse(predicted, test_df$rating)
#rmse # = 2.151092

rm(predicted, rmse)