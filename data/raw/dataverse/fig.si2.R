## Author: Kabir Khanna
## Updated: February 23, 2017

## Figure SI 2: Flow Diagram of Concealed Carry Experiment in Study 2

load("Study2.RData")
df2.num <- df2[df2$numeracy >= 4, ] #subset high-numeracy respondents

nrow(df2) # respondents invited to participate
c(table(1 - df2$antigun, df2$acc)) # respondents allocated into each condition
c(table(1 - df2.num$antigun, df2.num$acc)) # high-numeracy respondents allocated into each condition
c(table(1 - df2[df2$numeracy < 4, ]$antigun, df2[df2$numeracy < 4, ]$acc)) # low-numeracy respondents allocated into each condition

## Analysis
c(table(1 - df2.num[!is.na(df2.num$guncong), ]$antigun, df2.num[!is.na(df2.num$guncong), ]$acc)) # high-numeracy respondents indicating position on concealed carry
c(table(1 - df2.num[df2.num$ban == 1, ]$antigun, df2.num[df2.num$ban == 1, ]$acc)) # high-numeracy gun opposers
c(table(1 - df2.num[df2.num$ban == 0, ]$antigun, df2.num[df2.num$ban == 0, ]$acc)) # high-numeracy gun supporters
