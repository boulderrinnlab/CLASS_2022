library(tidyverse)
library(GenomicRanges)
# source("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/util/intersect_functions.R")
source("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/util/class_functions.R")
# run consensus peaks
consensus_peaks <- create_consensus_peaks("/scratch/Shares/rinnclass/CLASS_2022/data/peaks")