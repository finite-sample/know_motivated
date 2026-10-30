## Author: Kabir Khanna
## Updated: February 23, 2017

## Figure SI 1: Flow Diagram of Concealed Carry Experiment in Study 1

load("Study1.RData")

nrow(df1) # respondents invited to participate and randomized into experiment
c(table(1 - df1$antigun, df1$acc)) # respondents allocated into each condition

## Analysis
c(table(1 - df1[!is.na(df1$guncong), ]$antigun, df1[!is.na(df1$guncong), ]$acc)) # high-numeracy respondents indicating position on concealed carry
c(table(1 - df1[df1$ban == 1, ]$antigun, df1[df1$ban == 1, ]$acc)) # high-numeracy gun opposers
c(table(1 - df1[df1$ban == 0, ]$antigun, df1[df1$ban == 0, ]$acc)) # high-numeracy gun supporters
