## Replication Script for "Motivated Responding in Studies of Factual Learning" by Kabir Khanna and Gaurav Sood
## Author: Kabir Khanna
## Updated: February 23, 2017

## Set working directory
setwd("")

## Load data
load("Study1.RData")
load("Study2.RData")
load("Study3.RData")

source("functions.R")

## Pool concealed carry task in Studies 1 and 2
pool.vars <- c("study", "respid", "pid7", "ideo5", "numeracy", "ban", "guncong", "acc", "cvd", "well", "conv")
df <- rbind(df1[pool.vars], df2[df2$numeracy >= 4, pool.vars])

## Subset high-numeracy respondents in Studies 2 and 3
df2.num <- df2[df2$numeracy >= 4, ]
df3.num <- df3[df3$numeracy >= 4, ]

## Average federal ban and minimum wage positions by study (p. 15)
mean(df1$ban, na.rm = T) #Study 1: oppose ban, i.e., favor concealed carry
mean(df2$ban, na.rm = T) #Study 2: oppose ban, i.e., favor concealed carry
mean(df3$ban, na.rm = T) #Study 3: oppose ban, i.e., favor concealed carry
mean(df2$wage, na.rm = T) #Study 2: favor increasing federal minimum wage
mean(df3$wage, na.rm = T) #Study 3: favor increasing federal minimum wage

## Average p-value of cross condition comparisons by study (p. 16)
pvalues1 <- c(.72, .83, .07, .26, .20, .42); round(sum(pvalues1) / 6, 2) #p-values from Table SI 2, Study 1
pvalues2 <- c(.45, .28, .50, .64, .71, .24); round(sum(pvalues2) / 6, 2) #p-values from Table SI 2, Study 2
pvalues3 <- c(.85, .96, .11, .32, .31, .81); round(sum(pvalues3) / 6, 2) #p-values from Table SI 2, Study 3
round(sum(pvalues1, pvalues2, pvalues3) / 18, 2) #Average p-value across three studies

## Footnote 8 (p. 16)
keep.temp <- c("pid7", "ideo5", "ban")
df.temp <- rbind(df1[keep.temp], df2[keep.temp], df3[keep.temp])
1 - mean(df.temp[df.temp$pid7 <= 3 & df.temp$ideo5 <= 2, ]$ban, na.rm = T) #Democrats who oppose ban
mean(df.temp[df.temp$pid7 >= 5 & df.temp$ideo5 >= 4, ]$ban, na.rm = T) #Republicans who favor ban

## Footnote 11 (p. 20)
table(df2$wage)
1 - mean(df2$wage, na.rm = T)

## Overall minimum wage task performance by study (p. 20)
mean(df2$cvdwage, na.rm = T) #Study 2
mean(df3$cvdwage, na.rm = T) #Study 3

## Study Ratings (pp. 23-24)
library(psy)
cronbach(df[c("well", "conv")]) #Cronbach's Alpha

df$rating <- (df$conv + df$well) / 2 #Average study rating variables into single scale

t.test(rating ~ guncong, data = df[df$ban == 0, ], alternative = "less")
t.test(rating ~ guncong, data = df[df$ban == 0 & df$acc == 0, ], alternative = "less")
t.test(rating ~ guncong, data = df[df$ban == 0 & df$acc == 1, ], alternative = "less")

t.test(rating ~ guncong, data = df[df$ban == 1, ], alternative = "less")
t.test(rating ~ guncong, data = df[df$ban == 1 & df$acc == 0, ], alternative = "less")
t.test(rating ~ guncong, data = df[df$ban == 1 & df$acc == 1, ], alternative = "less")

diff(tapply(df[df$ban == 0 & df$acc == 1 & df$cvd == 1, ]$rating, df[df$ban == 0 & df$acc == 1 & df$cvd == 1, ]$guncong, mean, na.rm = T))
t.test(rating ~ guncong, data = df[df$ban == 0 & df$acc == 1 & df$cvd == 1, ], alternative = "less")

diff(tapply(df[df$ban == 1 & df$acc == 1 & df$cvd == 1, ]$rating, df[df$ban == 1 & df$acc == 1 & df$cvd == 1, ]$guncong, mean, na.rm = T))
t.test(rating ~ guncong, data = df[df$ban == 1 & df$acc == 1 & df$cvd == 1, ], alternative = "less")

## Footnote 13 (p. 23)
tapply(df$rating, df$guncong, mean, na.rm = T) #Congeniality effect (pooled)
t.test(rating ~ guncong, data = df, alternative = "less")

diff(tapply(df[df$acc == 1, ]$rating, df[df$acc == 1, ]$guncong, mean, na.rm = T)) #WITH incentives
t.test(rating ~ guncong, data = df[df$acc == 1, ], alternative = "less")

diff(tapply(df[df$acc == 0, ]$rating, df[df$acc == 0, ]$guncong, mean, na.rm = T)) #WITHOUT incentives
t.test(rating ~ guncong, data = df[df$acc == 0, ], alternative = "less")

## Footnote 16 (p. 26)
round(table(df3[df3$ban == 0 & df3$acc == 0, ]$conf == 5, df3[df3$ban == 0 & df3$acc == 0, ]$cvd) / sum(table(df3[df3$ban == 0 & df3$acc == 0, ]$conf == 5, df3[df3$ban == 0 & df3$acc == 0, ]$cvd)), 2)
round(table(df3[df3$ban == 0 & df3$acc == 1, ]$conf == 5, df3[df3$ban == 0 & df3$acc == 1, ]$cvd) / sum(table(df3[df3$ban == 0 & df3$acc == 1, ]$conf == 5, df3[df3$ban == 0 & df3$acc == 1, ]$cvd)), 2)

## Table SI 1: Sample Characteristics by Study
sample.char(df1)
sample.char(df2)
sample.char(df2[df2$numeracy >= 4, ])
sample.char(df3)
sample.char(df3[df3$numeracy >= 4, ])

## Table SI 2: Covariate Balance across Experimental Conditions in Concealed Carry Task
summary(lm(pid7 ~ guncong + acc + guncong:acc, data = df1))
summary(lm(ideo5 ~ guncong + acc + guncong:acc, data = df1))
summary(lm(as.numeric(edu) ~ guncong + acc + guncong:acc, data = df1))
summary(lm(age ~ guncong + acc + guncong:acc, data = df1))
summary(lm(fem ~ guncong + acc + guncong:acc, data = df1))
summary(lm(as.numeric(raceeth == "White, Non-Hisp") ~ acc, data = df1))

summary(lm(pid7 ~ guncong + acc + guncong:acc, data = df2))
summary(lm(ideo5 ~ guncong + acc + guncong:acc, data = df2))
summary(lm(as.numeric(edu) ~ guncong + acc + guncong:acc, data = df2))
summary(lm(age ~ guncong + acc + guncong:acc, data = df2))
summary(lm(fem ~ guncong + acc + guncong:acc, data = df2))
summary(lm(as.numeric(raceeth == "White, Non-Hisp") ~ acc, data = df2))

summary(lm(pid7 ~ acc, data = df3))
summary(lm(ideo5 ~ acc, data = df3))
summary(lm(as.numeric(edu) ~ acc, data = df3)) #F=2.51 (.11)
summary(lm(age ~ acc, data = df3)) #F=1.004 (.32)
summary(lm(fem ~ acc, data = df3)) #F=1.036 (.31)
summary(lm(as.numeric(raceeth == "White, Non-Hisp") ~ acc, data = df3)) #F=.058 (.81)

## Table SI 3: Logistic Regression of Minimum Wage Task Correctness on Experimental Treatments in Both Tasks
summary(glm(cvdwage ~ 
              guncong + acc + guncong:acc + 
              wagecong + acc2 + wagecong:acc2 + 
              guncong:wagecong + acc:wagecong + guncong:acc:wagecong + 
              guncong:acc2 + acc:acc2 + guncong:acc:acc2 + 
              guncong:wagecong:acc2 + acc:wagecong:acc2 + guncong:acc:wagecong:acc2, family = "binomial", data = df2[df2$wage == 1, ]))
summary(glm(cvdwage ~ acc + wagecong + acc2 + wagecong:acc2 + 
              acc:wagecong + acc:acc2 + acc:wagecong:acc2, family = "binomial", data = df3[df3$wage == 1, ]))
summary(glm(cvdwage ~ acc + wagecong + acc2 + wagecong:acc2 + 
              acc:wagecong + acc:acc2 + acc:wagecong:acc2, family = "binomial", data = df3[df3$wage == 0, ]))

## Table SI 4: Incentive Effects in Concealed Carry Task by Study, Condition, and Respondent Numeracy
acc.eff(df1[!is.na(df1$ban) & df1$guncong == 0 & df1$ban == 0, ])
acc.eff(df1[!is.na(df1$ban) & df1$guncong == 0 & df1$ban == 1, ])
acc.eff(df1[!is.na(df1$ban) & df1$guncong == 1 & df1$ban == 0, ])
acc.eff(df1[!is.na(df1$ban) & df1$guncong == 1 & df1$ban == 1, ])

acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 0 & df2$numeracy >= 4, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 0 & df2$numeracy <= 3, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 0, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 1 & df2$numeracy >= 4, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 1 & df2$numeracy <= 3, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 0 & df2$ban == 1, ])

acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 0 & df2$numeracy >= 4, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 0 & df2$numeracy <= 3, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 0, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 1 & df2$numeracy >= 4, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 1 & df2$numeracy <= 3, ])
acc.eff(df2[!is.na(df2$ban) & df2$guncong == 1 & df2$ban == 1, ])

acc.eff(df3[!is.na(df3$ban) & df3$ban == 0 & df3$numeracy >= 4, ])
acc.eff(df3[!is.na(df3$ban) & df3$ban == 0 & df3$numeracy <= 3, ])
acc.eff(df3[!is.na(df3$ban) & df3$ban == 0, ])
acc.eff(df3[!is.na(df3$ban) & df3$ban == 1 & df3$numeracy >= 4, ])
acc.eff(df3[!is.na(df3$ban) & df3$ban == 1 & df3$numeracy <= 3, ])
acc.eff(df3[!is.na(df3$ban) & df3$ban == 1, ])

## "Response Bias" among Low- and High-Numeracy Respondents (SI Section 2.1)

  ## Study 2, Low Numeracy
  resp.bias(df2[df2$ban == 1 & df2$numeracy <= 3 & df2$acc == 0, ]) #1.25
  resp.bias(df2[df2$ban == 1 & df2$numeracy <= 3 & df2$acc == 1, ]) #1.13

  ## Study 2, High Numeracy
  resp.bias(df2[df2$ban == 1 & df2$numeracy >= 4 & df2$acc == 0, ]) #1.22
  resp.bias(df2[df2$ban == 1 & df2$numeracy >= 4 & df2$acc == 1, ]) #0.82

  ## Study 3, Low Numeracy
  resp.bias(df3[df3$ban == 1 & df3$numeracy <= 3 & df3$acc == 0, ]) #3.68
  resp.bias(df3[df3$ban == 1 & df3$numeracy <= 3 & df3$acc == 1, ]) #2.41

  ## Study 3, High Numeracy
  resp.bias(df3[df3$ban == 1 & df3$numeracy >= 4 & df3$acc == 0, ]) #2.04
  resp.bias(df3[df3$ban == 1 & df3$numeracy >= 4 & df3$acc == 1, ]) #1.68

## SI Section 2.2. Subsetting Respondents by "Ideological Worldview"
df.temp <- df1[c("study", "respid", "pid7", "ideo5", "numeracy", "ban", "banimp", "guncong", "acc", "cvd")]
df.temp$wage <- df.temp$wageimp <- NA
temp.vars <- c("study", "respid", "pid7", "ideo5", "numeracy", "ban", "banimp", "wage", "wageimp", "guncong", "acc", "cvd")
df.temp <- rbind(df.temp, df2[temp.vars], df3[temp.vars])

df.temp$libdem <- NA
df.temp$libdem <- ifelse(df.temp$pid7 >= 5 & df.temp$ideo5 >= 4, 0, df.temp$libdem) #Conservative Republicans
df.temp$libdem <- ifelse(df.temp$pid7 <= 3 & df.temp$ideo5 <= 2, 1, df.temp$libdem) #Liberal Democrats

cor(df.temp[df.temp$study == 2 & df.temp$numeracy >= 4, ]$libdem, df.temp[df.temp$study == 2 & df.temp$numeracy >= 4, ]$ban, use = "pairwise") #.41
cor(df.temp[df.temp$study == 2 & df.temp$numeracy <= 3, ]$libdem, df.temp[df.temp$study == 2 & df.temp$numeracy <= 3, ]$ban, use = "pairwise") #.16

## SI Section 2.3. No Evidence of Selective Perception (including Tables SI 5 and 6)
cell <- paste("rec", c("a", "b", "c", "d"), sep = "_")
for (i in 1:4) {
  print(paste("Cell", toupper(substr(cell[i], 5, 6))))
  print(tapply(df1[df1$acc == 0, cell[i]], df1[df1$acc == 0, ]$guncong, mean, na.rm = T)) #average estimate
  print(tapply(df1[df1$acc == 0, cell[i]], df1[df1$acc == 0, ]$guncong, sd, na.rm = T) /
          sqrt(apply(table(df1[df1$acc == 0, cell[i]], df1[df1$acc == 0, ]$guncong), 2, sum))) #standard error
}
summary(lm(rec_a ~ guncong + acc + guncong:acc, data = df1)) #Table SI 5
summary(lm(rec_c ~ guncong + acc + guncong:acc, data = df1)) #Table SI 6

## Table SI 7: Logistic Regression on Concealed Carry Supporters (Studies 1 & 2)
summary(glm(cvd ~ guncong + acc + guncong:acc, family = "binomial", data = df[df$ban == 0, ]))

## Table SI 8: Logistic Regression on Concealed Carry Opponents (Studies 1 & 2)
summary(glm(cvd ~ guncong + acc + guncong:acc, family = "binomial", data = df[df$ban == 1, ]))

## Assessing Experimenter Demand Effects, including Tables SI 9 and 10

  ## Concealed Carry Opposers
  N.opp <- c(table(df[!is.na(df$cvd) & df$ban == 1, ]$guncong, df[!is.na(df$cvd) & df$ban == 1, ]$acc))

    ## Without Incentives
    tbl.opp.0 <- table(df[df$ban == 1 & df$acc == 0, ]$guncong, df[df$ban == 1 & df$acc == 0, ]$cvd)
    tbl.opp.0[2, ] <- tbl.opp.0[2, 2:1] #reverse order of second row, because correct answer is congenial
    tbl.opp.0 <- tbl.opp.0 / apply(tbl.opp.0, 1, sum)
    tbl.opp.0 <- cbind(round(tbl.opp.0, 3), round(tbl.opp.0[, 1] / tbl.opp.0[, 2], 2))
    
    ## With Incentives
    tbl.opp.1 <- table(df[df$ban == 1 & df$acc == 1, ]$guncong, df[df$ban == 1 & df$acc == 1, ]$cvd)
    tbl.opp.1[2, ] <- tbl.opp.1[2, 2:1] #reverse order of second row, because correct answer is congenial
    tbl.opp.1 <- tbl.opp.1 / apply(tbl.opp.1, 1, sum)
    tbl.opp.1 <- cbind(round(tbl.opp.1, 3), round(tbl.opp.1[, 1] / tbl.opp.1[, 2], 2))
    
    colnames(tbl.opp.0) <- colnames(tbl.opp.1) <- c("anti-gun answer", "pro-gun answer", "odds")
    print(cbind(N.opp, rbind(tbl.opp.0, tbl.opp.1)))

  ## Concealed Carry Supporters
  N.sup <- c(table(df[!is.na(df$cvd) & df$ban == 0, ]$guncong, df[!is.na(df$cvd) & df$ban == 0, ]$acc))

    ## Without Incentives
    tbl.sup.0 <- table(df[df$ban == 0 & df$acc == 0, ]$guncong, df[df$ban == 0 & df$acc == 0, ]$cvd)
    tbl.sup.0[1, ] <- tbl.sup.0[1, 2:1] #reverse order of first row, because incorrect answer is congenial
    tbl.sup.0 <- tbl.sup.0 / apply(tbl.sup.0, 1, sum)
    tbl.sup.0 <- cbind(round(tbl.sup.0, 3), round(tbl.sup.0[, 2] / tbl.sup.0[, 1], 2))
    
    ## With Incentives
    tbl.sup.1 <- table(df[df$ban == 0 & df$acc == 1, ]$guncong, df[df$ban == 0 & df$acc == 1, ]$cvd)
    tbl.sup.1[1, ] <- tbl.sup.1[1, 2:1] #reverse order of first row, because incorrect answer is congenial
    tbl.sup.1 <- tbl.sup.1 / apply(tbl.sup.1, 1, sum)
    tbl.sup.1 <- cbind(round(tbl.sup.1, 3), round(tbl.sup.1[, 2] / tbl.sup.1[, 1], 2))
    
    colnames(tbl.sup.0) <- colnames(tbl.sup.1) <- c("anti-gun answer", "pro-gun answer", "odds")
    print(cbind(N.sup, rbind(tbl.sup.0, tbl.sup.1)))

## SI Section 2.7. How Confident are Respondents in Their Answers?
round(table(df3[df3$acc == 0, ]$conf, df3[df3$acc == 0, ]$cvd) / sum(table(df3[df3$acc == 0, ]$conf, df3[df3$acc == 0, ]$cvd)), 2)
round(table(df3[df3$acc2 == 0, ]$confwage, df3[df3$acc2 == 0, ]$cvdwage) / sum(table(df3[df3$acc2 == 0, ]$confwage, df3[df3$acc2 == 0, ]$cvdwage)), 2)
