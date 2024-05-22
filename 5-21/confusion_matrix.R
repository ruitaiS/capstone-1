# tabulate each combination of prediction and actual value
table(predicted, actual)
test_df %>% 
  mutate(predicted = predicted) %>%
  group_by(genre) %>% #TODO: What other groups? Maybe rating_count cutoff groups?
  summarize(accuracy = mean(predicted == rating))

confusionMatrix(data = test_df$predicted, reference = test_df$rating)
