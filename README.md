### Movielens Dataset:
https://grouplens.org/datasets/movielens/10m/

### Vehicle Insurance Dataset:
https://www.kaggle.com/datasets/imtkaggleteam/vehicle-insurance-data

# Movielens Project:

0 points: The report is either not uploaded or contains very minimal information AND/OR the report is not written in English AND/OR the report appears to violate the edX Honor Code.
<br>
10 points: Multiple required sections of the report are missing.
<br>
15 points: The methods/analysis or the results section of the report is missing or missing significant supporting details. Other sections of the report are present.
<br>
20 points: The introduction/overview or the conclusion section of the report is missing, not well-presented or not consistent with the content.
<br>
20 points: The report includes all required sections, but the report is significantly difficult to follow or missing supporting detail in multiple sections.
<br>
25 points: The report includes all required sections, but the report is difficult to follow or missing supporting detail in one section.
<br>
25 points: The report is otherwise well-written, but is based on code that simply copies from previous code in the course series without further developing it.
<br>
30 points: The report includes all required sections and is well-drafted and easy to follow, but with minor flaws in multiple sections.
<br>
35 points: The report includes all required sections and is easy to follow, but with minor flaws in one section.
<br>
40 points: The report includes all required sections, is easy to follow with good supporting detail throughout, and is insightful and innovative. 
<br>

## Introduction:

an introduction/overview/executive summary section that describes the dataset and summarizes the goal of the project and key steps that were performed

## Methods / Analysis

a methods/analysis section that explains the process and techniques used, including data cleaning, data exploration and visualization, insights gained, and your modeling approach

<br>

<img src="/movielens/graphs/genre_counts_barplot.png" align="left" alt="Genre Counts"
	title="Genre Counts"/>

 <img src="/movielens/graphs/genre_co_occurrence_heatmap_sqrt_transform.png" align="left" alt="Genre Co-Occurrence"
	title="Genre Co-Occurrence"/>

 <br>

[Discussion of get_ratings_count_percentile function, how it works, why I started in this direction]

[Is it worth talking about the pareto distribution here? Do you know enough about it? It does seem to follow the same natural law but idk too much about it mathematically]

Using `get_ratings_count_percentile`, I found that more than half of the users in the training set have fewer than 2 ratings, and fewer than 20% have more than 5. This I could not follow my original plan to develop a taste profile for each user's genre preferences and predict their ratings based on the activity of other users with similar tastes. With the vast majority of users having fewer than 5 ratings, creating such a profile would be infeasible.

| Ratings Count    | Percentile |
| -------- | ------- |
| 1  | 35.55505    |
| 2 | 56.60346     |
| 3    | 68.94254    |
| 4    | 76.73673    |
| 4    | 81.96849    |

Conversely, the most prolific users had a disproportionately large number of ratings. Whatever approach I took, I would need to take care not to force the preferences of the more actve users onto the more infrequent ones.

[Movie specific predictions?]

### Tuneable Parameters:

Ignore Low Activity Users (bottom n, bottom percentile)

Ignore Low Activity Movies (bottom n, bottom percentile)

## Results

a results section that presents the modeling results and discusses the model performance

## Conclusion

a conclusion section that gives a brief summary of the report, its limitations and future work


Vehicle Insurance Project:

An introduction/overview/executive summary section that describes the dataset and variables, and summarizes the goal of the project and key steps that were performed.
A methods/analysis section that explains the process and techniques used, including data cleaning, data exploration and visualization, any insights gained, and your modeling approach. At least two different models or algorithms must be used, with at least one being more advanced than linear or logistic regression for prediction problems.
A results section that presents the modeling results and discusses the model performance.
A conclusion section that gives a brief summary of the report, its potential impact, its limitations, and future work.
A references section that lists sources for datasets and/or other resources used, if applicable.

0 points: The report is either not uploaded or contains very minimal information AND/OR the report is not written in English AND/OR the report appears to violate the terms of the edX Honor Code.
5 points: One or more required sections of the report are missing.
10 points: The report includes all required sections, but the report is significantly difficult to follow or missing significant supporting detail in multiple sections.
15 points: The report includes all required sections, but the report has flaws: it is difficult to follow and/or missing supporting detail in one section and/or has minor flaws in multiple sections and/or does not demonstrate mastery of the content.
15 points: The report is otherwise fine, but the project is a variation on the MovieLens project.
20 points: The report includes all required sections and is easy to follow, but with minor flaws in one section.
25 points: The report includes all required sections, is easy to follow with good supporting detail throughout, and is insightful and innovative.

Introduction:

Methods / Analysis:

Results:

Conclusion:

References:
