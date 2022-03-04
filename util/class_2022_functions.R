#' A function to multiply two numbers
#'
#' @description 
#' This function will multiply the input values of X and Y
#' 
#' @param x @param y number you'd like to multiply
#' y the other number you'd like to multiply
fun <- function(x, y) {
  ans <- x * y
  return(ans)
}



#' import peak .bed files as a list 
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