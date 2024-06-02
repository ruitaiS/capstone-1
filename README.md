# Movie Recommendations:

## Introduction:

The goal of this project is to implement a machine learning based prediction system for ratings the MovieLens dataset. The full dataset consists of 10000054 ratings of 10681 movies by 71567 unique users, along with associated metadata. Template code provided by the EdX team splits the data into a main dataset $\mathcal{D}$ and a final holdout test set $\mathcal{F}$ to be used exclusively for a final error calculation at the end of the project.

The approach here is a modified version of the one outlined by Robert M. Bell, Yehuda KorenChris, Volinsky in their 2009 paper "The BellKor Solution to the Netflix Grand Prize." 

$\mathcal{D}$ was split into training and test sets with ```p = 0.8``` and ```0.2``` respectively. An average $\mu$ of all movie ratings in the training set formed a baseline predictor, on top of which were added movie, user, and genre biases - $`{b}_{i}`$, $`{b}_{u}`$, $`{b}_{g}`$. After tuning regularization parameters $\alpha_1$, $\alpha_2$, $\alpha_3$ for each of them, the root mean squared error (RMSE) was calculated on the test set.

The training set was then split into four sets of ```p = 0.2``` each, and the process was repeated using each of these sets as the new test set, with the remaining three sets plus the original test set forming the new training set, effectively reproducing the results of a ```k=5``` K-fold cross validation test. The optimal parameter values (those which produced the lowest average RMSE across the 5 folds) were selected.

Matrix factorization with stochastic gradient descent was used to account for the remaining residuals ${r'}$, but at the time of this writing have not yielded results better than the average + biasing effects alone.

* Final Output

## Data Analysis / Preprocessing:

The main dataset was split into training and test sets with the ```partition(seed, subset_p = 1, test_p = 0.2)``` function. The function accepts as parameters a random seed value, as well as optional ```subset_p``` and ```test_p``` parameters. ```subset_p``` specifies how much of the main dataset is used, with a value of 1 indicating the entire dataset, and a value of 0 indicating none of it. This is useful in cases where using the full dataset might be too resource intensive, or for initial code testing. All the final results are reported with the full dataset. ```test_p``` specifies the proportion of the subsetted data to use for the test set ```test_df```; the remaining entries form the training set, ```train_df```.

```test_p = 0.2``` was used exclusively throughout this project.

The ```partition``` function also ensures that every movieId and userId which appears in the test set must appear in the training set - the code to do this was borrowed from the provided template code, which also performs a similar modification for the main data set in relation to the final holdout set. While this is a seemingly small detail, it makes the recommendation task **significantly** easier, as it completely eliminates the need to deal with the possibility of making recommendations for users or movies which do not appear in the training set, also known as the [cold start problem](https://en.wikipedia.org/wiki/Cold_start_(recommender_systems)).

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

(TODO: Figure out where to put this:)
If we look to the density plot of the ratings given in the training set, we see that most movies are rated 3 or 4. Whole number ratings are more common than .5s.

<img src="/movielens/graphs/rating_histogram.png" align="center" alt="Ratings Histogam"
	title="Ratings Histogram"/>

### User Data Analysis:

Initial data exploration showed very quickly that some users had rated much more movies than others, so much so that the discrepancy is difficult to visualize properly on a graph. Here is an attempt to do so using a box-whisker decile plot:

<div style="display: inline-block;">
  <img src="/movielens/graphs/box-whisker-decile.png" alt="Box-and-Whisker Plot of Rating Counts by Decile" title="Box-and-Whisker Plot of Rating Counts by Decile" style="float: center; width: 100%;">
</div>


As the plot shows, the most prolific 10% or so of users have rated so many movies that it immediately blows out the scale of the Y axis, making it difficult to even read the values for the other 90%. Cumulative density functions done on these two groups show that the cutoff for the top 10% of users is about 250 ratings, beyond which the counts begin to skyrocket.

<div style="display: inline-block;">
  <img src="/movielens/graphs/counts_cdf_bottom90.png" alt="Cumulative Density of Rating Counts (Bottom 90%)" title="Cumulative Density of Rating Counts (Bottom 90%)" style="float: left; margin-right: 10px; width: 45%;">
  <img src="/movielens/graphs/counts_cdf_top10.png" alt="Cumulative Density of Rating Counts (Top 10%)" title="Cumulative Density of Rating Counts (Top 10%)" style="float: left; margin-right: 10px; width: 45%;">
</div>

(TODO: If you have time, make mu, movie bias, and genre bias split along these two user groups)

### Genre Data Analysis:

My initial approach for genres was to split apart the list of genres for each movie, and consider them individually. In total there are twenty unique genres, and similarly to what we saw with users, certain movie genres had a much higher number of ratings, and others very few. However the skew is not nearly as dramatic.

<img src="/movielens/graphs/genre_counts_barplot.png" align="center" alt="Genre Counts"
	title="Genre Counts"/>

I was also curious to see which genres were most likely to appear together on the same movie, so I created the co-occurrence heatmap shown below. Each cell represents the number of movies which have both the genre on the X axis and the genre on the Y axis, with darker values indicating a higher number. Cells along the diagonal (where the X and Y genres are the same) are counts for movies with only that genre associated to it.

<img src="/movielens/graphs/genre_co_occurrence_heatmap.png" align="center" alt="Genre Heatmap"
	title="Genre Heatmap"/>

It is clear that there are certain genres which occur more frequently alongside other ones, but, perhaps unsurprisingly, the most common genres are also the ones most likely to be associated with other genres, and the rarer ones less likely. I tried normalizing the matrix by dividing each row element by the sum of the values in that row, but the result wasn't any more insightful. I decided to stop my exploration into the genre data here, and stick to using the full genre string associated with each movie, rather than over-complicate things by subdividing them into individual genres. There are 797 unique genre strings, as opposed to only 20 unique individual genres, so while some resolution might be lost, in a training set of over 7 million ratings, I did not consider this loss of granularity to be worth the added complexity.

### Movie Data Analysis

(TODO: Fill this out more)
There are 10677 unique movies in the dataset, with release dates from 1915 to 2008. 
(TODO: Chronological effect, if there's time to do it)

## Methods:

Initial tests were done with training and test sets produced by ```partition(seed = 1, subset_p = 1)```

As specified in the project instructions, the root mean squared error function was used as a measure for each algorithms effectiveness.

Let ${r}{_u}{_i}$ denote the observed rating of user $u$ for movie $i$ in some dataset, and let $\hat{r}{_u}{_i}$ signify an algorithm's prediction for how that user would rate the movie. The root mean squared error can then be written as

```math
\sqrt{{\sum}_{u,i\in {D}_{val}} \frac{({r}{_u}{_i} - \hat{r}{_u}{_i})^2}{|{D}_{val}|}}
```

where $`{D}_{val}`$ is our validation (eg. test) set. It is, as the name would suggest, the square root of the mean of the square of the error, or the difference between the predicted and actual values. For this reason, RMSE is also frequently called RMSD, or Root Mean Squared Difference. In code this equation is much easier to understand:

```
calculate_rmse <- function(predicted_ratings, actual_ratings) {
  errors <- predicted_ratings - actual_ratings
  squared_errors <- errors^2
  mean_of_squared_errors <- mean(squared_errors)
  rmse <- sqrt(mean_of_squared_errors)
  return(rmse)
}
```

### Some Simple Algorithms

A couple of very basic methods for rating prediction come to mind, and these were the ones I tried first while building out the testing framework. The code for them is in the ```simple-algorithms.R``` file. (TODO: Specify where the files are for each section)

The most naive approach would be to randomly guess a rating - as one would expect, this gave a very poor RMSE of ~2.16. Next was to find the average of all the ratings in the training set, and to use that value as the prediction for the ratings in the test set. This gives a much improved RMSE of ~1.06. 


The results of these simple algorithms are tallied below:
	
| Algorithm | RMSE |
| :-: | :-: |
| Random Guess | 2.1553650|
| Avg All | 1.0605995 |
| Genre Avg | 1.0184635
| User Avg | 0.9790682 |
| Movie Avg | 0.9437667 |
| User and Movie Avg, Equal Weight Ensemble | 0.9133540 |
| User and Movie Avg Weighted Ensemble, w =  0.4062 | 0.9116089 |


## Results

a results section that presents the modeling results and discusses the model performance

## Conclusion

a conclusion section that gives a brief summary of the report, its limitations and future work

## References
Movielens Dataset:
https://grouplens.org/datasets/movielens/10m/




## Formulas and Notation:

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

Regularized bias for genre $g$: $`{b}_{g_0} = \sum_{u,i\in R(g)} \frac{{r}{_u}{_i} - (\mu+{b}_{i_{reg}}+{b}_{u_{reg}})}{\alpha_3 + |R(g)|}`$

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






