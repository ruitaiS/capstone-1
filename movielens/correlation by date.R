movie_correlation <- aggregate(edx[, c("rating", "timestamp")], by = list(edx$movieId), FUN = cor)

# Rename the columns
colnames(movie_correlation) <- c("movieId", "correlation")

# Now, merge with the movie names
movie_correlation <- merge(movie_correlation, unique(edx[, c("movieId", "movieName")]), by = "movieId")

# Plot the scatterplot
plot(movie_correlation$movieName, movie_correlation$correlation, 
     xlab = "Movie Name", ylab = "Correlation Coefficient", 
     main = "Correlation between Rating and Timestamp for Each Movie",
     pch = 16)

##########################################
# Forrest Gump movieId
# 356

movie_data <- df[df$movieId == your_movie_id, ]

# Now, perform linear regression
linear_model <- lm(rating ~ timestamp, data = movie_data)

# Get the correlation coefficient
correlation <- cor(movie_data$rating, movie_data$timestamp)

# Print correlation coefficient
print(paste("Correlation coefficient:", correlation))

# Print summary of linear model
summary(linear_model)