base="./imaging/demographics/cd/direc.csv"
df <- read.csv(base, header = TRUE)

# Convert columns to date format
date_cols <- c("DOB", "DIAG", "DOI", "FU_DATE")

for (col in date_cols) { 
	df[[col]] <- as.Date(df[[col]], format = "%d/%m/%Y") 
}

# Compute TWSTRS %-change scores
df$SEV_CHANGE <- ((df$PRE_SEV-df$POST_SEV)/df$PRE_SEV)*100
df$DIS_CHANGE <- ((df$PRE_DIS-df$POST_DIS)/df$PRE_DIS)*100

# One patient has 0 pre-operative pain
df$PAIN_CHANGE <- ((df$PRE_PAIN-df$POST_PAIN)/df$PRE_PAIN)*100
df$PAIN_CHANGE[is.infinite(df$PAIN_CHANGE) & df$PAIN_CHANGE < 0] <- NA
mean(df$PAIN_CHANGE, na.rm=TRUE)

# Calculate Age at implantation (in years)
df$AGE_IMP <- as.numeric(difftime(df$DOI, df$DOB, units = "weeks")) / 52.25 

# Calculate Disease duration (in years)
df$DD <- as.numeric(difftime(df$DOI, df$DIAG, units = "weeks")) / 52.25 

# Calculate Age of onset (in years)
df$AGE_ONSET <- as.numeric(difftime(df$DIAG, df$DOB, units = "weeks")) / 52.25 

# Calculate Follow-up duration (in years)
df$FU_DURATION <- as.numeric(difftime(df$FU_DATE, df$DOI, units = "weeks")) / 52.25

# Combine the data for both groups into one data frame with a new grouping column
df_combined <- rbind( data.frame(SEX = df_conv$SEX, Group = "CONV"), data.frame(SEX = df_direc$SEX, Group = "DIREC") )

# Create a contingency table for SEX across the two groups
sex_table <- table(df_combined$SEX, df_combined$Group)

# Perform Fisher's Exact Test on the contingency table
fisher_test <- fisher.test(sex_table) 

# View the results 
print(fisher_test)

# Create seperate data frames
df_conv <- subset(df, DIREC == 1)
df_direc <- subset(df, DIREC == 2)

# Compute TWSTRS %-change scores for conventional
df_conv$SEV_CHANGE <- ((df_conv$PRE_SEV-df_conv$POST_SEV)/df_conv$PRE_SEV)*100
df_conv$DIS_CHANGE <- ((df_conv$PRE_DIS-df_conv$POST_DIS)/df_conv$PRE_DIS)*100
df_conv$PAIN_CHANGE <- ((df_conv$PRE_PAIN-df_conv$POST_PAIN)/df_conv$PRE_PAIN)*100

# Compute TWSTRS %-change scores for directional
df_direc$SEV_CHANGE <- ((df_direc$PRE_SEV-df_direc$POST_SEV)/df_direc$PRE_SEV)*100
df_direc$DIS_CHANGE <- ((df_direc$PRE_DIS-df_direc$POST_DIS)/df_direc$PRE_DIS)*100
# One patient has 0 pre-operative pain
df_direc$PAIN_CHANGE <- ((df_direc$PRE_PAIN-df_direc$POST_PAIN)/df_direc$PRE_PAIN)*100
df_direc$PAIN_CHANGE[is.infinite(df_direc$PAIN_CHANGE) & df_direc$PAIN_CHANGE < 0] <- NA

# Shapiro-Wilk test for normality on each variable
variables <- c("AGE_IMP", "DD", "AGE_ONSET", "FU_DURATION", "HZ_MEAN", "US_MEAN", "AMP_MEAN", "PRE_SEV", "PRE_DIS", "PRE_PAIN")

# Function to check normality and run appropriate test
for (var in variables) { 
	# Print the variable name 
	cat("\nAnalyzing:", var, "\n") 
	# Check normality for both groups using the Shapiro-Wilk test
	shapiro_conv <- shapiro.test(df_conv[[var]])
	shapiro_direc <- shapiro.test(df_direc[[var]])

	# Print normality test results
	cat("Shapiro-Wilk Test for Normality (CONV): p-value =", shapiro_conv$p.value, "\n")
	cat("Shapiro-Wilk Test for Normality (DIREC): p-value =", shapiro_direc$p.value, "\n")

	# If both groups are normally distributed, run a t-test 
	if (shapiro_conv$p.value > 0.05 & shapiro_direc$p.value > 0.05) { 
		cat("Both groups are normally distributed. Running t-test...\n")
		t_test_result <- t.test(df_conv[[var]], df_direc[[var]])
		print(t_test_result)

		# Calculate mean and standard deviation for each group
		mean_conv <- mean(df_conv[[var]], na.rm = TRUE)
		sd_conv <- sd(df_conv[[var]], na.rm = TRUE)
		mean_direc <- mean(df_direc[[var]], na.rm = TRUE)
		sd_direc <- sd(df_direc[[var]], na.rm = TRUE)

		# Print the mean ± SD for both groups
		cat("Group CONV (mean ± sd):", mean_conv, "±", sd_conv, "\n")
		cat("Group DIREC (mean ± sd):", mean_direc, "±", sd_direc, "\n")
	} 
		else { 
		# If either group is not normally distributed, run Mann-Whitney U test
		cat("Data is not normally distributed. Running Mann-Whitney U test...\n")
		wilcox_test_result <- wilcox.test(df_conv[[var]], df_direc[[var]])
		print(wilcox_test_result)

		# Calculate mean and standard deviation for each group
		mean_conv <- mean(df_conv[[var]], na.rm = TRUE)
		sd_conv <- sd(df_conv[[var]], na.rm = TRUE)
		mean_direc <- mean(df_direc[[var]], na.rm = TRUE)
		sd_direc <- sd(df_direc[[var]], na.rm = TRUE)

		# Print the mean ± SD for both groups
		cat("Group CONV (mean ± sd):", mean_conv, "±", sd_conv, "\n")
		cat("Group DIREC (mean ± sd):", mean_direc, "±", sd_direc, "\n")
	} 
}

# Linear models:

# Linear model with interaction between AMP_MEAN and HZ_MEAN
demo_lm <- lm(SEV_CHANGE ~ AGE_IMP + DD + FU_DURATION + SEX, data = df)

# View the model summary
summary(demo_lm)



# HOTELLINGS T-SQUARE 

# Install the HotellingT2Test package if you don't have it
install.packages("HotellingT2Test")

# Load the library
library(HotellingT2Test)

# Example data: (x, y, z) coordinates for directional and conventional DBS
# Replace these with your actual data
directional_dbs <- matrix(c(...), ncol=3)  # 11 rows, 3 columns for x, y, z
conventional_dbs <- matrix(c(...), ncol=3) # 11 rows, 3 columns for x, y, z

# Perform Hotelling's T-squared test
hotelling_result <- hotelling.test(directional_dbs, conventional_dbs)

# View the result
print(hotelling_result)

# Test multivariate normality
# Install the MVN package if you don't have it
install.packages("MVN")

# Load the library
library(MVN)

# Test for multivariate normality (Mardia's test) on directional and conventional groups
mvn_result_dir <- mvn(data = as.data.frame(directional_dbs), mvnTest = "mardia")
mvn_result_con <- mvn(data = as.data.frame(conventional_dbs), mvnTest = "mardia")

# View results
print(mvn_result_dir$multivariateNormality)
print(mvn_result_con$multivariateNormality)

# Function to calculate Hotelling's T-squared statistic
hotelling_t2_stat <- function(X, Y) {
  n1 <- nrow(X)
  n2 <- nrow(Y)
  p <- ncol(X)
  
  mean_X <- colMeans(X)
  mean_Y <- colMeans(Y)
  
  S1 <- cov(X)
  S2 <- cov(Y)
  S_pooled <- ((n1 - 1) * S1 + (n2 - 1) * S2) / (n1 + n2 - 2)
  
  diff_mean <- mean_X - mean_Y
  T2 <- (n1 * n2) / (n1 + n2) * t(diff_mean) %*% solve(S_pooled) %*% diff_mean
  
  return(as.numeric(T2))
}

# Permutation test function
permutation_test <- function(X, Y, num_permutations = 10000) {
  n1 <- nrow(X)
  combined_data <- rbind(X, Y)
  
  # Observed Hotelling's T-squared
  T2_observed <- hotelling_t2_stat(X, Y)
  
  T2_permutations <- numeric(num_permutations)
  
  for (i in 1:num_permutations) {
    perm_indices <- sample(1:nrow(combined_data), n1)
    X_perm <- combined_data[perm_indices, ]
    Y_perm <- combined_data[-perm_indices, ]
    T2_permutations[i] <- hotelling_t2_stat(X_perm, Y_perm)
  }
  
  # Calculate p-value
  p_value <- mean(T2_permutations >= T2_observed)
  
  return(list(T2_observed = T2_observed, p_value = p_value))
}

# Run the permutation test
perm_test_result <- permutation_test(directional_dbs, conventional_dbs)
print(perm_test_result)

# VISULAISATION

# Install the scatterplot3d package if needed
install.packages("scatterplot3d")

# Load the library
library(scatterplot3d)

# Create 3D scatter plot for directional DBS
scatterplot3d(directional_dbs[,1], directional_dbs[,2], directional_dbs[,3], color = "red", main = "Directional DBS")

# Create 3D scatter plot for conventional DBS
scatterplot3d(conventional_dbs[,1], conventional_dbs[,2], conventional_dbs[,3], color = "blue", main = "Conventional DBS")
