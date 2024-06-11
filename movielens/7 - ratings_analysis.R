plot <- ggplot(train_df, aes(x = rating)) +
  geom_histogram(binwidth = 0.5, fill = "lightblue", color = "black") +
  geom_vline(aes(xintercept = mu), color = "red", linetype = "dashed", size = 1) +
  labs(title = "Histogram of Ratings",
       x = "Rating",
       y = "Count") +
  theme_minimal()+
  theme(
    text = element_text(size = unit(2, "mm")),
    plot.title = element_text(size = unit(20, "mm")),
    axis.title = element_text(size = unit(15, "mm")),
    axis.text = element_text(size = unit(10, "mm"))
  )
print(plot)
#store_plot("rating_histogram.png", plot)
rm(plot)