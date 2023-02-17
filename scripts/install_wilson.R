
if (!require(devtools)) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require(wilson)) devtools::install_github(repo = "loosolab/wilson", host="github.molgen.mpg.de/api/v3", auth_token = NULL, dependencies=FALSE)
library(wilson)
