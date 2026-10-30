## Author: Kabir Khanna
## Updated: February 8, 2017

## Figure 5: Congeniality Effect on Study Ratings (Studies 1 & 2)

source("functions.R")
load("Study1.RData")
load("Study2.RData")

## Pool studies
pool.vars <- c("study", "respid", "pid7", "ideo5", "numeracy", "ban", "guncong", "acc", "cvd", "well", "conv")
df <- rbind(df1[pool.vars], df2[df2$numeracy >= 4, pool.vars])

## Average study rating variables into single scale
df$rating <- (df$conv + df$well) / 2

## Number of respondents by condition
N.sup <- c(table(df[!is.na(df$rating) & df$ban == 0, ]$guncong), c(table(df[!is.na(df$rating) & df$ban == 0, ]$guncong, df[!is.na(df$rating) & df$ban == 0, ]$acc)))
N.opp <- c(table(df[!is.na(df$rating) & df$ban == 1, ]$guncong), c(table(df[!is.na(df$rating) & df$ban == 1, ]$guncong, df[!is.na(df$rating) & df$ban == 1, ]$acc)))

## Calculate average rating and standard error by condition
rat.sup <- rat.opp <- se.sup <- se.opp <- rep(NA, 6)
for (i in 1:2) {
  rat.sup[i] <- mean(df[df$guncong == c(0, 1)[i] & df$ban == 0, ]$rating, na.rm = T)
  rat.opp[i] <- mean(df[df$guncong == c(0, 1)[i] & df$ban == 1, ]$rating, na.rm = T)
  se.sup[i] <- sd(df[df$guncong == c(0, 1)[i] & df$ban == 0, ]$rating, na.rm = T) / sqrt(N.sup[i])
  se.opp[i] <- sd(df[df$guncong == c(0, 1)[i] & df$ban == 1, ]$rating, na.rm = T) / sqrt(N.opp[i])
}
for (i in 1:4) {
  rat.sup[i + 2] <- mean(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1)[i] & df$ban == 0, ]$rating, na.rm = T)
  rat.opp[i + 2] <- mean(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1)[i] & df$ban == 1, ]$rating, na.rm = T)
  se.sup[i + 2] <- sd(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1) & df$ban == 0, ]$rating, na.rm = T) / sqrt(N.sup[i + 2])
  se.opp[i + 2] <- sd(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1) & df$ban == 1, ]$rating, na.rm = T) / sqrt(N.opp[i + 2])
}

## Calculate treatment effects and standard errors
diff.sup <- c(rat.sup[2] - rat.sup[1], rat.sup[4] - rat.sup[3], rat.sup[6] - rat.sup[5])
diff.opp <- c(rat.opp[2] - rat.opp[1], rat.opp[4] - rat.opp[3], rat.opp[6] - rat.opp[5])
se.diff.sup <- c(se.diff(se.sup[1], se.sup[2]), se.diff(se.sup[3], se.sup[4]), se.diff(se.sup[5], se.sup[6]))
se.diff.opp <- c(se.diff(se.opp[1], se.opp[2]), se.diff(se.opp[3], se.opp[4]), se.diff(se.opp[5], se.opp[6]))

## Plots
par(mai = c(1, 1, .5, .5), mfrow = c(2, 2)) #bottom, left, top, right

plot(1:3, diff.sup, pch = 19, xaxt = "n", xlim = c(.5, 3.5), ylim = c(-2, 2), 
     xlab = "", ylab = "Congeniality Effect", cex.main = .9, 
     main = paste("A) Concealed Carry Supporters (N=", sum(N.sup[1:2]), ")", sep = ""))
axis(1, at = 1:3, padj = 0, lab = c("Overall", "No Incentive", "Incentive"), cex.axis = .9)
abline(h = 0, lty = 2)
for (i in 1:3) {
  lines(c(i, i), c(diff.sup[i] - qnorm(.95) * se.diff.sup[i], diff.sup[i] + qnorm(.95) * se.diff.sup[i]))
  text(i + .1, diff.sup[i], paste(formatC(diff.sup[i], format = "f", digits = 2), "\n(", 
                                  formatC(se.diff.sup[i], format = "f", digits = 2), ")", sep = ""), adj = 0, cex = .8)
}

plot(1:3, diff.opp, pch = 19, xaxt = "n", xlim = c(.5, 3.5), ylim = c(-2, 2), 
     xlab = "", ylab = "Congeniality Effect", cex.main = .9, 
     main = paste("B) Concealed Carry Opponents (N=", sum(N.opp[1:2]), ")", sep = ""))
axis(1, at = 1:3, padj = 0, lab = c("Overall", "No Incentive", "Incentive"), cex.axis = .9)
abline(h = 0, lty = 2)
for (i in 1:3) {
  lines(c(i, i), c(diff.opp[i] - qnorm(.95) * se.diff.opp[i], diff.opp[i] + qnorm(.95) * se.diff.opp[i]))
  text(i + .1, diff.opp[i], paste(formatC(diff.opp[i], format = "f", digits = 2), "\n(", 
                                  formatC(se.diff.opp[i], format = "f", digits = 2), ")", sep = ""), adj = 0, cex = .8)
}
