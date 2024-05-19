unique_titles <- train_df %>%
  filter(genres == '(no genres listed)') %>%
  distinct(title) %>%
  pull(title)
unique_titles


rm(unique_titles)