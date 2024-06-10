# Movie Recommendations:

TODO:
* Section explaining how test / train was selected, since the partition functionw as rewritten. Instead say the charts were developed using fold 1 of the K, and that the full K folds were used for regularization tuning. Then the entire edx set was used for lm and sgd training, and for final evaluation
* mention how weights were tuned for w and lambda
* Redo results and graphs for simple algorithms using fold_index 1
* Mention the lm and matrix factorization approaches you took, which unfortunately did not yield positive results / took too far too long to run.
* Fiddle with the heatmap graph spacing if you really want

## Introduction:

This project implements a machine learning based prediction system for ratings the MovieLens dataset. The full dataset consists of 10,000,054 ratings of 10681 movies by 71567 unique users. Each row in the dataset has columns indicating the user who made the rating, the movie which was rated, the rating given, the timestamp at which it was given, the title of the movie, and the genres that the movie belongs to.

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

Template code provided by the EdX team splits the data into a main dataset $\mathcal{D}$ of 9,000,055 entries and a final holdout test set $\mathcal{F}$ of 999,999 entries to be used exclusively for a final error calculation at the end of the project. The goal is to train a machine learning model on the records in the main dataset which can predict the values in the `rating` column of the final holdout set, using the other column values as predictor variables. The root mean squared error function was used as a metric for the predictive power of the algorithm, with a target RMSE of less than 0.86490.

```
> nrow(edx)
[1] 9000055
> nrow(final_holdout_test)
[1] 999999
>
```
(TODO: Phrase this better)
Initial data analysis was performed on the main dataset, then the data was split into five equally sized subsets, indexed by `fold_index` one through five. Some simple algorithms were explored first to establish a performance benchmark, and for these models, only `fold_index = 1` was used as the test set. The other four sets were merged back together to form the training set. Cross-validation was not done for these models.

The main model used in this project is a modified version of the approach outlined by Robert M. Bell, Yehuda Koren, and Chris, Volinsky in their 2009 paper "The BellKor Solution to the Netflix Grand Prize." An average $\mu$ of all movie ratings in the training set formed a baseline predictor, on top of which were added movie, user, and genre biases - $`{b}_{i}`$, $`{b}_{u}`$, $`{b}_{g}`$. Each bias had an associated regularization parameter, $\lambda_1$, $\lambda_2$, $\lambda_3$, which was tuned to minimize the error on the test set. This process was performed on all five folds for `k=5` fold cross validation. 

(TODO: Find another way to refer to the model other than biasing effect model.)
Each parameter was finalized at the average of the values calculated during the five validation runs. A single pass was then made through the entire training set to find the remaining difference ${r'} = \hat{r} - r$ between the recorded ratings and the ratings predicted by the bias effect model. Two methods were tried to account for these residual values - a matrix factorization model using stochastic gradient descent, and a simple linear model - but neither showed an improvement over the biasing effect model, and were not used for the final RMSE calculation on the holdout set.

The final RMSE on the holdout set was (TODO)

## Data Analysis / Preprocessing:

* splitting section used splitindex

The main dataset was split into training and test sets with the ```partition(seed, subset_p = 1, test_p = 0.2)``` function. The function accepts as parameters a random seed value, as well as optional ```subset_p``` and ```test_p``` parameters. ```subset_p``` specifies how much of the main dataset is used, with a value of 1 indicating the entire dataset, and a value of 0 indicating none of it. This is useful in cases where using the full dataset might be too resource intensive, or for initial code testing. All the final results are reported with the full dataset. ```test_p``` specifies the proportion of the subsetted data to use for the test set ```test_df```; the remaining entries form the training set, ```train_df```.

```test_p = 0.2``` was used exclusively throughout this project.

The ```partition``` function also ensures that every movieId and userId which appears in the test set must appear in the training set - the code to do this was borrowed from the provided template code, which also performs a similar modification for the main data set in relation to the final holdout set. While this is a seemingly small detail, it makes the prediction task **significantly** easier, as it completely eliminates the need to deal with the possibility of making predictions for users or movies which do not appear in the training set, also known as the [cold start problem](https://en.wikipedia.org/wiki/Cold_start_(recommender_systems)).

The training data was further processed to produce the ```genres```, ```users```, and ```movies``` dataframes. The column names are provided below, and should be mostly self-explanatory.

```
> names(genres)
[1] "genres"     "count"      "avg_rating"
> names(movies)
[1] "movieId"    "title"      "year"       "count"      "avg_rating"
> names(users)
[1] "userId"     "count"      "avg_rating"
```

Note genres contains the full genre list string provided for a movie, not an individual genre. This was done mainly for the sake of simplification - the section on genre relationships will touch further on this decision.
```
> head(genres)
                                              genres count avg_rating
1                                 (no genres listed)     4   3.250000
2                                             Action 19548   2.942961
3                                   Action|Adventure 54891   3.659671
4         Action|Adventure|Animation|Children|Comedy  6005   3.969692
5 Action|Adventure|Animation|Children|Comedy|Fantasy   149   3.043624
6    Action|Adventure|Animation|Children|Comedy|IMAX    54   3.222222
```

### User Data Analysis:

Initial data exploration showed very quickly that some users had rated much more movies than others, so much so that the discrepancy is difficult to visualize properly on a graph. Here is an attempt to do so using a box-whisker decile plot:

<div style="display: inline-block;">
  <img src="/movielens/graphs/box-whisker-decile_users.png" alt="User Rating Counts by Decile" title="User Rating Counts by Decile" style="float: center; width: 100%;">
</div>


As the plot shows, the most prolific 10% or so of users have rated so many movies that it immediately blows out the scale of the Y axis, making it difficult to even read the values for the other 90%. Cumulative density functions done on these two groups show that the cutoff for the top 10% of users is about 300 ratings, beyond which the counts begin to skyrocket.

<div style="display: inline-block;">
  <img src="/movielens/graphs/counts_cdf_bottom90_users.png" alt="Cumulative Density of Rating Counts (Bottom 90%)" title="Cumulative Density of Rating Counts (Bottom 90%)" style="float: left; margin-right: 10px; width: 45%;">
  <img src="/movielens/graphs/counts_cdf_top10_users.png" alt="Cumulative Density of Rating Counts (Top 10%)" title="Cumulative Density of Rating Counts (Top 10%)" style="float: left; margin-right: 10px; width: 45%;">
</div>

(TODO: If you have time, make mu, movie bias, and genre bias split along these two user groups)

### Genre Data Analysis:

My initial approach for genres was to split apart the list of genres for each movie, and consider them individually. In total there are twenty unique genres, and similarly to what we saw with users, certain movie genres had a much higher number of ratings, and others very few. However the skew is not nearly as dramatic.

<img src="/movielens/graphs/genre_counts_barplot.png" align="center" alt="Genre Counts"
	title="Genre Counts"/>

I was also curious to see which genres were most likely to appear together on the same movie, so I created the co-occurrence heatmap shown below. Each cell represents the number of movies which have both the genre on the X axis and the genre on the Y axis, with darker values indicating a higher number. Cells along the diagonal (where the X and Y genres are the same) are counts for movies with only that genre associated to it.

<div style="display: inline-block; vertical-align: middle;">
<p>
<img src="/movielens/graphs/genre_co_occurrence_heatmap.png" align="left" style="width: 425px;" alt="Genre Heatmap"
	title="Genre Heatmap"/>

<br>
It is clear that there are certain genres which occur more frequently alongside other ones, but, perhaps unsurprisingly, the most common genres are also the ones most likely to be associated with other genres, and the rarer ones less likely. I tried normalizing the matrix by dividing each row element by the sum of the values in that row, but the result wasn't any more insightful. I decided to stop my exploration into the genre data here, and stick to using the full genre string associated with each movie, rather than over-complicate things by subdividing them into individual genres. There are 797 unique genre strings, as opposed to only 20 unique individual genres, so while some resolution might be lost, in a training set of over 7 million ratings, I did not consider this loss of granularity to be worth the added complexity.
</p>
</div>
<br>
<br>

### Movie Data Analysis

(TODO: Fill this out more)
There are 10677 unique movies in the dataset, with release dates from 1915 to 2008. 
(TODO: Chronological effect, if there's time to do it)

<img src="/movielens/graphs/movie_rating_by_release_year.png" align="center" alt="Average Movie Ratings By Release Year"
	title="Average Movie Ratings By Release Year"/>

## Methods:

Initial tests were done with training and test sets produced by ```partition(seed = 1, subset_p = 1)```

As specified in the project instructions, the root mean squared error function was used as a measure for each algorithms effectiveness.

Let ${r}{_u}{_i}$ denote the observed rating of user $u$ for movie $i$ in some dataset, and let $\hat{r}{_u}{_i}$ signify an algorithm's prediction for how that user would rate the movie. The root mean squared error can then be written as

```math
RMSE = \sqrt{\frac{{\sum}_{u,i\in {D}_{val}}({r}{_u}{_i} - \hat{r}{_u}{_i})^2}{|{D}_{val}|}}
```

where $`{D}_{val}`$ is our validation (eg. test) set. It is, as the name would suggest, the square root of the mean of the square of the error. Error is commonly defined as the difference between the predicted vs. actual values - for this reason RMSE is also frequently called RMSD, or Root Mean Squared Difference. In code this relationship is much clearer:

```
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  errors <- predicted_ratings - actual_ratings
  squared_errors <- errors^2
  mean_of_squared_errors <- mean(squared_errors)
  rmse <- sqrt(mean_of_squared_errors)
  return(rmse)
}
```

### Some Simple Algorithms to Start

(TODO: These algorithms were all run using fold index 1 to create the training and test sets)

A couple of very basic methods for rating prediction come to mind, and these were the ones I tried first while building out the testing framework. The code for them is in the ```simple-algorithms.R``` file. (TODO: Specify where the files are for each section)

The most naive approach would be to randomly guess a rating - as one would expect, this gave a very poor RMSE of ~2.16. Next was to find the average of all the ratings in the training set, and to use that value as the prediction for every rating in the test set. If we look to the histogram plot of the ratings given in the training set, we see that whole number ratings are more common than ones rated at half integer increments - this I would attribute to user psychology more than anything else. Taken individually, the set of whole number ratings and the set of half-step ratings both form bell-curve shaped distributions centered roughly around the global mean, shown as the dashed vertical red line.

<img src="/movielens/graphs/rating_histogram.png" align="center" alt="Ratings Histogam"
	title="Ratings Histogram"/>

Always predicting the global mean might not be a very sophisticated approach, but it minimizes the distance from observed ratings more so than any other static value. In any case, it is much better than making random guesses, and gives a much improved RMSE of ~1.06.

Per-genre average, per-user average, and per-movie average is a slightly more nuanced approach, producing a mean for each genre, user, or movie, and making that our guess, rather than the global average. This takes into account that some genres / users / movies might tend to rate higher or lower, and by taking the mean of specific subsets of ratings rather than the entire set, we capture slightly more detail and were able to incrementally improve the rmse.

Finally, I tried an ensemble of the user and movie averages. In the case where the two are equally weighted, the predicted value is defined as $`\hat{r}{_u}{_i} = \frac{(\bar{r}_{u} + \bar{r}_{i})}{2}`$, with the average rating for user $u$ and movie $i$ as $`\bar{r}_{u}`$ and $`\bar{r}_{i}`$ respectively. This yielded an RMSE of ~0.913, To see whether this could be improved by weighting the average, the prediction was redefined as $`\hat{r}{_u}{_i} = {w} * \bar{r}_{u} + (1 - {w}) * \bar{r}_{i}`$, with ${w}$ being the weight assigned to the user average, and $1-{w}$ the weight for the movie average. The plot below shows the RMSE across the test set plotted against values of ${w}$ ranging from 0.2 to 0.6.

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

A more sophisticated approach similar to the one found in Koren et al.'s (TODO: format) 2009 paper was tried next. Rather than taking the average rating for each movie, we instead find the biasing effect $`{b}_{i}`$ for each movie, defined as the average difference of the observed ratings for all users on that movie from the global average $\mu$ of all movie ratings, such that $`{b}_{i} = \frac{\sum_{u\in R(i)}{r}{_u}{_i} - \mu}{|R(i)|}`$, with ${u\in R(i)}$ being all users $u$ who have rated movie $i$, and $|R(i)|$ as the size of that set of users. We likewise define the user bias to be the average of the observed ratings, minus the global mean plus the movie bias: $`{b}_{u} = \frac{\sum_{i\in R(u)}{r}{_u}{_i} - (\mu+{b}_{i})}{|R(u)|}`$, and the genre bias to be the average of the observed, minus the global mean plus the user and movie biases: $`{b}_{g} = \frac{\sum_{u,i\in R(g)}{r}{_u}{_i} - (\mu+{b}_{i}+{b}_{u})}{|R(g)|}`$, where $`{u,i\in R(g)}`$ is some user $u$ rating a movie $i$ which has genre $g$, and $|R(g)|$ is the size of the set of all ratings for that genre.

Please note again that "genre" in this case refers to the entire genre list string attached to a given movie. As mentioned previously, I did not feel it was worth the added complexity of finding the biasing effects of each the 20 individual genres, and instead treated the entire genre list string as one item.

These equations were implemented in code using R's `aggregate` function. Again, the code might be easier to understand than the mathematical equations, so I've included a shortened version below (the `_0` suffix indicates that these are unregularized biases - more on that in the Bias Regularization section).:
```
movies <- aggregate((rating-mu) ~ movieId, data = train_df, FUN = mean)
users <- aggregate((rating-(mu+b_i_0)) ~ userId, data = train_df, FUN = mean)
genres <- aggregate((rating-(mu+b_i_0+b_u_0)) ~ genres, data = train_df, FUN = mean)
```

Once the biasing effects $`{b}_{i}`$, $`{b}_{u}`$, and $`{b}_{g}`$ are calculated for each movie, user, and list of genres, we simply add them on top of the global rating average $\mu$ to find the predicted rating $`\hat{r}{_u}{_i} = \mu + {b}_{i} + {b}_{u} + {b}_{g}`$,

I layered the biasing effects onto the global average one at a time, and the results are shown below:

<div align = "center">
	
| Algorithm | RMSE |
| :-: | :-: |
| mu + b_i_0 | 0.9441866 |
| mu + b_i_0 + b_u_0 | 0.8665665 |
| mu + b_i_0 + b_u_0 + b_g_0 | 0.8662257 |

</div>

### Bias Regularization Tuning With K = 5 Fold Cross Validation
(TODO)
The variance of the mean value of a sample can be defined as $`Var(\bar{r}) = \frac{\sigma^2}{n}`$ for a sample of size $n$ taken from a population that has some variance $`\sigma^2`$. This equation shows that the variance of the sample mean is inversely proportional to the sample size - for movies, users, or genres with very few ratings in the training set, the calculated biasing effect (essentially a sample mean) will vary significantly based on the specific ratings randomly selected for inclusion.

To counteract this, I adopted Koren et al.'s approach by including a regularization in the bias calculation:

```math
	
{b}_{i_{reg}} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{\lambda_1 + |R(i)|} \quad \quad
{b}_{u_{reg}} = \sum_{u,i\in R(u)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}})}{\lambda_2 + |R(u)|} \quad \quad
{b}_{g_{reg}} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}})}{\lambda_3 + |R(g)|}

```

When the sample size $|R|$ is small, $\lambda$ significantly reduces the bias, while for larger sample sizes this effect diminishes, approaching 0 as $|R|$ increases. This reduces the influence of noisy biasing effects caused by small sample sizes, while preserving the bias effects we have greater confidence in.

Similar to the weighted average parameter tuning process, (TODO: phrase better) values for $\lambda$ were stepped in 0.001 increments and plotted against the resulting RMSE on the test set. The value which minimized the RMSE was picked at each stage before moving on to the next parameter.

<div style="display: inline-block;">
	<img src="/movielens/graphs/l1-tuning-square-fold-1.png" alt="L1 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: left; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l2-tuning-square-fold-1.png" alt="L2 Tuning Fold 1" title="L2 Tuning Fold 1" style="float: center; margin-left: 5px; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l3-tuning-square-fold-1.png" alt="L3 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: right; margin-left: 5px; width: 30%;">
</div>

(TODO: Rephrase. Maybe talk more about what K-fold cross validation is.)
As mentioned, the biasing effects are quite sensitive to the randomness of the training / test set split, and consequently so are their tuning parameters. To counteract this, the full dataset was split into 5 folds and the process was run once on each fold. The results of the first fold is shown above (plots for the other folds are included in the repository, but omitted for brevity), and a summary of the tuned values across all five folds, along with the resulting RMSE, is presented below.

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






