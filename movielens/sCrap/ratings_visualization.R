library(tidyr)

matrix <- pivot_wider(data = df, 
                           id_cols = userId, 
                           names_from = movieId, 
                           values_from = rating, 
                           values_fill = NA)

# Fill NA Values
matrix[is.na(matrix)] <- 0

#----------

# Convert wide_matrix to matrix
rating_matrix <- as.matrix(matrix)

# Set up the plotting environment
par(mar = c(5, 4, 4, 8) + 0.1)

# Create the image plot
image(1:ncol(rating_matrix), 1:nrow(rating_matrix), rating_matrix, col = gray((0:255)/255), axes = FALSE, xlab = "Movie ID", ylab = "User ID")

# Add a color legend
legend("right", legend = c("Low Rating", "High Rating"), fill = gray((0:1)/255), bty = "n", y.intersp = 2)

# Add axis labels
axis(1, at = seq(1, ncol(rating_matrix), by = 10))
axis(2, at = seq(1, nrow(rating_matrix), by = 10))
