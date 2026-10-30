## Author: Kabir Khanna
## Updated: February 8, 2017

## Figure 3: Concealed Carry Task Results (Study 3)

source("functions.R")
load("Study3.RData")

## Number of respondents by condition
N.sup <- c(table(df3[!is.na(df3$cvd) & df3$ban == 0, ]$guncong, df3[!is.na(df3$cvd) & df3$ban == 0, ]$acc))
N.opp <- c(table(df3[!is.na(df3$cvd) & df3$ban == 1, ]$guncong, df3[!is.na(df3$cvd) & df3$ban == 1, ]$acc))

## Calculate percent correct by condition
cvd.sup <- cvd.opp <- rep(NA, 2)
for (i in 1:2) {
  cvd.sup[i] <- mean(df3[df3$acc == c(0, 1)[i] & df3$ban == 0, ]$cvd, na.rm = T) * 100
  cvd.opp[i] <- mean(df3[df3$acc == c(0, 1)[i] & df3$ban == 1, ]$cvd, na.rm = T) * 100
}

## Calculate standard errors
se.sup <- se.prop(cvd.sup / 100, N.sup) * 100
se.opp <- se.prop(cvd.opp / 100, N.opp) * 100

par(mai = c(1, 1, .5, .5), mfrow = c(2,2)) #bottom, left, top, right

plot(1:2, cvd.sup, pch = 19, xaxt = "n", xlim = c(.5, 2.5), ylim = c(10, 60), xlab = "", ylab = "Percent Correct", cex.main = .9, 
     main = paste("A) Concealed Carry Supporters (N=", sum(N.sup), ")", sep = ""))
axis(1, at = 1:2, padj = 0, lab = c("No Incentive", "Incentive"), cex.axis = .9)
lines(c(1, 1), c(cvd.sup[1] - qnorm(.975) * se.sup[1], cvd.sup[1] + qnorm(.975) * se.sup[1]))
lines(c(2, 2), c(cvd.sup[2] - qnorm(.975) * se.sup[2], cvd.sup[2] + qnorm(.975) * se.sup[2]))
text(1, cvd.sup[1] + 10, paste(formatC(cvd.sup[1], format = "f", digits = 1), " (", formatC(se.sup[1], format = "f", digits = 1), ")", sep = ""), adj = .5, cex = .8)
text(2, cvd.sup[2] + 10, paste(formatC(cvd.sup[2], format = "f", digits = 1), " (", formatC(se.sup[2], format = "f", digits = 1), ")", sep = ""), adj = .5, cex = .8)

plot(1:2, cvd.opp, pch = 19, xaxt = "n", xlim = c(.5, 2.5), ylim = c(10, 60), xlab = "", ylab = "Percent Correct", cex.main = .9, 
     main = paste("B) Concealed Carry Opponents (N=", sum(N.opp), ")", sep = ""))
axis(1, at = 1:2, padj = 0, lab = c("No Incentive", "Incentive"), cex.axis = .9)
lines(c(1, 1), c(cvd.opp[1] - qnorm(.975) * se.opp[1], cvd.opp[1] + qnorm(.975) * se.opp[1]))
lines(c(2, 2), c(cvd.opp[2] - qnorm(.975) * se.opp[2], cvd.opp[2] + qnorm(.975) * se.opp[2]))
text(1, cvd.opp[1] + 10, paste(formatC(cvd.opp[1], format = "f", digits = 1), " (", formatC(se.opp[1], format = "f", digits = 1), ")", sep = ""), adj = .5, cex = .8)
text(2, cvd.opp[2] + 10, paste(formatC(cvd.opp[2], format = "f", digits = 1), " (", formatC(se.opp[2], format = "f", digits = 1), ")", sep = ""), adj = .5, cex = .8)
