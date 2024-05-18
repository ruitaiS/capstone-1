# Load necessary library if not already loaded
library(dplyr)

# Fit linear regression model
fit <- lm(rating ~ timestamp, data = train_df)

# Print the summary of the model
summary(fit)
  
  library(caret)
p_hat <- predict(fit, newdata = mnist_27$test)
y_hat <- factor(ifelse(p_hat > 0.5, 7, 2))
confusionMatrix(y_hat, mnist_27$test$y)$overall[["Accuracy"]]