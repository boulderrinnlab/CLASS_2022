
library(tidyverse)
source("../../../util/plotting_functions.R")
source("../../../util/intersect_functions.R")
source("../../../util/_setup.R")

# Loading in filtered consensus peaks
fl <- list.files("/scratch/Shares/rinnclass/CLASS_2022/data/filtered_consensus_peaks", 
                 pattern = "*.bed",
                 full.names = TRUE)

# lappy to import each file in file list 
filtered_consensus_peaks <- lapply(fl, rtracklayer::import)


names(filtered_consensus_peaks) <- sapply(filtered_consensus_peaks, function(x){
  unlist(strsplit(x$name, "_"))[[1]]
})

# Loading in all_promoters_gr
# these are the promoter regions for lncRNAs and mRNAs 
#TODO MAKE SURE YOU HAVE RIGHT PATH
all_promoters_gr <- rtracklayer::import("/path/gene_annotation_files/lncRNA_mrna_promoters.gtf")

# setting up promter_df needed in for loop below
metaplot_df <- data.frame(x = integer(), dens = numeric(), dbp = character())

# Writting a for loop to calculate promoter coverage for all DBPs:
for(i in c(1:390, 392:length(filtered_consensus_peaks))) {
  # we skipped 391 as it breaks (only 19 peaks ?)
  print(names(filtered_consensus_peaks)[[i]])
  tmp_df <- profile_tss(filtered_consensus_peaks[[i]], promoters_gr = all_promoters_gr)
  tmp_df$dbp <- names(filtered_consensus_peaks)[[i]]
  metaplot_df <- bind_rows(metaplot_df, tmp_df)
  
}

# write_rds(metaplot_df, "metaplot_df.rds")
# MAKE SURE TO HAVE RIGHT WORKING DIRECTORY !!
write_rds(metaplot_df, "metaplot_df_final.rds")