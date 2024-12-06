# Movie Recommendations:

## Introduction:

This project is a machine learning based prediction system for movie ratings in the MovieLens dataset. The full dataset consists of 10,000,054 ratings, 10,677 movies, and 69,878 unique users. Each row has columns indicating the ID of the user who made the rating, the ID of the movie which was rated, the rating given, the timestamp at which it was given, the title of the movie, and the genres that the movie belongs to. Ratings can range from 0 to 5, at half-integer increments.

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

Template code provided by the EdX team splits the data into a main dataset of 9,000,055 entries and a final holdout test set of 999,999 entries to be used exclusively for a final error calculation at the end of the project. The goal is to train a machine learning model on the records in the main dataset which can reliably predict values in the `rating` column of the final holdout set, using the other column values as predictor variables. The root mean squared error function is used as a metric for the predictive power of the algorithm, with a target RMSE of less than 0.86490.

```
> nrow(edx)
[1] 9000055
> nrow(final_holdout_test)
[1] 999999
>
```
Data analysis was performed on the main dataset as a whole. For model development, the data was split into five equally sized subsets, indexed by `fold_index` one through five. Some simple algorithms were explored first to establish a performance benchmark - for these models, `fold_index = 1` was used as the test set and the other four sets were merged back together to form the training set. Cross-validation was not done on these models.

The main model used in this project is a modified version of the approach outlined by Robert M. Bell, Yehuda Koren, and Chris Volinsky in their 2009 paper "The BellKor Solution to the Netflix Grand Prize." An average $\mu$ of all movie ratings in the training set formed a baseline predictor, on top of which were added movie, user, and genre biases: $`{b}_{i}`$, $`{b}_{u}`$, and $`{b}_{g}`$ respectively. Each bias has an associated regularization parameter, $\lambda_1$, $\lambda_2$, $\lambda_3$, which was tuned to minimize the error on the test set. This process was performed on all five folds for `k=5` fold cross validation. 

The tuning parameters were finalized using the average of the optimal values calculated during each of the five validation runs. A single pass was then made through the entire main dataset to find the residual differences ${r'} = \hat{r} - r$ between the recorded ratings and the ratings predicted by the model. Two methods were attempted to model these residual values - a matrix factorization model using stochastic gradient descent, and a simple time factor linear model - but neither showed improvement over the base model, and were not used for the final RMSE calculation on the holdout set.

The final RMSE on the holdout set was 0.8653710.

## Preprocessing:
The provided template code downloads the MovieLens dataset and splits the data into `edx` and `final_holdout_test` dataframes, with a proportion of `p = 0.1` for the latter.

The `edx` set is then split into five folds using `createFolds`, with the `rating` column assigned as the response vector to ensure that rating values are equally distributed among each fold. Each fold is an equal length list of unique, non-overlapping indices corresponding to rows from the `edx` set.

The `generate_splits` function accepts a `fold_index` parameter designating one of the five folds as the test set, and the remaining folds are merged together to form the training set. The two sets are passed to the `consistency_check` function before being assigned as the `test_df` and `train_df` dataframes.

`consistency_check` ensures that every `movieId` and `userId` which appears in the test set also appears in the training set. The code to do this was borrowed from the provided template code, which performs a similar modification for the main dataset in relation to the final holdout set. While this may seem to be a minor detail, it makes the prediction task **significantly** easier, as it completely eliminates the need to make predictions on users or movies which do not appear in the training set, also known as the [cold start problem](https://en.wikipedia.org/wiki/Cold_start_(recommender_systems)).

The training set was further processed to produce the ```genres```, ```users```, and ```movies``` dataframes. The column names for these dataframes are shown below, and should be self-explanatory.

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

---

### Genre Data Analysis:

In total there are 20 unique genres, and similarly to what we saw with users, certain movie genres had a much higher number of ratings, and others very few. However the skew is not nearly as dramatic:

<img src="/movielens/graphs/genre_counts_barplot.png" align="center" alt="Genre Counts"
	title="Genre Counts"/>

I was curious to see which genres were most likely to appear together on the same movie, so I created the co-occurrence heatmap matrix shown below. Each cell represents the number of movies which have both the X-axis genre and the Y-axis genre, with darker values indicating more. Cells along the diagonal (where the X and Y genres are the same) are counts for movies with just that one genre associated to it.

<div style="display: inline-block; vertical-align: middle;">
<p>
<img src="/movielens/graphs/genre_co_occurrence_heatmap.png" align="left" style="width: 425px;" alt="Genre Heatmap"
	title="Genre Heatmap"/>

<br>
It is clear that there are certain genres which occur more frequently alongside others, but, perhaps unsurprisingly, this can largely be attributed to popularity - the most common genres also tend to have the highest co-occurrence counts. I tried normalizing the matrix by dividing each row element by the sum of the values in that row, but the result wasn't any more insightful. I decided to stop my exploration into the genre data here, and stick to using the full genre string associated with each movie, rather than over-complicate things by subdividing them into individual genres. There are 797 unique genre strings, as opposed to only 20 unique individual genres, so while some resolution might be lost, in a dataset of over 9 million ratings, I did not consider this loss of granularity to be worth the added complexity.
</p>
</div>
<br>
<br>
<br>
<br>

---

### Movie Data Analysis

There are 10,677 unique movies in the dataset, with release dates ranging from 1915 to 2008. As with users and genres, there are some movies which are substantially more popular than others.

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

There is also good evidence of chronological effect on movie ratings. Older movies tend to recieve higher average ratings than newer movies, which generally show greater variation in user ratings. One possible explanation might be that older movies are more likely to only be viewed and rated by users who are fans of old movies, while newer movies are rated by a broader audience. It could also be the case that only the good movies from past decades are remembered and included in the MovieLens library, while the rest are lost to time.

<img src="/movielens/graphs/movie_rating_by_release_year.png" align="center" alt="Average Movie Ratings By Release Year"
	title="Average Movie Ratings By Release Year"/>

## Methods:

The project instructions specify using the root mean squared error function as the measure for each algorithms effectiveness. As the name would suggest, it is calculated by taking the square **root** of the **mean** of the **square** of the **error** (error in this case being the difference between the predicted and observed values. For this reason, the RMSE is also frequently referred to as the **RMSD**, or root mean squared **difference**). Mathematically, we define it with the following:

Let ${r}{_u}{_i}$ denote the observed rating of user $u$ for movie $i$ in some dataset, and let $\hat{r}{_u}{_i}$ signify an algorithm's prediction for how that user would rate the movie. The root mean squared error can then be written as

```math
RMSE = \sqrt{\frac{{\sum}_{u,i\in {D}_{test}}({r}{_u}{_i} - \hat{r}{_u}{_i})^2}{|{D}_{test}|}}
```

where $`{D}_{test}`$ is our test set.

Each algorithm produces a list of predicted ratings of equal length to the `rating` column in `test_df`, which contains the actual observed ratings in the test set. Feeding these two lists into the `calculate_rmse` function returns a single RMSE value for the algorithm, which is then stored in `rmse_df` dataframe along with the algorithm's name and the `fold_index` that the model was run on.

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

A couple of very basic methods for rating prediction come to mind, and these were the ones I tried first while building out the testing framework.

The most naive approach would be to randomly guess a rating. Naturally, this gave a very poor RMSE of ~2.16. The next method was to find the average of all ratings in the training set, and to use that value as the prediction for every rating in the test set. If we look to the histogram plot of the ratings given in the training set, we see that whole number ratings are more common than ones rated at half integer increments (this I would attribute to user psychology more than anything else), but the set of whole number ratings and the set of half-step ratings both form bell-curve shaped distributions centered roughly around the global mean, shown as the dashed vertical red line.

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

A more sophisticated approach is presented in Koren et al.'s 2009 paper, The BellKor Solution to the Netflix Grand Prize. Rather than taking the average rating for each movie, we instead find the biasing effect $`{b}_{i}`$ for each movie, defined as the average difference of the observed ratings for all users on that movie from the global average $\mu$ of all movie ratings, such that $`{b}_{i} = \frac{\sum_{u\in R(i)}{r}{_u}{_i} - \mu}{|R(i)|}`$, with ${u\in R(i)}$ being all users $u$ who have rated movie $i$, and $|R(i)|$ as the size of that set of users. We likewise define the user bias to be the average of the observed ratings, minus the sum of the global mean and the movie bias: $`{b}_{u} = \frac{\sum_{i\in R(u)}{r}{_u}{_i} - (\mu+{b}_{i})}{|R(u)|}`$, and the genre bias to be the average of the observed minus the sum of the global mean and the user and movie biases: $`{b}_{g} = \frac{\sum_{u,i\in R(g)}{r}{_u}{_i} - (\mu+{b}_{i}+{b}_{u})}{|R(g)|}`$, where $`{u,i\in R(g)}`$ is some user $u$ rating a movie $i$ which has genre $g$, and $|R(g)|$ is the size of the set of all ratings for that genre.

(Please note again that "genre" in this case refers to the entire genre list string attached to a given movie. As mentioned previously, I did not feel it was worth the added complexity of finding the biasing effects of each the 20 individual genres, and instead treated the entire genre list string as one item.)

These equations were implemented in code using R's `aggregate` function. The code might be easier to understand than the mathematical equations, so I've included a shortened version below (the `_0` suffix indicates that these are unregularized biases - more on that in the Bias Regularization section).:
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

The variance of the mean value for a sample can be defined as $`Var(\bar{r}) = \frac{\sigma^2}{n}`$ for a sample of size $n$ taken from a population that has some variance $`\sigma^2`$. This equation shows that the variance of the sample mean is inversely proportional to the sample size, so in our context, when movies, users, or genres have very few ratings in the training set, the calculated biasing effect (which is essentially a sample mean) will vary significantly based on the specific ratings randomly selected for inclusion.

I adopted Koren et al.'s approach to mitigating this problem by including a regularization parameter $\lambda$ into each bias calculation:

```math
	
{b}_{i_{reg}} = \sum_{u\in R(i)} \frac{{r}{_u}{_i} - \mu}{\lambda_1 + |R(i)|} \quad \quad
{b}_{u_{reg}} = \sum_{u,i\in R(u)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}})}{\lambda_2 + |R(u)|} \quad \quad
{b}_{g_{reg}} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}})}{\lambda_3 + |R(g)|}

```

When the sample size $|R|$ is small, $\lambda$ significantly reduces the bias, and for larger sample sizes this effect diminishes, approaching 0 as $|R|$ increases. This reduces the influence of noisy biasing effects caused by small sample sizes, while preserving the bias effects we have greater confidence in.

Similar to the tuning process for the weighted average parameter, values for $\lambda$ were stepped in 0.001 increments and plotted against the resulting RMSE on the test set. The value which minimized the RMSE was picked at each stage before moving on to the next parameter.

<div style="display: inline-block;">
	<img src="/movielens/graphs/l1-tuning-square-fold-1.png" alt="L1 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: left; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l2-tuning-square-fold-1.png" alt="L2 Tuning Fold 1" title="L2 Tuning Fold 1" style="float: center; margin-left: 5px; margin-right: 5px; width: 30%;">
	<img src="/movielens/graphs/l3-tuning-square-fold-1.png" alt="L3 Tuning Fold 1" title="L1 Tuning Fold 1" style="float: right; margin-left: 5px; width: 30%;">
</div>

Since the biasing effects are sensitive to the randomness of the training / test set split, so are their tuning parameters. To counteract this, the full dataset was split into 5 folds and the tuning process was run on each fold. The plots for the first fold are shown above (plots for the other folds are included in the repository, but omitted for brevity), and a summary of the tuned values across all five folds, along with the resulting RMSE, is presented below:

<div align = "center">

| Fold | L1 | L2 | L3 | RMSE |
| :-: | :-: | :-: | :-: | :-: |
| Fold 1 | 1.947 | 4.836 | 27.167 | 0.8656432 |
| Fold 2 | 2.347 | 4.974 | 15.209 | 0.8653785 |
| Fold 3 | 2.083 | 4.859 | 0 | 0.8653743 |
| Fold 4 | 2.272 | 4.959 | 12.262 | 0.8649200 |
| Fold 5 | 2.151 | 5.307 | 4.07 | 0.8647899 |

</div>

### Attempts to further reduce residual values $r'$

The regularization parameters were averaged across all five folds, for final values of $\lambda_1 = 2.16$, $\lambda_2 = 4.987$, and $\lambda_3 = 11.7416$. Values for $\hat{r}{_u}{_i}$ were calculated for all ratings in the EdX dataset, and a list of residual values was produced.

```
edx$r <- edx$rating - (mu + movie_bias + user_bias + genre_bias)
```

These residual values represent portion of the ratings which the sum of the global average and the biasing effects are unable to account for. I attempted two methods to model the residuals, with the goal of adding the predicted residuals on top of the predicted ratings to reduce the final RMSE calculation. Both models were unfortunately unsuccessful in this regard, so I will only touch on them briefly. Code related to them is included in the repository, but should not be considered part of the main project.

The first attempt was to use Stochastic Gradient Descent to create `k=2` latent factor matrices for both the users and movies. Matrix factorization is a process by which a large matrix is decomposed into a product of two smaller matrices. In our case, I intended to produce an ${m} X {2}$ matrix ${P}$ for the users, and an ${n} X {2}$ matrix ${Q}$ for movies, where $`m = |\{u\in \mathcal{D}\}|`$, $`n = |\{i\in \mathcal{D}\}|`$, such that the product ${P}*{Q}^T$ would approximate the $m\times n$ residuals matrix $\mathcal{E}$.

```math
\mathcal{E} = \begin{pmatrix}
r'_{11} & r'_{12} & \cdots & r'_{1n} \\
r'_{21} & r'_{22} & \cdots & r'_{2n} \\
\vdots & \vdots & \ddots & \vdots \\
r'_{m1} & r'_{m2} & \cdots & r'_{mn} \\
\end{pmatrix}
```

 where each entry $`{r'}{_u}{_i} = {r} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}}+{b}_{g_{reg}})`$. The factorization algorithm I wrote took far too long to make even single pass through the training data, and I was unable to increase the learning rate without causing the algorithm to diverge rather than converge. This is definitely an area of further research I would like to spend more time on in the future, but this started to turn into a mini-project in itself, and in the end I decided to focus on using the techniques we learned during the course.

<img src="/movielens/graphs/learning_rate.png" align="center" alt="Learning Rate"
	title="Learning Rate"/>

Having spent far too long trying and failing to tune the SGD code, I decided to try a very simple time factor model for the movie residuals. A linear model was produced for each movie to predict the residuals as a factor of the timestamp. This was admittedly far too simple of an approach; I should have spent more time analyzing the chronological effects on ratings, instead of throwing everything into the `lm` function and hoping for the best, but I was feeling quite discourged from the wasted effort on the SGD model, and also running out of time to complete the project. These models did not yield positive results on the test sets produced by `createFolds`.


## Results

Final result calculations were peformed with regularization parameters $\lambda_1 = 2.16$, $\lambda_2 = 4.987$, and $\lambda_3 = 11.7416$. The biasing effects were recalculated using these values on the `fold_index=1` fold. This was actually done by mistake - I had intended to apply it to the entire training set, but my local R environment was not set up properly. Having already calculated the RMSE on the final holdout set using these incorrectly set biasing effects, I felt I should accept the mistake rather than run the final RMSE calculation more than once, which we were explicitly told not to do. The final RMSE, and the RMSEs of all the algorithms produced in the course of this project are shown below.

<div align = "center">
	
| Algorithm | RMSE | Fold |
| :-: | :-: | :-: |
| Random Guess | 2.1575303 | 1 |
| Avg All | 1.0604283 | 1 |
| Genre Avg | 1.0183814 | 1 |
| User Avg | 0.9790523 | 1 |
| Movie Avg | 0.9441866 | 1 |
| User and Movie Avg, Equal Weight Ensemble | 0.9137740 | 1 |
| User Movie Avg Weighted Ensemble, w =  0.4069 | 0.9120644 | 1 |
| mu + b_i_0 | 0.9441866 | 1 |
| mu + b_i_0 + b_u_0 | 0.8665665 | 1 |
| mu + b_i_0 + b_u_0 + b_g_0 | 0.8662257 | 1 |
| mu + b_i_reg | 0.9441361 | 1 |
| mu + b_i_reg + b_u_reg | 0.8659429 | 1 |
| mu + b_i_reg + b_u_reg + b_g_reg | 0.8656432 | 1 |
| mu + b_i_reg | 0.9437307 | 2 |
| mu + b_i_reg + b_u_reg | 0.8656964 | 2 |
| mu + b_i_reg + b_u_reg + b_g_reg | 0.8653785 | 2 |
| mu + b_i_reg | 0.9438586 | 3 |
| mu + b_i_reg + b_u_reg | 0.8656873 | 3 |
| mu + b_i_reg + b_u_reg + b_g_reg | 0.8653743 | 3 |
| mu + b_i_reg | 0.9432518 | 4 |
| mu + b_i_reg + b_u_reg | 0.8652172 | 4 |
| mu + b_i_reg + b_u_reg + b_g_reg | 0.8649200 | 4 |
| mu + b_i_reg | 0.9432800 | 5 |
| mu + b_i_reg + b_u_reg | 0.8650870 | 5 |
| mu + b_i_reg + b_u_reg + b_g_reg | 0.8647899 | 5 |
| Final RMSE | 0.8653710 | X |

</div>

Even though the biasing effects were calculated on only a subset of the full training set, the results were in line with what I expected given what I saw in previous runs. I regretfully was not able to trim the values in the residuals matrix with a functioning SGD or LM model, so the final RMSE falls a little short of the original target. Overall however, I am satisfied with my results.

## Conclusion

This project demonstrated the potential of applying machine learning techniques in predicting ratings on the MovieLens dataset. Data analysis on the users, movies and genres revealed important insights into the dataset. Some simple algorithms and an ensemble model were used to establish a baseline for model performance. The final model presented uses a combination of the global mean rating average and the biasing effects of users, movies, and genres to predict the observed outcome. Regularization parameters were tuned using K-fold cross validation, and the average of the optimal values on the five folds was used to obtain a final RMSE value of 0.8653710 on the holdout test set. Two very promising methods of further refining the predictive model - matrix factorization and time based modelling - were explored in the course of this project, but ultimately abandoned due to time constraints. These will for now remain areas for future investigation. 

## References

Koren, Y. (2009). The BellKor Solution to the Netflix Grand Prize. . https://www2.seas.gwu.edu/~simhaweb/champalg/cf/papers/KorenBellKor2009.pdf

Movielens Dataset:
https://grouplens.org/datasets/movielens/10m/
