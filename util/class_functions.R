#' A function to multiply two numbers
#'
#' @description 
#' This function will multiply the input values of X and Y
#' 
#' @param x one number you'd like to multiply
#' y the other number you'd like to multiply
fun <- function(x, y) {
  ans <- x * y
  return(ans)
}



#' *** import peak .bed files as a list ***
#' 
#' @description 
#' this function will take each peak file and name them by the DBP
#' and return a list of GRanges peaks for each ChiPseq experiment
#' 
#' @param consensus_file_path the path to each peak file
#' 

import_peaks <- function(consensus_file_path = "/scratch/Shares/rinnclass/CLASS_2022/data/peaks") {
  
  # Setting some variables needed in main part of function (same as above -- peak_files & tf_name)
  peak_files <- list.files(consensus_file_path, full.names = T)
  
  # Make an object with each TF name for indexing and merging later
  tf_name <- sapply(peak_files, function(x){
    y <-  str_extract(x, "([^\\/]+$)")
    unlist(strsplit(y, "_"))[[1]]
  })
  
  # Here is the heart of the function that will import each file as GRanges (we can use for overlaps)
  # takes 
  
  peak_list <- c()
  for(i in 1:length(peak_files)) {
    # Import peak files
    peaks <- rtracklayer::import(peak_files[i])
    # Append this GRanges object to the of the list.
    peak_list <- c(peak_list, peaks)
    # Name the list elements by their TF name (we just made above)
    names(peak_list)[length(peak_list)] <- tf_name[i]
  }
  return(peak_list)
}



#' *** Intersect peaks from replicate chip-seq peak files ***
#' 
#' @description 
#' this function will take each peak file and perform 
#' fingOVerlaps to produce all the indicies for overlaps 
#' this is further used in create_consensus_peaks function

#' 
#' @param peak_list which is produced in import_peaks function
#' 

intersect_peaks <- function(peak_list) {

combined_peaks <- peak_list[[1]]
for(i in 2:length(peak_list)) {
  suppressWarnings(pl_ov <- findOverlaps(combined_peaks, peak_list[[i]]))
  pl1 <- combined_peaks[unique(pl_ov@from)]
  pl2 <- peak_list[[i]][unique(pl_ov@to)]
  suppressWarnings(combined_peaks <- GenomicRanges::reduce(union(pl1, pl2)))
  
}
return(combined_peaks)
}



#' *** read peaks function: filter to cannonical chr ***
#' 
#' @description 
#' this function will filter each peak file to only cannonical chr.


#' 
#' @param broad_peak_file which is produced in import_peaks function
#' 

read_peaks <- function(broad_peak_file, filter_to_canonical_chr = TRUE) {
  dat <- read.table(broad_peak_file, sep = "\t")
  if(filter_to_canonical_chr == TRUE) {
    dat <- dat[dat$V1 %in% c(paste0("chr", 1:22), "chrM", "chrX", "chrY"),]
  }
  gr <- GRanges(seqnames = dat$V1,
                ranges = IRanges(start=dat$V2,end=dat$V3))
  return(gr)
}

```