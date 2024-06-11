plot <- ggplot(movies, aes(x = year, y = avg_rating)) +
  geom_point() +
  labs(title = "Average Movie Rating By Release Year",
       x = "Release Year",
       y = "Average Movie Rating") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("movie_rating_by_release_year.png", plot)

# Cleanup
rm(movieIds, movieId_groups, create_scatterplots, scatterplots_list)