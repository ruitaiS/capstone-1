# Movie Recommendations:

# Formulas

RMSE = $`\\sum_{n=1}^{\\infty} 2^{-n} = 1 $


$$\\sum_{i=1}^{|\kappa|} (r_i{_j} - \hat{r}{_i}{_j})^2$$

$$\sqrt{\frac{\sum_{i=1}^{n}  (r_i_j - \hat{r}_i_j)^2}{n}}$$

* 0 points: The report is either not uploaded or contains very minimal information AND/OR the report is not written in English AND/OR the report appears to violate the edX Honor Code.

* 10 points: Multiple required sections of the report are missing.

* 15 points: The methods/analysis or the results section of the report is missing or missing significant supporting details. Other sections of the report are present.

* 20 points: The introduction/overview or the conclusion section of the report is missing, not well-presented or not consistent with the content.

* 20 points: The report includes all required sections, but the report is significantly difficult to follow or missing supporting detail in multiple sections.

* 25 points: The report includes all required sections, but the report is difficult to follow or missing supporting detail in one section.

* 25 points: The report is otherwise well-written, but is based on code that simply copies from previous code in the course series without further developing it.

* 30 points: The report includes all required sections and is well-drafted and easy to follow, but with minor flaws in multiple sections.

* 35 points: The report includes all required sections and is easy to follow, but with minor flaws in one section.

* 40 points: The report includes all required sections, is easy to follow with good supporting detail throughout, and is insightful and innovative. 

## Introduction:

an introduction/overview/executive summary section that describes the dataset and summarizes the goal of the project and key steps that were performed

## Methods / Analysis

a methods/analysis section that explains the process and techniques used, including data cleaning, data exploration and visualization, insights gained, and your modeling approach

### Data Cleaning

### Planning / Data Exploration

[This basically all needs to be redone]
* Percentile section is wrong b/c I was looking at a subset of the training set. It's a lot more than 5.

* both Charts need to be redone with the full dataset




I originally intended to develop a taste profile for each user's genre preferences, predicting their ratings by looking at how similarly a movie aligned with those preferences, as well as the rating of that movie by other users with similar tastes. This most closely approximates how I would approach this problem in everyday life - if a friend asked me for movie recommendations, I might suggest to them movies similar to ones I know they like, or I might refer them to another friend who I know has similar interests in movies.

<br>
<br>

I did some initial exploration to see if I actually had enough movie ratings per user in order to do this. I created a `ratings_count` column which associated each unique userId with the number of movies that they rated, and I wrote the `get_ratings_count_percentile` function to calculate, given N ratings, what percentile of users had recorded that many ratings or fewer.

<br>
<br>

Using `get_ratings_count_percentile`, I found that more than half of the users in the training set have fewer than 2 ratings, and less than 20% have more than 5. This I meant could not follow my original plan - with the vast majority of users having fewer than 5 ratings, I would have a very hard time determining their preferences with such a small sample.

<div align="center">

| Ratings Count    | Percentile |
| :-: | :-: |
| 1  | 35.55505    |
| 2 | 56.60346     |
| 3    | 68.94254    |
| 4    | 76.73673    |
| 5    | 81.96849    |

</div>

Conversely, the most prolific users had a disproportionately large number of ratings. One user in the training set had rated over 6500 movies.

<div align = "center">

|userId | count | avg_rating |
|:-: | :-: | :-: |
|57960 | 59269 | 6616 |  3.264586 |

</div>

 Whatever approach I took, I would need to take care not to force the preferences of the more actve users onto the more infrequent ones. I decided to shift my focus away from the users and examine the movies themselves.

[Is it worth talking about the pareto distribution here? Do you know enough about it? It does seem to follow the same natural law but idk too much about it mathematically]

[Movie-genre effects for low count users]
[Preference / Movie genre alignment for higher count users]

[Genre specific predictions]

I started with the genres. Similar to what I saw with users, certain movie genres had a much higher number of ratings, and others very few. However the skew was not nearly as dramatic, so I continued in this direction.

<br>

<img src="/movielens/graphs/genre_counts_barplot.png" align="left" alt="Genre Counts"
	title="Genre Counts"/>

<br>

Many movies have more than one genre associated with it, and I wanted to see if there was a tendency for certain genres to belong to the same movie. The co-occurrence heatmap below shows that this is indeed the case

<br>

 <img src="/movielens/graphs/genre_co_occurrence_heatmap_sqrt_transform.png" align="left" alt="Genre Co-Occurrence"
	title="Genre Co-Occurrence"/>

 <br>

 [RMSEs for Simple Algorithms]
 [Using subset_p = 0.02]
 | Algorithm    | RMSE |
 | :-: | :-: |
| Random Guess | 2.138071    |
| All Rating Avg | 1.062161 |
| User Avg | 0.8764618     |
| Movie Avg    | 0.9283148 |
| Simple Genre Avg | 1.048989 |
| User / Movie Ensemble    | 0.0    |

[Genre Avg in Depth]
[
- Basic model is that the observed rating is a Linear combination of genre averages
- Advanced model should Boost or decrement weightings, based on heat map's indication that certain genres go together. Eg. If Horror and Romance are not frequently co-occurring, and this is a horror movie, then we should decrease the weight of romance movie averages. Do this for all the genres that a movie has, vs. all the other genres.
- Split boosting / decrementing effects among each genre that the movie is tagged with. Start with even splits; you can play around with tweaking the splits to give more weight to certain genres if you have time
]

[ User / Movie ensemble in depth]
[
- User / movie ensemble parameters: Effect weighting, Rating count cutoff
- Keeping weighting constant, is there a rating count at which we start to see improvements over the movie avg?
-  If yes, then worth exploring user effects more in detail (eg. write the algorithm which looks at their genre averages, but only ensemble it if there are more than N ratings by that user)
]

 [movieId averages]
 [userId averages (ignore for majority of users who have low rating counts)]

 [Changes in ratings over time]
 
 [Can ignore sentivity / specificity I think, because we're not predicting binary output?]

[There's some movies with very high/low average ratings because they don't have very many ratings to start with. There's a class section on why this happens]

[popularity seems to be correlated with rating. pretty sure there's a section talking about this too]

### Tuneable Parameters:

Ignore Low Activity Users (bottom n, bottom percentile)

Ignore Low Activity Movies (bottom n, bottom percentile)

Effect strength weighting

## Results

a results section that presents the modeling results and discusses the model performance

## Conclusion

a conclusion section that gives a brief summary of the report, its limitations and future work

## References
Movielens Dataset:
https://grouplens.org/datasets/movielens/10m/
