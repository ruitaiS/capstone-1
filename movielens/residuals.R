# Run movielens_setup.R, then biasing_effects.R prior to this file

# Residuals calculation / Prep for SVD:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(train_df$genres, genres$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

# Re-index the movieIds and userIds so they match their position in the matrix
users$userIndex <- as.numeric(factor(users$userId))
movies$movieIndex <- as.numeric(factor(movies$movieId))
train_df$movieIndex <- as.numeric(factor(train_df$movieId))
train_df$userIndex <- as.numeric(factor(train_df$userId))
train_df$movieIndex <- as.numeric(factor(train_df$movieId))

# Test Only: Check that the indices are all consecutive, and all match
all(diff(sort(users$userIndex)) == 1)
all(diff(sort(movies$movieIndex)) == 1)
all(users$userIndex[match(train_df$userId, users$userId)] == train_df$userIndex)
all(movies$movieIndex[match(train_df$movieId, movies$movieId)] == train_df$movieIndex)




# Plotting the Residuals Density Plot
density_values <- density(train_df$r)
plot(density_values, main = "Density Plot of Remaining Variation", xlab = "Remainder", ylab = "Density")
polygon(density_values, col = "lightblue", border = "black")

# Comparing Residuals of Two Movies
compare_r <- function(movieId1, movieId2){
  subset <- merge(train_df[train_df$movieId == movieId1, c('movieId', 'userId', 'title', 'r')],
                         train_df[train_df$movieId == movieId2, c('movieId', 'userId', 'title', 'r')],
                         by = "userId")
  title1 <- unique(subset$title.x)[1]
  title2 <- unique(subset$title.y)[1]
  
  ggplot(subset, aes(x = r.x, y = r.y)) +
    geom_point() +
    xlab(paste(title1, " Residuals")) +
    ylab(paste(title2, " Residuals")) +
    ggtitle(paste("Comparison of Residuals for", title1, "and", title2))
}

#compare_r(1, 300)

# SVD on Residuals----------------

# Exploration --------

set.seed(1987)
n <- 100
k <- 8
Sigma <- 64  * matrix(c(1, .75, .5, .75, 1, .5, .5, .5, 1), 3, 3) 
m <- MASS::mvrnorm(n, rep(0, 3), Sigma)
m <- m[order(rowMeans(m), decreasing = TRUE),]
y <- m %x% matrix(rep(1, k), nrow = 1) + matrix(rnorm(matrix(n*k*3)), n, k*3)
colnames(y) <- c(paste(rep("Math",k), 1:k, sep="_"),
                 paste(rep("Science",k), 1:k, sep="_"),
                 paste(rep("Arts",k), 1:k, sep="_"))

my_image <- function(x, zlim = range(x), ...){
  colors = rev(RColorBrewer::brewer.pal(9, "RdBu"))
  cols <- 1:ncol(x)
  rows <- 1:nrow(x)
  image(cols, rows, t(x[rev(rows),,drop=FALSE]), xaxt = "n", yaxt = "n",
        xlab="", ylab="",  col = colors, zlim = zlim, ...)
  abline(h=rows + 0.5, v = cols + 0.5)
  axis(side = 1, cols, colnames(x), las = 2)
}

my_image(y)

# TODO

my_image(cor(y), zlim = c(-1,1))
range(cor(y))
axis(side = 2, 1:ncol(y), rev(colnames(y)), las = 2)

#---------

fill_missing_A <- function(i, u){
  # TODO: Default Values for residuals on missing user/movie combinations
  # a) Fill in the missing ratings using the user / movie ensemble,
  # and subtract (mu + movie_bias + user_bias + genre_bias)
  
  # b) Use mu - (movie_bias + user_bias + genre_bias).
  # Mathematically I'm not sure how to justify this choice, but intuitively it seems promising
  # It might no be correct though. The residuals represent the deviation from the mean, minus biasing factors
  # This equation only gives the mean minus biasing factors.
  
  # c) Fill the missing ratings with mu, and subtract (mu + movie_bias + user_bias + genre_bias),
  # yielding r = -movie_bias - user_bias - genre_bias.
  
  # d) Fill in the missing ratings with some other value
  # and subtract (mu + movie_bias + user_bias + genre_bias)
  
  # e) b, c, d are all specific instances of the more general
  # r = alpha - (movie_bias + user_bias + genre_bias)
  # You can just tune for alpha
  
  return 0
}



# Populate the residuals matrix
residuals <- as.matrix(train_df[, c("userId", "movieId", "r")])

# Exploration:

#A <- matrix(c(13, -4, 2, -4, 11, -2, 2, -2, 8), 3, 3, byrow=TRUE)
#ev <- eigen(A)
#eigenvalues <- ev$values
#eigenvectors <- ev$vectors


# Exploration:

#random_movieIds <- sample(unique(train_df$movieId), 100, replace = FALSE)

# Randomly select 100 unique userIds
#random_userIds <- sample(unique(train_df$userId), 100, replace = FALSE)

# Filter train_df based on randomly selected movieIds and userIds
#filtered_df <- train_df[train_df$movieId %in% random_movieIds & train_df$userId %in% random_userIds, ]

# Convert filtered dataframe to matrix
#residuals <- as.matrix(filtered_df[, c("userId", "movieId", "r")])


