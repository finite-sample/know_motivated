## Author: Kabir Khanna
## Updated: February 9, 2017

## Calculate standard error of proportion
se.prop <- function(p, n) {
  sqrt(p * (1 - p) / n)
}

## Calculate standard error of difference
se.diff <- function(se1, se2) {
  sqrt(se1 ^ 2 + se2 ^ 2)
}

## Sample characteristics
sample.char <- function(df) {
  print(paste("Democrats", round(sum(table(df$pid7)[1:3]) / sum(table(df$pid7)), 2)))
  print(paste("Republican", round(sum(table(df$pid7)[5:7]) / sum(table(df$pid7)), 2)))
  print(paste("Liberal", round(sum(table(df$ideo5)[1:2]) / sum(table(df$ideo5)), 2)))
  print(paste("Conservative", round(sum(table(df$ideo5)[4:5]) / sum(table(df$ideo5)), 2)))
  print(round(table(df$edu) / sum(table(df$edu)), 2))
  print(round(table(df$agecat) / sum(table(df$agecat)), 2))
  print(paste("Female", round(table(df$fem)["1"] / sum(table(df$fem)), 2)))
  print(round(table(df$raceeth)[1:4] / sum(table(df$raceeth)), 2))
  print(paste("Other/Mixed", round(sum(table(df$raceeth)[5:6]) / sum(table(df$raceeth)), 2)))
}

## Calculate incentive effect
acc.eff <- function(df) {
  mean0 <- mean(df[df$acc == 0, ]$cvd, na.rm = T)
  mean1 <- mean(df[df$acc == 1, ]$cvd, na.rm = T)
  
  n0 <- nrow(df[df$acc == 0 & !is.na(df$cvd), ])
  n1 <- nrow(df[df$acc == 1 & !is.na(df$cvd), ])
  
  se.diff <- sqrt(mean0 * (1 - mean0) / n0 + mean1 * (1 - mean1) / n1)
  
  print(paste("Incentive Effect:", round((mean1 - mean0) * 100, 1)))
  print(paste("Standard Error:", round(se.diff * 100, 1)))
  print(paste("n =", n0 + n1))
}

## Calculate "response bias" (i.e., odds of choosing congenial answer)
resp.bias <- function(df) {
  if (length(table(df$guncong)) == 1) {
    resp <- c(table(df$cvd))
    bias <- ifelse(as.numeric(names(table(df$guncong))) == 0, resp[1] / resp[2], resp[2] / resp[1])
    return(bias)
  }
  if (length(table(df$guncong)) == 2) {
    resp <- c(table(df$guncong, df$cvd))
    bias <- (resp[1] + resp[4]) / (resp[2] + resp[3])
    return(bias)
  }
}
