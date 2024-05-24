# Run movielens_setup.R, then biasing_effects.R prior to this file

# Residuals calculation / Prep for SVD:
movie_bias <- movies$b_i_reg[match(train_df$movieId, movies$movieId)]
user_bias <- users$b_u_reg[match(train_df$userId, users$userId)]
genre_bias <- genres$b_g_reg[match(train_df$genres, genres$genres)]
train_df$r <- train_df$rating - (mu + movie_bias + user_bias + genre_bias)
rm(movie_bias, user_bias, genre_bias)

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

# Create residuals matrix
residuals <- as.matrix(train_df[, c("userId", "movieId", "r")])


