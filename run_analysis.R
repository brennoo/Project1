###
# Phase 1 - setup
###

# 1.1 required libraries
require("data.table")
require("reshape2")

# 1.2 set working directory
setwd("C:/Users/brenno.oliveira/Documents/GitHub/Project1/")
home <- getwd()

###
# Phase 2 - get data
###


# 2.1 download dataset

url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip "
file <- "Dataset.zip"

download.file(url, file, mode='wb')

# 2.2 extract dataset
unzip(file, exdir = home)

# 2.3 set dataset files path
path <- file.path(home, "UCI HAR Dataset")

###
# Phase 3 - load data
###

# 3.1 load subject files
dtSubTrain <- fread(file.path(path, "train", "subject_train.txt"))
dtSubTest  <- fread(file.path(path, "test" , "subject_test.txt" ))

# 3.2 load activity files
dtActTrain <- fread(file.path(path, "train", "Y_train.txt"))
dtActTest  <- fread(file.path(path, "test" , "Y_test.txt" ))

# 3.3 read data files


df <- read.table(file.path(path, "train", "X_train.txt"))
dtTrain <- data.table(df)
rm(df)

df <- read.table(file.path(path, "test" , "X_test.txt" ))
dtTest  <- data.table(df)
rm(df)
# had to change it due to erros with fread



###
## Phase 4 - merge data (#1 Merges the training and the test sets to create one data set.)
###

# 4.1 concatenate data.tables

dtSubject <- rbind(dtSubTrain, dtSubTest)
setnames(dtSubject, "V1", "subject")

dtActivity <- rbind(dtActTrain, dtActTest)
setnames(dtActivity, "V1", "activityNum")

dt <- rbind(dtTrain, dtTest)

# 4.2 merge columns

dtSubject <- cbind(dtSubject, dtActivity)
dt <- cbind(dtSubject, dt)

# 4.3 set the key
setkey(dt, subject, activityNum)

###
## Phase 5 - subset data (#2 Extracts only the measurements on the mean and standard deviation for each measurement. )
###

# 5.1 read features.txt - to know which variables are for the mean and standard deviation.

dtFeatures <- fread(file.path(path, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))

# 5.2 Subset only measurements for the mean and standard deviation

dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]

# 5.3 Convert the column numbers to a vector of variable names matching columns in dt.

dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
head(dtFeatures)
dtFeatures$featureCode

# 5.4 Subset these variables using variable names.

select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with=FALSE]

###
## Phase 6 - Name the variables (#3 Uses descriptive activity names to name the activities in the data set)
###


# 6.1 use descriptive activity names from activity_labels.txt

dtActivityNames <- fread(file.path(path, "activity_labels.txt"))
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))

# 6.2 merge activity labels
dt <- merge(dt, dtActivityNames, by="activityNum", all.x=TRUE)

# 6.3 set the key
setkey(dt, subject, activityNum, activityName)


# 6.4 reshape the data table (from short/wide to tall/narrow)
dt <- data.table(melt(dt, key(dt), variable.name="featureCode"))

# 6.5 merge activity name
dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)

# 6.6 duplicate variables

dt$activity <- factor(dt$activityName)
dt$feature <- factor(dt$featureName)


# 6.7 split features column accordinly

# grep features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepl("^t", dt$feature), grepl("^f", dt$feature)), ncol=nrow(y))
dt$featDomain <- factor(x %*% y, labels=c("Time", "Freq"))
x <- matrix(c(grepl("Acc",dt$feature), grepl("Gyro", dt$feature)), ncol=nrow(y))
dt$featInstrument <- factor(x %*% y, labels=c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepl("BodyAcc", dt$feature), grepl("GravityAcc", dt$feature)), ncol=nrow(y))
dt$featAcceleration <- factor(x %*% y, labels=c(NA, "Body", "Gravity"))
x <- matrix(c(grepl("mean()", dt$feature), grepl("std()", dt$feature)), ncol=nrow(y))
dt$featVariable <- factor(x %*% y, labels=c("Mean", "SD"))

# grep featyres with 1 category
dt$featJerk <- factor(grepl("Jerk", dt$feature), labels=c(NA, "Jerk"))
dt$featMagnitude <- factor(grepl("Mag",dt$feature), labels=c(NA, "Magnitude"))

# grep features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepl("-X",dt$feature), grepl("-Y",dt$feature), grepl("-Z",dt$feature)), ncol=nrow(y))
dt$featAxis <- factor(x %*% y, labels=c(NA, "X", "Y", "Z"))

###
## Phase 7 - write a tidy dataset (#5  creates a second, independent tidy data set with the average of each variable for each activity and each subject)
###

setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by=key(dt)]
write.table(dtTidy, file = "GeneratedDataset.txt", row.name=FALSE, sep="\t")
