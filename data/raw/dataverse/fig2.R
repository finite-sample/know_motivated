## Author: Kabir Khanna
## Updated: February 8, 2017

## Figure 2: Concealed Carry Task Results (Studies 1 & 2)

source("functions.R")
load("Study1.RData")
load("Study2.RData")

## Pool studies
pool.vars <- c("study", "respid", "pid7", "ideo5", "numeracy", "ban", "guncong", "acc", "cvd", "well", "conv")
df <- rbind(df1[pool.vars], df2[df2$numeracy >= 4, pool.vars])

## Number of respondents by condition
N.sup <- c(table(df[!is.na(df$cvd) & df$ban == 0, ]$guncong, df[!is.na(df$cvd) & df$ban == 0, ]$acc))
N.opp <- c(table(df[!is.na(df$cvd) & df$ban == 1, ]$guncong, df[!is.na(df$cvd) & df$ban == 1, ]$acc))

## Calculate percent correct by condition
cvd.sup <- cvd.opp <- rep(NA, 4)
for (i in 1:4) {
  cvd.sup[i] <- mean(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1)[i] & df$ban == 0, ]$cvd, na.rm = T) * 100
  cvd.opp[i] <- mean(df[df$guncong == c(0, 1, 0, 1)[i] & df$acc == c(0, 0, 1, 1)[i] & df$ban == 1, ]$cvd, na.rm = T) * 100
}

## Calculate standard errors
se.sup <- se.prop(cvd.sup / 100, N.sup) * 100
se.opp <- se.prop(cvd.opp / 100, N.opp) * 100

## Calculate treatment effects and standard errors
diff.sup <- c(cvd.sup[2] - cvd.sup[1], cvd.sup[4] - cvd.sup[3])
diff.opp <- c(cvd.opp[2] - cvd.opp[1], cvd.opp[4] - cvd.opp[3])
se.diff.sup <- c(se.diff(se.sup[1], se.sup[2]), se.diff(se.sup[3], se.sup[4]))
se.diff.opp <- c(se.diff(se.opp[1], se.opp[2]), se.diff(se.opp[3], se.opp[4]))

## Calculate DiD and standard error
diff.sup <- c(diff.sup, diff.sup[2] - diff.sup[1])
diff.opp <- c(diff.opp, diff.opp[2] - diff.opp[1])
se.diff.sup <- c(se.diff.sup, se.diff(se.diff.sup[1], se.diff.sup[2]))
se.diff.opp <- c(se.diff.opp, se.diff(se.diff.opp[1], se.diff.opp[2]))

## Plots
par(mai = c(1, 1, .5, .5), mfrow = c(2, 2)) #bottom, left, top, right

## Panel A
plot(1:4, cvd.sup, pch = 19, xaxt = "n", xlim = c(.5, 4.5), ylim = c(20, 80), xlab = "", ylab = "Percent Correct", cex.main = .9, 
     main = paste("A) Percent Answering Correctly:\nConcealed Carry Supporters (N=", sum(N.sup), ")", sep = ""))
axis(1, at = 1:4, labels = rep("", 4))
abline(v = 2.5)
text(1.4, 80, "No Incentives", cex = .9)
text(3.6, 80, "Incentives", cex = .9)
text(1:4 - .5, par("usr")[3] - 8, labels = c("Uncongenial", "Congenial", "Uncongenial", "Congenial"), srt = 45, pos = 1, xpd = TRUE, cex = .9)
for (i in 1:4) {
  lines(c(i, i), c(cvd.sup[i] - qnorm(.975) * se.sup[i], cvd.sup[i] + qnorm(.975) * se.sup[i]))
  text(i + .1, cvd.sup[i], paste(formatC(cvd.sup[i], format = "f", digits = 1), "\n(", 
                                 formatC(se.sup[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}

## Panel B
plot(1:3, diff.sup, pch = 19, xaxt = "n", xlim = c(.5, 3.5), ylim = c(-50, 50), xlab = "", ylab = "Percentage-Point Difference", cex.main = .9, 
     main = paste("B) Congeniality Effects and DiD:\nConcealed Carry Supporters (N=", sum(N.sup), ")", sep = ""))
axis(1, at = 1:3, padj = 0, lab = c("No Incentive", "Incentive", "DiD"), cex.axis = .9)
abline(h = 0, lty = 2)
for (i in 1:3) {
  lines(c(i, i), c(diff.sup[i] - qnorm(.975) * se.diff.sup[i], diff.sup[i] + qnorm(.975) * se.diff.sup[i]))
  text(i + .1, diff.sup[i], paste(formatC(diff.sup[i], format = "f", digits = 1), "\n(", 
                                               formatC(se.diff.sup[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}

## Panel C
plot(1:4, cvd.opp, pch = 19, xaxt = "n", xlim = c(.5, 4.5), ylim = c(20, 80), xlab = "", ylab = "Percent Correct", cex.main = .9, 
     main = paste("C) Percent Answering Correctly:\nConcealed Carry Opponents (N=", sum(N.opp), ")", sep = ""))
axis(1, at = 1:4, labels = rep("", 4))
abline(v = 2.5)
text(1.4, 80, "No Incentives", cex = .9)
text(3.6, 80, "Incentives", cex = .9)
text(1:4 - .5, par("usr")[3] - 8, labels = c("Uncongenial", "Congenial", "Uncongenial", "Congenial"), srt = 45, pos = 1, xpd = TRUE, cex = .9)
for (i in 1:4) {
  lines(c(i, i), c(cvd.opp[i] - qnorm(.975) * se.opp[i], cvd.opp[i] + qnorm(.975) * se.opp[i]))
  text(i + .1, cvd.opp[i], paste(formatC(cvd.opp[i], format = "f", digits = 1), "\n(", 
                                           formatC(se.opp[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}

## Panel D
plot(1:3, diff.opp, pch = 19, xaxt = "n", xlim = c(.5, 3.5), ylim = c(-50, 50), xlab = "", ylab = "Percentage-Point Difference", cex.main = .9, 
     main = paste("D) Congeniality Effects and DiD:\nConcealed Carry Opponents (N=", sum(N.opp), ")", sep = ""))
axis(1, at = 1:3, padj = 0, lab = c("No Incentive", "Incentive", "DiD"), cex.axis = .9)
abline(h = 0, lty = 2)
for (i in 1:3) {
  points(i, diff.opp[i], pch = 19)
  lines(c(i, i), c(diff.opp[i] - qnorm(.975) * se.diff.opp[i], diff.opp[i] + qnorm(.975) * se.diff.opp[i]))
  text(i + .1, diff.opp[i], paste(formatC(diff.opp[i], format = "f", digits = 1), "\n(", 
                                  formatC(se.diff.opp[i], format = "f", digits = 1), ")", sep = ""), adj = 0, cex = .8)
}
