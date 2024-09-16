# Load necessary libraries
library(dplyr)
library(ggplot2)

# Example Data - Replace with your actual data
# Data format: dataframe with x, y, z coordinates and group labels (e.g., Directional or Conventional)
data <- data.frame(
  x = c(1.5, 1.7, 2.0, 1.9, 1.8, 2.5, 3.0, 2.9, 3.1, 2.8),
  y = c(2.0, 2.1, 2.3, 2.2, 2.1, 3.1, 3.2, 3.0, 3.3, 3.2),
  z = c(1.1, 1.2, 1.3, 1.1, 1.4, 2.0, 2.1, 2.2, 2.3, 2.1),
  group = c("Directional", "Directional", "Directional", "Directional", "Directional", 
            "Conventional", "Conventional", "Conventional", "Conventional", "Conventional")
)

# Function to calculate Euclidean distance between two points in 3D space
euclidean_distance <- function(x1, y1, z1, x2, y2, z2) {
  sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
}

# Step 1: Calculate mean centroid for each group
mean_centroids <- data %>%
  group_by(group) %>%
  summarize(
    mean_x = mean(x),
    mean_y = mean(y),
    mean_z = mean(z)
  )

# Step 2: Calculate Euclidean distance from each centroid to the group's mean centroid
data <- data %>%
  left_join(mean_centroids, by = "group") %>%
  rowwise() %>%
  mutate(distance = euclidean_distance(x, y, z, mean_x, mean_y, mean_z)) %>%
  ungroup()

# Step 3: Bootstrapping - Resample and calculate the mean distance for each group
set.seed(123) # For reproducibility
bootstrap_iterations <- 1000
bootstrap_results <- data %>%
  group_by(group) %>%
  summarize(
    bootstrap_means = list(
      replicate(bootstrap_iterations, {
        sample_indices <- sample(n(), replace = TRUE)
        mean_distance <- mean(distance[sample_indices])
        return(mean_distance)
      })
    )
  )

# Step 4: Convert the bootstrap results into a long format for easier analysis
bootstrap_df <- bootstrap_results %>%
  unnest(cols = bootstrap_means) %>%
  group_by(group)

# Step 5: Plot the bootstrapped distributions for each group
ggplot(bootstrap_df, aes(x = bootstrap_means, fill = group)) +
  geom_density(alpha = 0.5) +
  labs(title = "Bootstrapped Distribution of Mean Distances",
       x = "Bootstrapped Mean Distance",
       y = "Density") +
  theme_minimal()

# Step 6: Calculate 95% Confidence Intervals from the bootstrap results
bootstrap_ci <- bootstrap_df %>%
  group_by(group) %>%
  summarize(
    lower_ci = quantile(bootstrap_means, 0.025),
    upper_ci = quantile(bootstrap_means, 0.975),
    mean_bootstrap = mean(bootstrap_means)
  )

print(bootstrap_ci)

# Step 7: Compare the bootstrap distributions and perform hypothesis testing (optional)
# You can use a t-test on the bootstrapped means or perform further comparisons

# Example t-test to compare the bootstrapped mean distances between the two groups
t_test_result <- t.test(bootstrap_df$bootstrap_means[bootstrap_df$group == "Directional"],
                        bootstrap_df$bootstrap_means[bootstrap_df$group == "Conventional"])

print(t_test_result)
