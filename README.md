# Movie Recommendations:

TODO:
* Check results and graphs for simple algorithms using fold_index 1
* Mention the lm and matrix factorization approaches you took, which unfortunately did not yield positive results / took too far too long to run.
* Figure out a synoynm for "initially." Or control F it and see how many times you used it (feels like a lot)
* ctrl f 'edx' and 'main'. Make sure it's styled properly.

### Regarding the Files:

This project is split into several `.R` files, and are prefixed to indicate the proper running order. Each file corresponds to a section in this report, and includes the code necessary to generate the graphs shown.

`1 - edx_template.R` is the template code provided by the EdX team, and is only very slightly modified to change the directory structure. It should be run in it's entirety, and will produce the `edx` and `final_holdout_test` dataframes from the MovieLens data.

`2 - setup.R` downloads additional library dependencies, and provides some auxiliary functions used by the other files in the project. It also creates the `rmse_df` dataframe for storing the results of each algorithm, and `folds`, which contains five lists of indices, each corresponding to one fifth of the indices in the edx dataset. This also only needs to be run once in its entirety.

`3 - prepare_data.R` contains code to prepare the datasets for analysis and training, and consists of three subsections.

The first subsection assigns the entire edx set to `train_df`. This is mainly used for data analysis in sections 4-7, but is also used in section 12 to calculate the residual values on the entire dataset.

The second subsection assigns a specific fold as the test set, and merges the remaining folds into a training set. For section 8, 9, and 10, please use `fold_index = 1` to replicate the results in this report. Section 11 should be run five times with `fold_index` 1 through 5.

The third subsection should be always be run. It calculates the global rating average `mu` across the assigned training set, and creates the `users`, `movies`, and `genres` dataframes based on the training set.

The code is set up this way so that you can optionally run the analysis code on each fold instead of the full dataset without needing to change any of the variable names in those sections.

`4 - user_analysis.R` contains code to generate the graphs shown in the User Data Analysis section of the report. Please run each subsection one at a time, as the plot data is removed at the end of each subsection and you will not see the graphs if the entire file is run.

`5 - genre_analysis.R` generates the genre barplot and co-occurrence heatmap in the Genre Data Analyis section. Again, please run the barplot and the heatmap subsections individually, because otherwise you will not be able to see the graphs. There is optionally a section which will row-normalize the values in the heatmap, if you're interested in seeing that plot, which is mentioned but not included in the report.

`6 - movie_analysis.R` creates the Average Rating Vs. Release Year plot shown in the Movie Data Analysis section.

`6 - movie_analysis_extra.R` contains some extra plots about movie data that were ultimately left out of the report. They are in a similar format to the user data plots.

`7 - ratings_analysis.R` creates the ratings histogram plot shown in the Simple Algorithms section.

`8 - simple_algorithms.R` generates the outputs from the algorithms discussed in the Simple Algorithms section. This code can be run all at once. The results will be stored in `rmse_df` and can be viewed there.

`9 - ensemble_tuning.R` is the code for tuning the weights on the user / movie rating ensemble algorithm. The first subsection creates the graph shown in the Simple Algorithms section, and the second subsection stores into `rmse_df` the results obtained from using the tuned weights. Please run these individually.

This section also contains some commented out code for dropping users / movies from the average if they have less than some minimum number of ratings. This exploration was ultimately a dead end because it only seemed to increase the error, and is not included in the report. The code is there for those who are curious.

`10 - unregularized_biasing_effects.R` can be run all at once, and contains code for generating the output of the unregularized biasing effects model discussed in the User, Movie, and Genre Biases section. The results will be stored in `rmse_df`.

`11 - bias_regularization_tuning.R` is the code for tuning the regularization parameters mentioned in the User, Movie, and Genre Biases section. Prior to each run, please make sure to run `3 - prepare_data.R` using a new `fold_index` value from 1 to 5. I would recommend for just the first run to do the plotting sections individually to see the plots, then comment out the `print(plot)` portions and run the file in its entirely for subsequent runs.

`12 - residuals.R` calculates the residual values mentioned in the Residuals section of the report. Please run `3 - prepare_data.R` to assign the entire edx set as `train_df` prior to running this file. Everything here can be run all at once.

(TODO: LM, Matrix Factorization Models)

## Introduction:

This project implements a machine learning based prediction system for ratings in the MovieLens dataset. The full dataset consists of 10,000,054 ratings of 10,677 movies by 69,878 unique users. Each row has columns indicating the ID of the user who made the rating, the ID of the movie which was rated, the rating given, the timestamp at which it was given, the title of the movie, and the genres that the movie belongs to. Ratings can range from 0 to 5, at half-integer increments.

```
> nrow(movielens)
[1] 10000054
> length(unique(movielens$userId))
[1] 69878
> length(unique(movielens$movieId))
[1] 10677
> names(movielens)
[1] "userId"    "movieId"   "rating"    "timestamp" "title"     "genres"
```

Template code provided by the EdX team splits the data into a main dataset of 9,000,055 entries and a final holdout test set of 999,999 entries to be used exclusively for a final error calculation at the end of the project. The goal is to train a machine learning model on the records in the main dataset which can predict values in the `rating` column of the final holdout set, using the other column values as predictor variables. The root mean squared error function was used as a metric for the predictive power of the algorithm, with a target RMSE of less than 0.86490.

```
> nrow(edx)
[1] 9000055
> nrow(final_holdout_test)
[1] 999999
>
```
Initial data analysis was performed on the main dataset as a whole. For model development, the data was split into five equally sized subsets, indexed by `fold_index` one through five. Some simple algorithms were explored first to establish a performance benchmark, and for these models, only `fold_index = 1` was used as the test set; the other four sets were merged back together to form the training set. Cross-validation was not done for these models.

The main model used in this project is a modified version of the approach outlined by Robert M. Bell, Yehuda Koren, and Chris Volinsky in their 2009 paper "The BellKor Solution to the Netflix Grand Prize." An average $\mu$ of all movie ratings in the training set formed a baseline predictor, on top of which were added movie, user, and genre biases: $`{b}_{i}`$, $`{b}_{u}`$, and $`{b}_{g}`$ respectively. Each bias has an associated regularization parameter, $\lambda_1$, $\lambda_2$, $\lambda_3$, which was tuned to minimize the error on the test set. This process was performed on all five folds for `k=5` fold cross validation. 

(TODO: Find another way to refer to the model other than biasing effect model.)
The tuning parameters were finalized using the average of the optimal values calculated during each of the five validation runs. A single pass was then made through the entire main dataset to find the residual differences ${r'} = \hat{r} - r$ between the recorded ratings and the ratings predicted by the model. Two methods were attempted to account for these residual values - a matrix factorization model using stochastic gradient descent, and a simple time factor linear model - but neither showed improvement over the base model, and were not used for the final RMSE calculation on the holdout set.

The final RMSE on the holdout set was (TODO)

## Preprocessing:
The provided template code downloads the MovieLens dataset and splits the data into `edx` and `final_holdout_test` dataframes, with a proportion of `p = 0.1` for the latter. (TODO: Expound if time)

The `edx` set is split into five folds using `createFolds`, with the `rating` column assigned as the response vector to ensure that rating values are equally distributed among each fold. Each fold is an equal length list of unique, non-overlapping indices for rows from the `edx` set.

The `generate_splits` function accepts a `fold_index` parameter designating which of the five folds will be used as the test set; the remaining folds are merged together to form the training set. The corresponding rows are extracted from the `edx` set, and passed to the `consistency_check` function before being assigned as the `test_df` and `train_df` dataframes.

`consistency_check` ensures that every `movieId` and `userId` which appears in the test set also appears in the training set. The code to do this was borrowed from the provided template code, which performs a similar modification for the main dataset in relation to the final holdout set. While this is a seemingly minor detail, it makes the prediction task **significantly** easier, as it completely eliminates the need to make predictions on users or movies which do not appear in the training set, also known as the [cold start problem](https://en.wikipedia.org/wiki/Cold_start_(recommender_systems)).

The training set was further processed to produce the ```genres```, ```users```, and ```movies``` dataframes. The column names are provided below, and should be mostly self-explanatory.

```
> names(genres)
[1] "genres"     "count"      "avg_rating"
> names(movies)
[1] "movieId"    "title"      "year"       "count"      "avg_rating"
> names(users)
[1] "userId"     "count"      "avg_rating"
```

Note `genres` contains the full genre list string provided for a movie, not an individual genre. This was done mainly for the sake of simplification - the section on genre relationships will touch further on this decision.
```
> head(genres)
                                              genres count avg_rating
1                                 (no genres listed)     7   3.642857
2                                             Action 24482   2.936321
3                                   Action|Adventure 68688   3.659569
4         Action|Adventure|Animation|Children|Comedy  7467   3.962770
5 Action|Adventure|Animation|Children|Comedy|Fantasy   187   2.986631
6    Action|Adventure|Animation|Children|Comedy|IMAX    66   3.295455
```

## Data Analysis

### User Data Analysis:

Initial data exploration showed very quickly that some users had rated considerably more movies than others, so much so that the discrepancy is difficult to visualize properly on a graph. Here is an attempt to do so using a box-whisker decile plot:

<div style="display: inline-block;">
  <img src="/movielens/graphs/box-whisker-decile_users.png" alt="User Rating Counts by Decile" title="User Rating Counts by Decile" style="float: center; width: 100%;">
</div>

As the plot shows, the most prolific 10% or so of users have rated so many movies that it immediately blows out the scale of the Y axis, making it difficult to even read the values for the other 90%. Cumulative density functions done on these two groups show that the cutoff for the top 10% of users is about 300 ratings, beyond which the counts begin to skyrocket.

<div style="display: inline-block;">
  <img src="/movielens/graphs/counts_cdf_bottom90_users.png" alt="Cumulative Density of Rating Counts (Bottom 90%)" title="Cumulative Density of Rating Counts (Bottom 90%)" style="float: left; margin-right: 10px; width: 45%;">
  <img src="/movielens/graphs/counts_cdf_top10_users.png" alt="Cumulative Density of Rating Counts (Top 10%)" title="Cumulative Density of Rating Counts (Top 10%)" style="float: left; margin-right: 10px; width: 45%;">
</div>

### Genre Data Analysis:

In total there are 20 unique genres, and similar to what we saw with users, certain movie genres had a much higher number of ratings, and others very few. However the skew is not nearly as dramatic:

<img src="/movielens/graphs/genre_counts_barplot.png" align="center" alt="Genre Counts"
	title="Genre Counts"/>

I was curious to see which genres were most likely to appear together on the same movie, so I created the co-occurrence heatmap matrix shown below. Each cell represents the number of movies which have both the X-axis genre and Y-axis genre, with darker values indicating a higher number. Cells along the diagonal (where the X and Y genres are the same) are counts for movies with just that one genre associated to it.

<div style="display: inline-block; vertical-align: middle;">
<p>
<img src="/movielens/graphs/genre_co_occurrence_heatmap.png" align="left" style="width: 425px;" alt="Genre Heatmap"
	title="Genre Heatmap"/>

<br>
It is clear that there are certain genres which occur more frequently alongside other ones, but, perhaps unsurprisingly, the most common genres are also the ones with the highest co-occurrence counts. I tried normalizing the matrix by dividing each row element by the sum of the values in that row, but the result wasn't any more insightful. I decided to stop my exploration into the genre data here, and stick to using the full genre string associated with each movie, rather than over-complicate things by subdividing them into individual genres. There are 797 unique genre strings, as opposed to only 20 unique individual genres, so while some resolution might be lost, in a dataset of over 9 million ratings, I did not consider this loss of granularity to be worth the added complexity.
</p>
</div>
<br>
<br>

### Movie Data Analysis

There are 10677 unique movies in the dataset, with release dates from 1915 to 2008. Like users and genres, there are some movies which are substantially more popular than others.

```
> head(movies[order(-movies$count), ])
    movieId                            title year count avg_rating
294     296              Pulp Fiction (1994) 1994 31362   4.154789
353     356              Forrest Gump (1994) 1994 31079   4.012822
588     593 Silence of the Lambs, The (1991) 1991 30382   4.204101
477     480             Jurassic Park (1993) 1993 29360   3.663522
316     318 Shawshank Redemption, The (1994) 1994 28015   4.455131
109     110                Braveheart (1995) 1995 26212   4.081852
> head(movies[order(movies$count), ])
     movieId                          title year count avg_rating
3107    3191             Quarry, The (1998) 1998     1        3.5
3142    3226  Hellhounds on My Trail (1999) 1999     1        5.0
3150    3234 Train Ride to Hollywood (1978) 1978     1        3.0
3272    3356          Condo Painting (2000) 2000     1        3.0
3298    3383               Big Fella (1937) 1937     1        3.0
3473    3561         Stacy's Knights (1982) 1982     1        1.0
```

There is also good evidence of chronological effect on movie ratings as shown by the graph below. Older movies in general seem to have a higher average rating than newer movies, which show more spread. One possible explanation might be that older movies are more likely to only be viewed and rated by users who are fans of old movies, while newer movies are rated by a broader audience. It could also be the case that only the good movies from past decades are remembered and included in the MovieLens library, while the rest are lost to time.

<img src="/movielens/graphs/movie_rating_by_release_year.png" align="center" alt="Average Movie Ratings By Release Year"
	title="Average Movie Ratings By Release Year"/>

## Methods:

As specified in the project instructions, the root mean squared error function was used as a measure for each algorithms effectiveness.

Let ${r}{_u}{_i}$ denote the observed rating of user $u$ for movie $i$ in some dataset, and let $\hat{r}{_u}{_i}$ signify an algorithm's prediction for how that user would rate the movie. The root mean squared error can then be written as

```math
RMSE = \sqrt{\frac{{\sum}_{u,i\in {D}_{test}}({r}{_u}{_i} - \hat{r}{_u}{_i})^2}{|{D}_{test}|}}
```

where $`{D}_{test}`$ is our test set. It is, as the name would suggest, the square **root** of the **mean** of the **square** of the **error**. Error is commonly defined as the difference between the predicted vs. actual values - for this reason RMSE is also frequently called RMSD, or Root Mean Squared Difference. In code this relationship is much clearer to see:

```
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  errors <- predicted_ratings - actual_ratings
  squared_errors <- errors^2
  mean_of_squared_errors <- mean(squared_errors)
  rmse <- sqrt(mean_of_squared_errors)
  return(rmse)
}
```
Each algorithm produces a list of ratings of equal length to the `test_df$rating` column, and feeding these two lists into the `calculate_rmse` function returns a single RMSE value, which is then stored in `rmse_df` along with the algorithm's name and the `fold_index` that the model was run on.

### Some Simple Algorithms to Start
(TODO: Double Check RMSEs for these)

A couple of very basic methods for rating prediction come to mind, and these were the ones I tried first while building out the testing framework.

The most naive approach would be to randomly guess a rating - as one would expect, this gave a very poor RMSE of ~2.16. Next was to find the average of all the ratings in the training set, and to use that value as the prediction for every rating in the test set. If we look to the histogram plot of the ratings given in the training set, we see that whole number ratings are more common than ones rated at half integer increments (this I would attribute to user psychology more than anything else), but the set of whole number ratings and the set of half-step ratings both form bell-curve shaped distributions centered roughly around the global mean, shown as the dashed vertical red line.

<img src="/movielens/graphs/rating_histogram.png" align="center" alt="Ratings Histogam"
	title="Ratings Histogram"/>

Predicting the training set mean for each rating in the test set might not be a very sophisticated approach, but it minimizes the distance from observed ratings more so than any other static value. In any case, it is much better than making random guesses, and gives a much improved RMSE of ~1.06.

Per-genre average, per-user average, and per-movie average is slightly more nuanced, producing a mean for each genre, user, or movie, and making that our guess, rather than the global average. This takes into account that some genres / users / movies tend to rate higher or lower, and by taking the mean of specific subsets of ratings, rather than the mean of the entire training set, we capture slightly more detail, and are able to incrementally improve the RMSE.

Finally, I tried an ensemble of the user and movie averages. If we weight the two equally, the predicted value is defined as $`\hat{r}{_u}{_i} = \frac{(\bar{r}_{u} + \bar{r}_{i})}{2}`$, with the average rating for user $u$ and movie $i$ as $`\bar{r}_{u}`$ and $`\bar{r}_{i}`$ respectively. This yielded an RMSE of ~0.913, To see whether this could be improved by weighting the average, the prediction was redefined as $`\hat{r}{_u}{_i} = {w} * \bar{r}_{u} + (1 - {w}) * \bar{r}_{i}`$, with ${w}$ being the weight assigned to the user average, and $1-{w}$ the weight for the movie average. To find the optimal weighting ${w}$, I plotted the RMSE across the test set against values of ${w}$ ranging from 0.2 to 0.6:

<img src="/movielens/graphs/weighted_ensemble_tuning.png" align="center" alt="User / Movie Average Weighted Ensemble Optimization"
	title="User / Movie Average Weighted Ensemble Optimization"/>

The minima occurs at $`{w} = 0.4062`$, and yields a very slightly improved RMSE of ~0.912 on the test set.

The results of these simple algorithms are tallied below:

<div align = "center">
	
| Algorithm | RMSE |
| :-: | :-: |
| Random Guess | 2.1575303|
| Avg All | 1.0604283 |
| Genre Avg | 1.0183814
| User Avg | 0.9790523 |
| Movie Avg | 0.9441866 |
| User Movie Avg, Equal Weight Ensemble | 0.9137740 |
| User Movie Avg Weighted Ensemble, w =  0.4069 | 0.9120644 |

</div>

### User, Movie, and Genre Biases

A more sophisticated approach is presented in Koren et al.'s (TODO: format) 2009 paper. Rather than taking the average rating for each movie, we instead find the biasing effect $`{b}_{i}`$ for each movie, defined as the average difference of the observed ratings for all users on that movie from the global average $\mu$ of all movie ratings, such that $`{b}_{i} = \frac{\sum_{u\in R(i)}{r}{_u}{_i} - \mu}{|R(i)|}`$, with ${u\in R(i)}$ being all users $u$ who have rated movie $i$, and $|R(i)|$ as the size of that set of users. We likewise define the user bias to be the average of the observed ratings, minus the sum of the global mean and the movie bias: $`{b}_{u} = \frac{\sum_{i\in R(u)}{r}{_u}{_i} - (\mu+{b}_{i})}{|R(u)|}`$, and the genre bias to be the average of the observed minus the sum of the global mean and the user and movie biases: $`{b}_{g} = \frac{\sum_{u,i\in R(g)}{r}{_u}{_i} - (\mu+{b}_{i}+{b}_{u})}{|R(g)|}`$, where $`{u,i\in R(g)}`$ is some user $u$ rating a movie $i$ which has genre $g$, and $|R(g)|$ is the size of the set of all ratings for that genre.

(Please note again that "genre" in this case refers to the entire genre list string attached to a given movie. As mentioned previously, I did not feel it was worth the added complexity of finding the biasing effects of each the 20 individual genres, and instead treated the entire genre list string as one item.)

These equations were implemented in code using R's `aggregate` function. Again, the code might be easier to understand than the mathematical equations, so I've included a shortened version below (the `_0` suffix indicates that these are unregularized biases - more on that in the Bias Regularization section).:
```
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean)
genres <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean)
```

Once the biasing effects $`{b}_{i}`$, $`{b}_{u}`$, and $`{b}_{g}`$ are calculated for each movie, user, and list of genres, we simply add them on top of the global rating average $\mu$ to find the predicted rating:

```math
\hat{r}{_u}{_i} = \mu + {b}_{i} + {b}_{u} + {b}_{g}`
```
I layered the biasing effects onto the global average one at a time, and the results are shown below:

<div align = "center">
	
| Algorithm | RMSE |
| :-: | :-: |
| mu + b_i_0 | 0.9441866 |
| mu + b_i_0 + b_u_0 | 0.8665665 |
| mu + b_i_0 + b_u_0 + b_g_0 | 0.8662257 |

</div>

### Bias Regularization Tuning With K = 5 Fold Cross Validation

The variance of the mean value for a sample can be defined as $`Var(\bar{r}) = \frac{\sigma^2}{n}`$ for a sample of size $n$ taken from a population that has some variance $`\sigma^2`$. This equation shows that the variance of the sample mean is inversely proportional to the sample size. In our context, when movies, users, or genres have very few ratings in the training set, the calculated biasing effect (which is essentially a sample mean) will vary significantly based on the specific ratings randomly selected for inclusion.

To counteract this, I adopted Koren et al.'s approach by including a regularization parameter $\lambda$ into each bias calculation:

```math
	
{b}_{i_{reg}} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{\lambda_1 + |R(i)|} \quad \quad
{b}_{u_{reg}} = \sum_{u,i\in R(u)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}})}{\lambda_2 + |R(u)|} \quad \quad
{b}_{g_{reg}} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}})}{\lambda_3 + |R(g)|}

```

When the sample size $|R|$ is small, $\lambda$ significantly reduces the bias, while for larger sample sizes this effect diminishes, approaching 0 as $|R|$ increases. This reduces the influence of noisy biasing effects caused by small sample sizes, while preserving the bias effects we have greater confidence in.

Similar to the tuning process for the weighted average parameter, values for $\lambda$ were stepped in 0.001 increments and plotted against the resulting RMSE on the test set. The value which minimized the RMSE was picked at each stage before moving on to the next parameter.

<div style="display: inline-block;">
	<img src="/movielens/graphs/l1-tuning-square-fold-1.png" alt="L1 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: left; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l2-tuning-square-fold-1.png" alt="L2 Tuning Fold 1" title="L2 Tuning Fold 1" style="float: center; margin-left: 5px; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l3-tuning-square-fold-1.png" alt="L3 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: right; margin-left: 5px; width: 30%;">
</div>

(TODO: Rephrase. Maybe talk more about what K-fold cross validation is.)
As mentioned, the biasing effects are quite sensitive to the randomness of the training / test set split, and consequently so are their tuning parameters. To counteract this, the full dataset was split into 5 folds and the tuning process was run on each fold. The plots for the first fold are shown above (plots for the other folds are included in the repository, but omitted for brevity), and a summary of the tuned values across all five folds, along with the resulting RMSE, is presented below:

<div align = "center">

| Fold | L1 | L2 | L3 | RMSE |
| :-: | :-: | :-: | :-: | :-: |
| Fold 1 | 1.947 | 4.836 | 27.167 | 0.8656432 |
| Fold 2 | 2.347 | 4.974 | 15.209 | 0.8653785 |
| Fold 3 | 2.083 | 4.859 | 0 | 0.8653743 |
| Fold 4 | 2.272 | 4.959 | 12.262 | 0.8649200 |
| Fold 5 | 2.151 | 5.307 | 4.07 | 0.8647899 |

</div>

### Attempts to reduce residual values $r'$

(TODO: Write better)
The regularization parameters were averaged across all five folds, for final values of $\lambda_1 = 2.16$, $\lambda_2 = 4.987$, and $\lambda_3 = 11.7416$. Values for $\hat{r}{_u}{_i}$ were calculated for all ratings in the EdX dataset, and a residuals matrix of the remaining values was produced.

An $m\times n$ residuals matrix $`\mathcal{E} = \begin{pmatrix}
r'_{11} & r'_{12} & \cdots & r'_{1n} \\
r'_{21} & r'_{22} & \cdots & r'_{2n} \\
\vdots & \vdots & \ddots & \vdots \\
r'_{m1} & r'_{m2} & \cdots & r'_{mn} \\
\end{pmatrix}`$

where $`m = |\{u\in \mathcal{D}\}|`$, $`n = |\{i\in \mathcal{D}\}|`$, and each entry $`{r'}{_u}{_i} = {r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}}+{b}_{g_{reg}})`$

These residuals represent the discrepancy between the predicted and observed values which the biasing effects did not account for. Several methods were attempted on the residuals matrix to further reduce the RMSE - unfortunately none of them were successful in reducing the RMSE.

* Residuals Matrix
* SGD on Residuals


## Results

a results section that presents the modeling results and discusses the model performance

## Conclusion

a conclusion section that gives a brief summary of the report, its limitations and future work
* Chrono Biasing
* Per-Genre Analysis
* Better Matrix Factorization


## References
Movielens Dataset:
https://grouplens.org/datasets/movielens/10m/

(TODO: Other Papers)


### Code Bits

```


test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]
```

```
setup.R

library(ggplot2)
library(tidyr)
library(dplyr)
library(lubridate)
library(purrr)
library(reshape2)

# Make sure the same movies and users are in both sets
consistency_check <- function(test, train){...}

# Create folds
folds <- createFolds(edx$rating, k = 5, list = TRUE, returnTrain = FALSE)
generate_splits <- function(index){
  return (consistency_check(edx[folds[[index]],], edx[-folds[[index]],]))

# Auxiliary Functions
calculate_rmse <- function(predicted_ratings, actual_ratings) {...}
store_plot<- function(filename, plot, h = 6, w = 12) {...}

# Storing Results:
rmse_df <- data.frame(Algorithm = character(),
                      RMSE = numeric(),
                      Fold = numeric(),
                      stringsAsFactors = FALSE)
}
```


## Formulas and Notation:

$`{b}_{i_0} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{|R(i)|}`$

Final holdout set $\mathcal{F}$

Main dataset $\mathcal{D}$

(Check) Training Set $\kappa = \\{(u,i) | r{_u}{_i} \text{is known}\\}$

(Check) $k$ cross validation sets $\\{K_1, K_2, ... K_k\\}$

From these sets, we pick an index $v\in\\{1, 2, ... k\\}$ to form our validation and training sets, such that:

Validation Set $`\mathcal{D}_{val} = K_v`$

(Check nested curly braces)Training Set $`\mathcal{D}_{train} = \{ K_t\in \{K_1, K_2, ... K_k\} | t\neq v \}`$

(Genre set for movie i)

(Clarify that the following are derived from the training (eg. non-validation) folds)

Average Rating function $\bar{r}_{(...)}$, such that:

Average rating across all users and movies in the training set: $\bar{r}_{(\kappa)}$ or $\mu$

Average rating for a movie $i$ : $\bar{r}_{(i)}$

Average rating for a user $u$ : $\bar{r}_{(u)}$

Sets $R(u)$ and $R(i)$ denoting all movies rated by user $u$ and all users who have rated movie $i$, respectively

(Check) Set $R(g)$ denoting all pairs $(u,i)$ of users and movies which have rated a movie with genre set $g$

(Update code to use alpha instead of lambda for regularization)

Unregularized bias for movie $i$: $`{b}_{i_0} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{|R(i)|}`$

Regularization parameter for movie biases: $\alpha_1$

Regularized bias for movie $i$: $`{b}_{i_{reg}} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{\alpha_1 + |R(i)|}`$

Unregularized bias for user $u$: $`{b}_{u_0} = \sum_{i\in R(u)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_0})}{|R(u)|}`$

Regularization parameter for user biases: $\alpha_2$

Regularized bias for user $u$: $`{b}_{u_{reg}} = \sum_{i\in R(u)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}})}{\alpha_2 + |R(u)|}`$

(Check size of R(g)) Unregularized bias for genre set $g$: $`{b}_{g_0} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_0}+{b}_{u_0})}{|R(g)|}`$

Regularization parameter for genre biases: $\alpha_3$

Regularized bias for genre $g$: $`{b}_{g_reg} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}})}{\alpha_3 + |R(g)|}`$

(Make sure m and n line up in code)
An $m\times n$ residuals matrix $`\mathcal{E} = \begin{pmatrix}
r'_{11} & r'_{12} & \cdots & r'_{1n} \\
r'_{21} & r'_{22} & \cdots & r'_{2n} \\
\vdots & \vdots & \ddots & \vdots \\
r'_{m1} & r'_{m2} & \cdots & r'_{mn} \\
\end{pmatrix}`$

where $`m = |\{u\in \mathcal{D}\}|`$, $`n = |\{i\in \mathcal{D}\}|`$, and each entry $`{r'}{_u}{_i} = {r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}}+{b}_{g_{reg}})`$

We decompose $\mathcal{E}$ with Singular Value Decomposition:

$`\mathcal{E} = U\Sigma V^T`$, such that

$U$ is an $m\times m$ orthogonal matrix

$\Sigma$ is an $m\times n$ diagonal matrix with non-negative real numbers on the diagonal

$V$ is an $n\times n$ orthogonal matrix, of which $V^T$ is the transpose

From $\mathcal{E}$, we compute the $m\times m$ matrix $\mathcal{E}\mathcal{E}^T$ and the $n\times n$ matrix $\mathcal{E}^T\mathcal{E}$

Since $\mathcal{E}\mathcal{E}^T$ and $\mathcal{E}^T\mathcal{E}$ are both square matrices, we can find their eigenvalues and eigenvectors through eigendecomposition.

I would suggest that those who are interested in the exact details of this process read this wikipedia article: [Eigendecomposition of a matrix](https://en.wikipedia.org/wiki/Eigendecomposition_of_a_matrix)

For my purposes, I used R's built-in [eigen](https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/eigen) function, which precludes the need to re-implement it myself.






