## Author: Kabir Khanna
## Updated: February 8, 2017

## Figure SI 7: Minimum Wage Task Results (Study 2)

source("functions.R")
load("Study2.RData")

## Number of respondents by condition
N.sup <- c(table(df2[!is.na(df2$cvdwage) & df2$wage == 1, ]$wagecong, df2[!is.na(df2$cvdwage) & df2$wage == 1, ]$acc))

## Calculate percent correct by condition
cvd.sup <- rep(NA, 4)
for (i in 1:4) {
  cvd.sup[i] <- mean(df2[df2$wagecong == c(0, 1, 0, 1)[i] & df2$acc2 == c(0, 0, 1, 1)[i] & df2$wage == 1, ]$cvdwage, na.rm = T) * 100
}

## Calculate standard errors
se.sup <- se.prop(cvd.sup / 100, N.sup) * 100

## Calculate treatment effects and standard errors
diff.sup <- c(cvd.sup[2] - cvd.sup[1], cvd.sup[4] - cvd.sup[3])
se.diff.sup <- c(se.diff(se.sup[1], se.sup[2]), se.diff(se.sup[3], se.sup[4]))

## Calculate DiD and standard error
diff.sup <- c(diff.sup, diff.sup[2] - diff.sup[1])
se.diff.sup <- c(se.diff.sup, se.diff(se.diff.sup[1], se.diff.sup[2]))

## Plots
par(mai = c(1, 1, .5, .5), mfrow = c(2, 2)) #bottom, left, top, right

## Panel A
plot(1:4, cvd.sup, pch = 19, xaxt = "n", xlim = c(.5, 4.5), ylim = c(40, 100), xlab = "", ylab = "Percent Correct", cex.main = .9, 
     main = paste("A) Percent Answering Correctly:\nSupport Raising Minimum Wage (N=", format(sum(N.sup), big.mark=","), ")", sep = ""))
axis(1, at = 1:4, labels = rep("", 4))
abline(v = 2.5)
text(1.4, 45, "No Incentives", cex = .9)
text(3.6, 45, "Incentives", cex = .9)
text(1:4 - .5, par("usr")[3] - 8, labels = c("Uncongenial", "Congenial", "Uncongenial", "Congenial"), srt = 45, pos = 1, xpd = TRUE, cex = .9)
for (i in 1:4) {
  lines(c(i, i), c(cvd.sup[i] - qnorm(.975) * se.sup[i], cvd.sup[i] + qnorm(.975) * se.sup[i]))
  text(i + .1, cvd.sup[i], paste(formatC(cvd.sup[i], format = "f", digits = 1), "\n(", 
                                           formatC(se.sup[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}

## Panel B
plot(1:3, diff.sup, pch = 19, xaxt = "n", xlim = c(.5, 3.5), ylim = c(-40, 40), xlab = "", ylab = "Percentage-Point Difference", cex.main = .9, 
     main = paste("B) Congeniality Effects and DiD:\nSupport Raising Minimum Wage (N=", format(sum(N.sup), big.mark=","), ")", sep = ""))
axis(1, at = 1:3, padj = 0, lab = c("No Incentive", "Incentive", "DiD"), cex.axis = .9)
abline(h = 0, lty = 2)
for (i in 1:3) {
  points(i, diff.sup[i], pch = 19)
  lines(c(i, i), c(diff.sup[i] - qnorm(.975) * se.diff.sup[i], diff.sup[i] + qnorm(.975) * se.diff.sup[i]))
  text(i + .1, diff.sup[i], paste(formatC(diff.sup[i], format = "f", digits = 1), "\n(", 
                                  formatC(se.diff.sup[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}
