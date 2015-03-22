Get and Cleaning data - Project 1
============
Last updated 2015-03-22 12:45:50 using R version 3.1.0 (2014-04-10).


Instructions for project
------------------------

> The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 
- 1) a tidy data set as described below
- 2) a link to a Github repository with your script for performing the analysis
- 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md
You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  
> 
> One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 
> 
> http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 
> 
> Here are the data for the project: 
> 
> https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
> 
> You should create one R script called run_analysis.R that does the following. 
> 
> 1. Merges the training and the test sets to create one data set.
> 2. Extracts only the measurements on the mean and standard deviation for each measurement.
> 3. Uses descriptive activity names to name the activities in the data set.
> 4. Appropriately labels the data set with descriptive activity names.
> 5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
> 
> Good luck!


Setup
-------------

Required packages


```r
require("data.table")
require("reshape2")
```

Set and store working directory


```r
setwd("C:/Users/brenno.oliveira/Documents/GitHub/Project1/")
home <- getwd()
```


Get data
------------

Download dataset


```r
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip "
file <- "Dataset.zip"
download.file(url, file, mode='wb')
```

Extract dataset


```r
unzip(file, exdir = home)
```

Set dataset files path


```r
path <- file.path(home, "UCI HAR Dataset")
```

**See the `README.txt` file in C:/Users/brenno.oliveira/Documents/GitHub/Project1/UCI HAR Dataset for detailed information on the dataset.**


Load data
--------------

Load subject files.


```r
dtSubTrain <- fread(file.path(path, "train", "subject_train.txt"))
dtSubTest  <- fread(file.path(path, "test" , "subject_test.txt" ))
```

Load activity files


```r
dtActTrain <- fread(file.path(path, "train", "Y_train.txt"))
dtActTest  <- fread(file.path(path, "test" , "Y_test.txt" ))
```

Load data files (had to change it slightly to avoid fread errors)


```r
df <- read.table(file.path(path, "train", "X_train.txt"))
dtTrain <- data.table(df)
rm(df)
df <- read.table(file.path(path, "test" , "X_test.txt" ))
dtTest  <- data.table(df)
rm(df)
```


Merge data
------------------------------------
#1 Merges the training and the test sets to create one data set

Concatenate data.tables


```r
dtSubject <- rbind(dtSubTrain, dtSubTest)
setnames(dtSubject, "V1", "subject")
dtActivity <- rbind(dtActTrain, dtActTest)
setnames(dtActivity, "V1", "activityNum")
dt <- rbind(dtTrain, dtTest)
```

Merge columns


```r
dtSubject <- cbind(dtSubject, dtActivity)
dt <- cbind(dtSubject, dt)
```

Set the key


```r
setkey(dt, subject, activityNum)
```


subset data
--------------------------------------------
#2 Extracts only the measurements on the mean and standard deviation for each measurement.

read `features.txt` - to know which variables are for the mean and standard deviation.

```r
dtFeatures <- fread(file.path(path, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
```

Subset only measurements for the mean and standard deviation.


```r
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]
```

Convert the column numbers to a vector of variable names matching columns in `dt`.


```r
dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
head(dtFeatures)
```

```
##    featureNum       featureName featureCode
## 1:          1 tBodyAcc-mean()-X          V1
## 2:          2 tBodyAcc-mean()-Y          V2
## 3:          3 tBodyAcc-mean()-Z          V3
## 4:          4  tBodyAcc-std()-X          V4
## 5:          5  tBodyAcc-std()-Y          V5
## 6:          6  tBodyAcc-std()-Z          V6
```

```r
dtFeatures$featureCode
```

```
##  [1] "V1"   "V2"   "V3"   "V4"   "V5"   "V6"   "V41"  "V42"  "V43"  "V44" 
## [11] "V45"  "V46"  "V81"  "V82"  "V83"  "V84"  "V85"  "V86"  "V121" "V122"
## [21] "V123" "V124" "V125" "V126" "V161" "V162" "V163" "V164" "V165" "V166"
## [31] "V201" "V202" "V214" "V215" "V227" "V228" "V240" "V241" "V253" "V254"
## [41] "V266" "V267" "V268" "V269" "V270" "V271" "V345" "V346" "V347" "V348"
## [51] "V349" "V350" "V424" "V425" "V426" "V427" "V428" "V429" "V503" "V504"
## [61] "V516" "V517" "V529" "V530" "V542" "V543"
```

Subset these variables using variable names.


```r
select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with=FALSE]
```


Name the variables
------------------------------
#3 Uses descriptive activity names to name the activities in the data set
#4 Appropriately labels the data set with descriptive variable names.

use descriptive activity names from `activity_labels.txt`


```r
dtActivityNames <- fread(file.path(path, "activity_labels.txt"))
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))
```

Merge activity names


```r
dt <- merge(dt, dtActivityNames, by="activityNum", all.x=TRUE)
```

Set the key


```r
setkey(dt, subject, activityNum, activityName)
```

Reshape the data table (from short/wide to tall/narrow).


```r
dt <- data.table(melt(dt, key(dt), variable.name="featureCode"))
```

Merge activity name.



```r
dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)
```

Duplicate variables


```r
dt$activity <- factor(dt$activityName)
dt$feature <- factor(dt$featureName)
```

Split the features column accordingly


```r
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
```


Write a tidy data set
----------------------

#5 Creates a second, independent tidy data set with the average of each variable for each activity and each subject


```r
setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by=key(dt)]
write.table(dtTidy, file = "GeneratedDataset.txt", row.name=FALSE, sep="\t")
```

Generate codebook


```r
knit("geraCodebook.rmd", output="codebook.md", encoding="ISO8859-1", quiet=TRUE)
```

```
## [1] "codebook.md"
```

