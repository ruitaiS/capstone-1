'''
Rubric:
0 points: No RMSE reported AND/OR code used to generate the RMSE appears to violate the edX Honor Code.
5 points: RMSE >= 0.90000 AND/OR the reported RMSE is the result of overtraining or data leakage (the final hold-out test set ratings used for anything except reporting the final RMSE value) AND/OR the reported RMSE is the result of simply copying and running code provided in previous courses in the series.
10 points: 0.86550 <= RMSE <= 0.89999
15 points: 0.86500 <= RMSE <= 0.86549
20 points: 0.86490 <= RMSE <= 0.86499
25 points: RMSE < 0.86490

'''

#80/20 Split on main set
set.seed(1)
test_index <- createDataPartition(y = df$rating, times = 1, p = 0.2, list = FALSE)
train_df <- df[-test_index,]
test_df <- df[test_index,]

#RMSE Calculation Function:
calculate_rmse <- function(predicted, actual) {
  differences <- predicted - actual
  squared_differences <- differences^2
  mean_squared_difference <- mean(squared_differences)
  rmse <- sqrt(mean_squared_difference)
  return(rmse)
}

#Unique MovieIds
unique_movieIds <- sort(unique(df$movieId))

#Unique UserIds
unique_userIds <- sort(unique(df$userId))

#-----------------Specific Movels----------------------------

#Random Guess
#RMSE ~ 2.156
set.seed(3)
random_guess <- sample(seq(0, 5, 0.5), nrow(test_df), replace = TRUE)
guessing_rmse <- calculate_rmse(random_guess, test_df$rating)#sqrt(mean((random_guess-test_df$rating)^2))

#Predict by Movie Average------------------------------------------------
#RMSE ~ 0.944
learn_movie_avg <- function(movieId) {
  print(movieId)
  if (movieId %in% train_df$movieId){
    return(mean(train_df[train_df$movieId == movieId, "rating"])) 
  }else{
    #TODO: Split train/test sets so that they both have all movieIds
    # (without removing)
    # Check the template code, they have a way to do it idk
    return(mean(train_df$rating)) 
  }
}
mean_ratings <- sapply(unique_movieIds, learn_movie_avg)
movie_avg_lookups <- data.frame(movieId = unique_movieIds, avg_rating = mean_ratings)
predictions <- left_join(test_df, movie_avg_lookups, by = "movieId")
#predicted <- predictions$avg_rating
#actual <- test_df$rating
movie_avg_rmse <- calculate_rmse(predictions$avg_rating, test_df$rating)

#predictions[!complete.cases(predictions), ]

#User Average--------------------------------------------------------
#RMSE: 0.978
learn_user_avg <- function(userId) {
  print(userId)
  if (userId %in% train_df$userId){
    return(mean(train_df[train_df$userId == userId, "rating"])) 
  }else{
    #TODO: Split train/test sets so that they both have all movieIds
    # (without removing)
    # Check the template code, they have a way to do it idk
    return(mean(train_df$rating)) 
  }
}
mean_ratings <- sapply(unique_userIds, learn_user_avg)
user_avg_lookups <- data.frame(userId = unique_userIds, avg_rating = mean_ratings)
predictions <- left_join(test_df, user_avg_lookups, by = "userId")
user_avg_rmse <- calculate_rmse(predictions$avg_rating, test_df$rating)

#Movie / User Ensembling----------
ensemble_predict <- function(movieId, userId, k){
  user_rating <- user_avg_lookups[user_avg_lookups$userId == userId, "avg_rating"]
  movie_rating <- movie_avg_lookups[movie_avg_lookups$movieId == movieId, "avg_rating"]
  
  return ((k * user_rating) + (1-k)*movie_rating)
}

predictions <- apply(test_df, 1, function(row) {
  ensemble_predict(row["movieId"], row["userId"], 0.5)
})

ensemble_k05 <- calculate_rmse(predictions, test_df$rating)

#----
#TODOS:
#Reduce the size of Dataset.
#You're just doing exploratory analysis to figure out which approaches are worthwhile.
#There's no ned to run 10, 15 minute trainings on the entire dataset.
#A representative subsample is enough at this stage

#Look at the template code
#Find out how to make sure your training and test code are the same

# Check some of the edx sections below:




#Try a strict Average
#Try graphing the RMSE as a function of combination between the two

#---------
#Genre averaging

#Calculating effects of movie, user, and genre skewing

#SVD model

#caret package:
#https://learning.edx.org/course/course-v1:HarvardX+PH125.8x+3T2023/block-v1:HarvardX+PH125.8x+3T2023+type@sequential+block@0c52b960e83149df8d356387b278cd32/block-v1:HarvardX+PH125.8x+3T2023+type@vertical+block@4ac2f397cb024f5893744d4a8c3bc16e
#gamLoess
#glm
#knn
#cross validation
#classification tree

#Preprocessing Data:
#https://learning.edx.org/course/course-v1:HarvardX+PH125.8x+3T2023/block-v1:HarvardX+PH125.8x+3T2023+type@sequential+block@638b5f585b604ae187b32d1e089fccb8/block-v1:HarvardX+PH125.8x+3T2023+type@vertical+block@2228eb8c8fa24f15815ea814cbcd2bd1
#standardizing or transforming predictors and
#removing predictors that are not useful
#are highly correlated with others
#have very few non-unique values
#or have close to zero variation. 
