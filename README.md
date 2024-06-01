# Movie Recommendations:

## Introduction:

The goal of this project is to implement a machine learning based recommendation system for the MovieLens dataset. The full dataset consists of 10000054 ratings of 10681 movies by 71567 unique users, along with associated metadata. Template code provided by the EdX team splits the data into a main dataset $\mathcal{D}$ and a final holdout test set $\mathcal{F}$ to be used exclusively for a final error calculation at the end of the project.

The approach here is a modified version of the one outlined by Robert M. Bell, Yehuda KorenChris, Volinsky in their 2009 paper "The BellKor Solution to the Netflix Grand Prize." 

$\mathcal{D}$ was split into training and test sets with ```p = 0.8``` and ```0.2``` respectively. An average $\mu$ of all movie ratings in the training set formed a baseline predictor, on top of which were added movie, user, and genre biases - $`{b}_{i}`$, $`{b}_{u}`$, $`{b}_{g}`$. After tuning regularization parameters $\alpha_1$, $\alpha_2$, $\alpha_3$ for each of them, this combination resulted in an root mean squared error (RMSE) of ```0.8563``` on the test set.

* K Fold Validation
* SGD
* Final Output


## Methods / Analysis

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

Note genres contains the full genre list string provided for a movie, not an individual genre. This was done mainly for the sake of simplification.
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

Initial tests were done with training and test sets produced by ```partition(seed = 1, subset_p = 1)```

The average of all ratings in the training set was stored with a simple ```mu <- mean(train_df$rating)```, and applying this 






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

Observed rating of user $u$ for movie $i$: ${r}{_u}{_i}$

(Genre set for movie i)

(Clarify that the following are derived from the training (eg. non-validation) folds)

Average Rating function $\bar{r}_{(...)}$, such that:

Average rating across all users and movies in the training set: $\bar{r}_{(\kappa)}$ or $\mu$

Average rating for a movie $i$ : $\bar{r}_{(i)}$

Average rating for a user $u$ : $\bar{r}_{(u)}$

Sets $R(u)$ and $R(i)$ denoting all movies rated by user $u$ and all users who have rated movie $i$, respectively

(Check) Set $R(g)$ denoting all pairs $(u,i)$ of users and movies which have rated a movie with genre set $g$

(Update code to use alpha instead of lambda for regularization

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





Predicted rating for user $u$'s rating of movie $i$ : $\hat{r}{_u}{_i}$

Root Mean Squared Error (RMSE): $`{\sum}_{u,i\in {D}_{val}} \frac{({r}{_u}{_i} - \hat{r}{_u}{_i})^2}{|{D}_{val}|}`$
