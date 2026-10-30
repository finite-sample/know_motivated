## Author: Kabir Khanna
## Updated: February 23, 2017

## Figure SI 3: Flow Diagram of Concealed Carry Experiment in Study 3

load("Study3.RData")

nrow(df3) # respondents invited to participate
sum(table(df3$acc)) # respondents randomized into experiment
c(table(df3$acc)) # respondents allocated into each condition
c(table(df3[df3$ban == 1, ]$acc)) # gun opposers
c(table(df3[df3$ban == 0, ]$acc)) # gun supporters
