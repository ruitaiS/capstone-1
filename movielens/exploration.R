data("movielens")
keep <- c("Godfather, The", "Godfather: Part II, The", "Goodfellas", "Ghost", "Titanic", 
          "Scent of a Woman")
dat <- movielens  |> 
  group_by(userId) |>
  filter(n() >= 250) |> 
  ungroup() |>
  group_by(movieId) |>
  filter(n() >= 50 | title %in% keep) |> 
  ungroup() 

y <- select(dat, movieId, userId, rating) |>
  pivot_wider(names_from = movieId, values_from = rating) 
y <- as.matrix(y[,-1])

colnames(y) <- dat |> select(movieId, title) |> 
  distinct(movieId, .keep_all = TRUE) |>
  right_join(data.frame(movieId=as.integer(colnames(y))), by = "movieId") |>
  pull(title)