if(!require(ggplot2)) install.packages("ggplot2", repos = "http://cran.us.r-project.org")
if(!require(tidyr)) install.packages("tidyr", repos = "http://cran.us.r-project.org")
if(!require(dplyr)) install.packages("dplyr", repos = "http://cran.us.r-project.org")
if(!require(lubridate)) install.packages("lubridate", repos = "http://cran.us.r-project.org")
if(!require(purrr)) install.packages("purrr", repos = "http://cran.us.r-project.org")
if(!require(reshape2)) install.packages("reshape2", repos = "http://cran.us.r-project.org")

library(ggplot2)
library(tidyr)
library(dplyr)
library(lubridate)
library(purrr)
library(reshape2)

# Make sure the same movies and users are in both sets
consistency_check <- function(test, train){
  # Note it makes the test set smaller
  updated_test <- test %>% 
    semi_join(train, by = "movieId") %>%
    semi_join(train, by = "userId")
  updated_train <- rbind(train, anti_join(test, updated_test))
  return (list(updated_test, updated_train))
}

# K-fold Cross Validation; k = 5
set.seed(2, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(2) # if using R 3.5 or earlier
folds <- createFolds(edx$rating, k = 5, list = TRUE, returnTrain = FALSE)
generate_splits <- function(index){
  return (consistency_check(edx[folds[[index]],], edx[-folds[[index]],]))
}

# RMSE Calculation Function:
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  errors <- predicted_ratings - actual_ratings
  squared_errors <- errors^2
  mean_of_squared_errors <- mean(squared_errors)
  rmse <- sqrt(mean_of_squared_errors)
  return(rmse)
}

# Function to write plots to file
store_plot<- function(filename, plot, h = 6, w = 12) {
  res <- 300
  height <- h * res
  width <- w * res
  png(file = paste("graphs/", filename, sep = ""), height = height, width = width, res = res)
  print(plot)
  dev.off()
}

# DF for Storing Results:
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      Fold = numeric(),
                      stringsAsFactors = FALSE)