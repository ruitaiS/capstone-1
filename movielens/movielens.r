###############
# Initial Setup
###############

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")

library(tidyverse)
library(caret)
options(timeout = 120)

# Set working directory to the directory containing this script
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# Check for movies and ratings files
ratings_file = "../datasets/ml-10M100K/ratings.dat"
movies_file = "../datasets/ml-10M100K/movies.dat"
if(!(file.exists(ratings_file) & file.exists(movies_file))){
  # Download MovieLens 10M dataset:
  # https://grouplens.org/datasets/movielens/10m/
  # http://files.grouplens.org/datasets/movielens/ml-10m.zip
  download.file("https://files.grouplens.org/datasets/movielens/ml-10m.zip", "ml-10M100K.zip")
  unzip("ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/ratings.dat")
  unzip("ml-10M100K.zip", exdir = "../datasets/", files = "ml-10M100K/movies.dat")
  file.remove("ml-10M100K.zip")
}

###################################################
# Create main and final_holdout_test sets 
# Note: this process could take a couple of minutes
###################################################

ratings <- as.data.frame(str_split(read_lines(ratings_file), fixed("::"), simplify = TRUE),
                         stringsAsFactors = FALSE)
colnames(ratings) <- c("userId", "movieId", "rating", "timestamp")
ratings <- ratings %>%
  mutate(userId = as.integer(userId),
         movieId = as.integer(movieId),
         rating = as.numeric(rating),
         timestamp = as.integer(timestamp))

movies <- as.data.frame(str_split(read_lines(movies_file), fixed("::"), simplify = TRUE),
                        stringsAsFactors = FALSE)
colnames(movies) <- c("movieId", "title", "genres")
movies <- movies %>%
  mutate(movieId = as.integer(movieId))

movielens <- left_join(ratings, movies, by = "movieId")

# Final hold-out test set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.6 or later
# set.seed(1) # if using R 3.5 or earlier
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
df <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in final hold-out test set are also in main set
# TODO: Why is this something we want? Shouldn't we make sure they're not in here?
final_holdout_test <- temp %>% 
  semi_join(df, by = "movieId") %>%
  semi_join(df, by = "userId")

# Add rows removed from final hold-out test set back into main set
removed <- anti_join(temp, final_holdout_test)
df <- rbind(df, removed)

rm(ratings, movies, test_index, temp, movielens, removed)

#########################################################

#Scrap / Test Code:

#names(df)
#head(df, 10)
#length(unique(df$movieId))



