Genome-wide DNA binding in HEPG2
================
JR
4/17/2022

# Goal:

Here we aim to download all available DNA binding protein (DBP) profiles
in a single cell state (measured by ChIP-seq) . This will allow us to
investigate the binding properties of hundreds of DBPs in the same
cellular context or background. We aim to address several questions: (i)
What are the number of peaks and genome coverage for each DBP? (ii) What
are the binding preferences for promoters, gene-bodies and intergenic
genomic regions? (iii) What are the similarities and differences across
DBPs based on their genome-wide binding profiles genome-wide? (iv) What
properties or preferences do promoters have for binding events. (iv) Are
there reservoir promoters in HepG2 as defined in k562 previously? (v)
How does binding to a promoter affect the transcriptional output of that
promoter?

To address these questions we have curated a set of X,000 ChIPs-eq data
sets comprised of 486 DBPs in HEPG2 cells from the ENCODE consortrium.
We required duplicate ChIP-seq experiments for a given DBP and other
criterion that can be found here :

<https://www.encodeproject.org/report/?type=Experiment&status=released&assay_slims=DNA+binding&biosample_ontology.term_name=HepG2&assay_title=TF+ChIP-seq&biosample_ontology.classification=cell+line&files.read_length=100&files.read_length=76&files.read_length=75&files.read_length=36&assay_title=Control+ChIP-seq&assay_title=Histone+ChIP-seq&files.run_type=single-ended>

## These samples were selected on the following criteria:

1.  “chromatin” interaction data, then DNA binding data, cell line
    HEPG2, “TF-Chip-seq”.
2.  We further selected “TF Chip-seq”, “Control chip-seq” and “Histone
    Chip-seq”.
3.  We selected several read lengths to get the most DNA binding
    proteins (DBPs)
4.  Read lengths: 100, 76, 75, 36
5.  ONLY SINGLE END READS (this eliminates 54 samples)

### Experimental data was downloading by (ENCODE report.tsv):

<https://www.encodeproject.org/report.tsv?type=Experiment&status=released&assay_slims=DNA+binding&biosample_ontology.term_name=HepG2&assay_title=TF+ChIP-seq&biosample_ontology.classification=cell+line&files.read_length=100&files.read_length=76&files.read_length=75&files.read_length=36&assay_title=Control+ChIP-seq&assay_title=Histone+ChIP-seq&files.run_type=single-ended>

### The FASTQ files were downloaded with:

“<https://www.encodeproject.org/metadata/?status=released&assay_slims=DNA+binding&biosample_ontology.term_name=HepG2&assay_title=TF+ChIP-seq&biosample_ontology.classification=cell+line&files.read_length=100&files.read_length=76&files.read_length=75&files.read_length=36&assay_title=Control+ChIP-seq&assay_title=Histone+ChIP-seq&files.run_type=single-ended&type=Experiment>”

MD5sums were checked with all passing (see encode\_file\_info function
to reterive MD5Sum values that are not available from the encode portal
(/util)

### Processing data:

We processed all the read alignments and peak calling using the NF\_CORE
ChIP-seq pipeline: (nfcore/chipseq v1.2.1)

## Next we created consensus peaks that overlap in both replicates

Our strategy was to take peaks in each replicate and find all
overlapping peak windows. We then took the union length of the
overlapping range in each peak window.

``` r
# create_consensus_peaks requires an annotation .GTF file - loading in Gencode v32 annotations.
gencode_gr <- rtracklayer::import("/scratch/Shares/rinnclass/CLASS_2022/data/genomes/gencode.v32.annotation.gtf")

# Creating consensus peaks function to create a .bed file of overlapping peaks in each replicate.
# /util/intersect_functions.R

# TODO run this only on final knit
# create_consensus_peaks <- create_consensus_peaks(broadpeakfilepath = "/scratch/Shares/rinnclass/CLASS_2022/data/test_work/all_peak_files")

# exporting consensus peaks .bed files

# TODO run this only on final knit
# for(i in 1:length(consensus_peaks)) {
#  rtracklayer::export(consensus_peaks[[i]],
#                     paste0("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/11_consensus_peaks/consensus_peaks/",
#                             names(consensus_peaks)[i],
#                             "_consensus_peaks.bed"))
# }
```

# loading in consensus peaks to prevent rerunning create\_consensus\_peaks function

``` r
# Loading in files via listing and rtracklayer import
consensus_fl <- list.files("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/11_consensus_peaks/consensus_peaks", full.names = T)

# importing (takes ~5min)
consensus_peaks <- lapply(consensus_fl, rtracklayer::import)

# cleaning up file names
names(consensus_peaks) <- gsub("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/11_consensus_peaks/consensus_peaks/|_consensus_peaks.bed","", consensus_fl)

# Filtering consensus peaks to those DBPs with at least 250 peaks
num_peaks_threshold <- 250
num_peaks <- sapply(consensus_peaks, length)
filtered_consensus_peaks <- consensus_peaks[num_peaks > num_peaks_threshold]

# Result: these were the DBPs that were filtered out.
filtered_dbps <- consensus_peaks[num_peaks < num_peaks_threshold]
names(filtered_dbps)
```

    ##  [1] "CEBPZ"    "GPBP1L1"  "H3K27me3" "HMGA1"    "IRF3"     "MLLT10"  
    ##  [7] "MYBL2"    "NCOA5"    "RNF219"   "RORA"     "ZBTB3"    "ZFP36"   
    ## [13] "ZFP62"    "ZMAT5"    "ZNF10"    "ZNF17"    "ZNF260"   "ZNF382"  
    ## [19] "ZNF48"    "ZNF484"   "ZNF577"   "ZNF597"   "ZNF7"

``` r
# We have this many remaining DBPs
length(filtered_consensus_peaks)
```

    ## [1] 460

## Now we will determine the peak number and genome coverage for each DBP.

``` r
# Let's start with loading in the number of peaks each DBP has -- using length.
num_peaks_df <- data.frame("dbp" = names(filtered_consensus_peaks),
                           "num_peaks" = sapply(filtered_consensus_peaks, length))

# total genomic coverage of peaks for each dbp
num_peaks_df$total_peak_length <- sapply(filtered_consensus_peaks, function(x) sum(width(x)))

# Plotting distribution of peak number per dbp
hist(num_peaks_df$total_peak_length)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/peak%20number%20and%20coverage%20per%20DBP-1.png)<!-- -->

# Now we will create promoter annotations for lncRNA and mRNA and both.

We have created a funciton get\_promter\_regions that has up and
downstream parameters

``` r
# creating lncRNA and mRNA promoters
lncrna_mrna_promoters <- get_promoter_regions(gencode_gr, biotype = c("lncRNA", "protein_coding", upstream = 1500, downstream = 1500))
names(lncrna_mrna_promoters) <- lncrna_mrna_promoters$gene_id
rtracklayer::export(lncrna_mrna_promoters, "analysis/results/lncRNA_mrna_promoters.gtf")

# creating lncRNAs promoter
lncrna_promoters <- get_promoter_regions(gencode_gr, biotype = "lncRNA", upstream = 1500, downstream = 1500) 
names(lncrna_promoters) <- lncrna_promoters$gene_id
rtracklayer::export(lncrna_promoters, "analysis/results/lncRNA_promoters.gtf")

# creating mRNA promoters
mrna_promoters <- get_promoter_regions(gencode_gr, biotype = "protein_coding", upstream = 1500, downstream = 1500)
names(mrna_promoters) <- mrna_promoters$gene_id
rtracklayer::export(lncrna_promoters, "analysis/results/mRNA_promoters.gtf")

# creating all genebody annotation
lncrna_mrna_genebody <- gencode_gr[gencode_gr$type == "gene" & 
                                     gencode_gr$gene_type %in% c("lncRNA", "protein_coding")]
names(lncrna_mrna_genebody) <- lncrna_mrna_genebody$gene_id
rtracklayer::export(lncrna_mrna_genebody, "analysis/results/lncrna_mrna_genebody.gtf")

# creating lncRNA genebody annotation
lncrna_genebody <- gencode_gr[gencode_gr$type == "gene" & 
                                gencode_gr$gene_type %in% c("lncRNA")]
names(lncrna_genebody) <- lncrna_genebody$gene_id
rtracklayer::export(lncrna_mrna_genebody, "analysis/results/lncrna_genebody.gtf")

# creating mRNA genebody annotation
mrna_genebody <- gencode_gr[gencode_gr$type == "gene" & 
                              gencode_gr$gene_type %in% c("protein_coding")]
names(mrna_genebody) <-mrna_genebody$gene_id
rtracklayer::export(lncrna_mrna_genebody, "analysis/results/mrna_genebody.gtf")
```

# Determining the overlaps of chip peaks with promoters and genebodys

``` r
# creating index to subset lncRNA and mRNA annotations
lncrna_gene_ids <- lncrna_mrna_genebody$gene_id[lncrna_mrna_genebody$gene_type == "lncRNA"]
mrna_gene_ids <- lncrna_mrna_genebody$gene_id[lncrna_mrna_genebody$gene_type == "protein_coding"]

# using count peaks per feature returns number of annotation overlaps for a given DBP (takes ~5min)
promoter_peak_counts <- count_peaks_per_feature(lncrna_mrna_promoters, filtered_consensus_peaks, type = "counts")

# adding data to num_peaks_df
num_peaks_df$peaks_overlapping_promoters <- rowSums(promoter_peak_counts)
num_peaks_df$peaks_overlapping_lncrna_promoters <- rowSums(promoter_peak_counts[,lncrna_gene_ids])
num_peaks_df$peaks_overlapping_mrna_promoters <- rowSums(promoter_peak_counts[,mrna_gene_ids])

# gene body overlaps 
genebody_peak_counts <- count_peaks_per_feature(lncrna_mrna_genebody, 
                                                filtered_consensus_peaks, 
                                                type = "counts")


# adding data to num_peaks_df
num_peaks_df$peaks_overlapping_genebody <- rowSums(genebody_peak_counts)
num_peaks_df$peaks_overlapping_lncrna_genebody <- rowSums(genebody_peak_counts[,lncrna_gene_ids])
num_peaks_df$peaks_overlapping_mrna_genebody <- rowSums(genebody_peak_counts[,mrna_gene_ids])

write_csv(num_peaks_df, "analysis/results/num_peaks_df.csv")
```

# Plotting peak annotation features for DBPs

First we will plot the distribution of the number of peaks per DBP

``` r
num_peaks_df <- read_csv("analysis/results/num_peaks_df.csv")
# Distriubtion of peak numbers of all 460 DBPs
ggplot(num_peaks_df, aes(x = num_peaks)) + 
  geom_histogram(bins = 70)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20peak%20annotation%20features-1.png)<!-- -->

``` r
summary(num_peaks_df$num_peaks)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##     261    5643   15736   21524   32053  144675

The median number of peaks is nearly 16,000, but most DBPs tend to have
many fewer binding events. The distribution looks like an expotential
decay. Surprisingly, one DBP has nearly 150,000 peaks.

# Plotting the total genome coverage of each DBPs ChIP peaks

Here we want to see the relationship between the number of peaks and
amount of genome covered

``` r
# Plotting number of peaks versus total genome coverage
ggplot(num_peaks_df, aes(x = num_peaks, y = total_peak_length)) +
  geom_point() + 
  geom_smooth(method = "gam", se = TRUE, color = "black", lty = 2)+
         
  ylab("BP covered") +
  xlab("Number of peaks") +
  ggtitle("Peak count vs. total bases covered")
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/num%20peaks%20versus%20genome%20coverage-1.png)<!-- -->

``` r
ggsave("analysis/figures/peak_num_vs_coverage.pdf")
```

We observe a somewhat linear relationship between peak number and genome
coverage Thus, more peaks = more genome coverage. This could be
interpreted as the peak sizes are typically uniform and thus linearly
increase genome coverage

# Plotting number of peaks versus overlaps with promoters

Here we are comparing the number of peaks for a given DBP to the total
number of promoters those peaks overlap

``` r
# Plotting number of peaks versus peaks overlapping promoters
ggplot(num_peaks_df,
       aes(x = num_peaks, y = peaks_overlapping_promoters)) +
  xlab("Peaks per DBP") +
  ylab("Number of peaks overlapping promoters") +
  ggtitle("Relationship Between Number of DBP Peaks and Promoter Overlaps")+
  geom_point() +
  geom_abline(slope = 1, linetype="dashed") +
  geom_smooth(method = "lm", se=FALSE, formula = 'y ~ x',
              color = "#a8404c") +
  stat_regline_equation(label.x = 35000, label.y = 18000) +
  ylim(0,60100) +
  xlim(0,60100)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/peak%20number%20versus%20promoter%20overlaps-1.png)<!-- -->

``` r
ggsave("analysis/figures/3_peak_num_vs_promoter_coverage.pdf")
```

There is not a great linear fit across all the data. We observe that
below 20,000 peaks there seems to be a linear relationship however as
the peak number increases fewer promoters are overlapping. This suggests
that after 20,000 peaks most promoters are covered and now the peaks are
elsewhere.

# Peaks per DBP overlaps with genebody

Here we want to see how many of the peaks for each DBP overlap
genebodys.

``` r
# Plotting peak overlaps with genebody
ggplot(num_peaks_df,
       aes(x = num_peaks, y = peaks_overlapping_genebody)) +
  xlab("Peaks per DBP") +
  ylab("Number of peaks overlapping genes") +
  ggtitle("Relationship Between Number of DBP Peaks and Gene Body Overlaps")+
  geom_point() +
  geom_abline(slope = 1, linetype="dashed") +
  geom_smooth(method = "lm", se=F, formula = 'y ~ x',
              color = "#a8404c") +
  stat_regline_equation(label.x = 35000, label.y = 18000) +
  ylim(0,60100) +
  xlim(0,60100)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/peaks%20overlapping%20genebody-1.png)<!-- -->

``` r
ggsave("analysis/figures/4_peak_num_vs_gene_body_coverage.pdf")
```

We observe that there is a very linear relationship between peak number
and genebody overlap. This means that the more peaks you have the more
likely you are to overlap a genebody. One way to think about this is
that genebody overlaps explains most of the peaks – or most peaks
overlap genebodys. We would expect dots (DBPs) that are below the line
are binding outside genebodys.

However, one artifact could be if genebodys take up most of the genome
this would also make a linear trend.

# Determing how much of the genome is comprised of genebodies.

``` r
# there is a large amount of data explained (almost all by genebodys)
# Let's see what percentage of the genome genebodys cover:
reduced_gene_bodies <- gencode_gr[gencode_gr$type == "gene"] %>%
  GenomicRanges::reduce() %>%
  width() %>%
  sum()

# percentage of gene bodies in genome
reduced_gene_bodies/3.2e9
```

    ## [1] 0.589159

So we observe that genebodys do cover a lot of the genome. Since they
represent a majority of the genome we would expect a linear
relationship. Nonetheless we conclude that most peaks overlap genebodys.

# Counting the number of overlaps at each promoter

promoters are the cols and DBPs rows thus we can retrieve the number of
binding events at each promoter unlike the “counts parameter” that just
gives total number of overlaps

``` r
# Creating matrix of promoters(annotation feature) as cols and DBPs as rows (takes ~5min)
promoter_peak_occurence <- count_peaks_per_feature(lncrna_mrna_promoters, filtered_consensus_peaks, 
                                               type = "occurrence")

# test to make sure everything is in right order
stopifnot(all(colnames(promoter_peak_occurence) == lncrna_mrna_promoters$gene_id))

# Formatting final data.frame from peak occurence matrix
peak_occurence_df <- data.frame("gene_id" = colnames(promoter_peak_occurence),
                                "gene_name" = lncrna_mrna_promoters$gene_name,
                                "gene_type" = lncrna_mrna_promoters$gene_type,
                                "chr" = lncrna_mrna_promoters@seqnames,   
                                "1.5_kb_up_tss_start" = lncrna_mrna_promoters@ranges@start,
                                "strand" = lncrna_mrna_promoters@strand,
                                "number_of_dbp" = colSums(promoter_peak_occurence))
# exporting
write_csv(peak_occurence_df, "analysis/results/peak_occurence_dataframe.csv")
```

# Plotting

Here we are going to plot the distribution of the number of DBPs on a
given promoter

``` r
ggplot(peak_occurence_df, aes(x = number_of_dbp)) +
geom_density(alpha = 0.2, color = "#424242", fill = "#424242") +
  
  theme_paperwhite() +
  xlab(expression("Number of DBPs")) +
  ylab(expression("Density")) +
  ggtitle("Promoter binding events",
          subtitle = "mRNA and lncRNA genes") 
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/DBPs%20per%20promoter-1.png)<!-- -->

``` r
ggsave("analysis/figures/num_binding_events_per_promoter.pdf")
```

!COOL Result – maybe ! We observe a bimodal distribution of binding at
promoters. This indicates that there are two types of promoters: 1)
Those that have up to 70 or so DBPs bound 2) High binders that have more
than 200 DBPs We note a lag betweent 100-200 DBPs per promoter. This
could indicate that this is not a preferable number of DBPs.

# Multiple promoter window sizes

Let’s iterate over promoter window sizes and see if this effect is
maintained. First we’ll generate promoter windows of multiple

``` r
# Window sizes we want to iterate over.
window_size <- c(10, 30, 50, 100, 500, 1000, 1500, 2000, 2500, 3000)

# To test this function quickly, we'll subset gencode to a sampling of genes
gene_samples <- gencode_gr[gencode_gr$type == "gene"]
gene_samples <- gene_samples[gene_samples$gene_type %in% c("lncRNA", "protein_coding")]
gene_samples <- gene_samples[sample(1:length(gene_samples), 1000)]

promoter_list <- lapply(window_size, function(x) {
  GenomicRanges::promoters(gene_samples, upstream = x, downstream = x)
})
names(promoter_list) <- window_size

peaks_per_feature_list <- lapply(promoter_list, function(x) {
  count_peaks_per_feature(x, filtered_consensus_peaks, type = "occurrence")
})

num_dbp_list <- lapply(peaks_per_feature_list, function(x) {
  colSums(x)
})


for(i in 1:length(window_size)) {
  num_dbp_list[[i]] <- data.frame("gene_id" = names(num_dbp_list[[i]]),
                                  "num_dbp" = num_dbp_list[[i]],
                                  "window_size" = window_size[[i]])
}

num_dbp_df <- bind_rows(num_dbp_list)


ggplot(num_dbp_df, aes(x = num_dbp, color = window_size, group = window_size)) +
geom_density(alpha = 0.2) +
  theme_paperwhite() +
  xlab(expression("Number of DBPs")) +
  ylab(expression("Density")) +
  ggtitle("Promoter binding events",
          subtitle = "mRNA and lncRNA genes") 
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/unnamed-chunk-1-1.png)<!-- -->
Awesome, we see that window size is not affecting the bimodal
distribution. So this is an intersting result that no matter the window
size we find tow populations of promoters: “normal” and high affinity
promoters.

# Binding properties versus total RNA expression.

Let’s take a look at HEPG2 RNAseq downloaded from ENCODE. We will start
by loading in that data and then looking at the distribution of gene
expression and where to filter.

``` r
salmon_tpm <- read.csv("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/18_running_RNAseq_NF_CORE/preclass_NF_core_RUN/results/salmon/salmon_merged_gene_tpm.csv")

samplesheet <- read_rds("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/19_rnaseq/final_samplesheet.rds")

g2s <- read_csv("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/18_running_RNAseq_NF_CORE/g2s.csv") %>%
  dplyr::select(gene_id, gene_name)
```

# Organizing the loaded data into a nice data frame of TPM values.

``` r
# First we will take the mean TPM between replicates for total RNA (Homo_sapiens_hepg2).

tpm <- salmon_tpm %>% 
  pivot_longer(cols = 2:ncol(.), names_to = "sample_id", values_to = "tpm") %>%
  merge(samplesheet) %>%
  group_by(gene_id, condition) %>%
  summarize(tpm = mean(tpm, na.rm = T)) %>%
  filter(condition == "homo_sapiens_hepg2") %>%
  merge(g2s)

# Let's look at how many DBPs have a matching gene symbol in the gene expression dataset.
dbp_names <- tolower(num_peaks_df$dbp)
table(dbp_names %in% tolower(tpm$gene_name))
```

    ## 
    ## FALSE  TRUE 
    ##    14   446

``` r
dbp_names[!(dbp_names %in% tolower(tpm$gene_name))]
```

    ##  [1] "h3k27ac"         "h3k36me3"        "h3k4me1"         "h3k4me2"        
    ##  [5] "h3k4me3"         "h3k9ac"          "h3k9me3"         "h4k20me1"       
    ##  [9] "kiaa2018"        "polr2aphosphos2" "polr2aphosphos5" "zcchc11"        
    ## [13] "znf788"          "zzz3"

``` r
# There are 14 missing. It looks like it's mostly the histone modifactions -- which are not genes.

dbp_expression <- tpm %>% filter(tolower(gene_name) %in% dbp_names) %>%
  mutate(gene_name = tolower(gene_name))

# Final set of DBPs we can use between ENCODE names and TPM names from Salmon
# Making a data frame of DBPs we can use and TPM and overlaps
dbp_expression_vs_peak_number <- dbp_expression %>%
  left_join(num_peaks_df %>% dplyr::rename(gene_name = dbp) %>%
              mutate(gene_name = tolower(gene_name)))
```

# As a first check of the data let’s see how TPM relates to number of peaks

A resonalble hypothesis is that higher abundant proteins may have more
peaks.

``` r
ggplot(dbp_expression_vs_peak_number, aes(x = tpm, y = num_peaks)) +
  geom_point() +
  scale_y_log10() +
  xlim(0,50) +
  geom_smooth()
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20TPM%20versus%20number%20of%20peaks-1.png)<!-- -->
It seems that there’s no correlation between the expression level of the
gene and the number of peaks bound by the resulting protein. This makes
sense due to the fact that mRNA levels and protein levels are only
weakly correlated.

# Loading in peak occurence DF we made above.

This data frame has all our peak info per DBP and we will merge TPM data
and other features. This way we have all the inforamtion we need for
each promoter (rows)

``` r
# Loading in promoter peak occurence DF we made above (as matrix and converted to datframe)
# Around line 330
promoter_features_df <- read.csv("/scratch/Shares/rinnclass/CLASS_2022/JR/CLASS_2022/class_exeRcises/analysis/12_peak_features/peak_occurence_dataframe.csv")

# Merging int TPM values.
promoter_features_df <- promoter_features_df %>%
  left_join(tpm)
```

# Plotting number of DBPs (TFs) bound to a promoter versus expression of that promoter.

``` r
ggplot(promoter_features_df, 
            aes(y = log2(tpm + 0.001), x = number_of_dbp, color = gene_type)) + 
geom_point(data = promoter_features_df %>% filter(tpm < 0.001),
             shape = 17, alpha = 0.7) +
  geom_smooth(method = 'gam', formula = y ~ s(x, bs = "cs")) +
  stat_cor() +
  scale_x_continuous(expand = c(0,0)) +
  scale_color_manual(values = c("#a8404c", "#424242"), name = "Gene type") + 
  ggtitle("Expression vs. promoter binding events") + 
  xlab(expression('Number of DBPs')) +
  ylab(expression(log[2](TPM))) 
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/Plotting%20number%20of%20DBPs%20versus%20expression-1.png)<!-- -->

``` r
ggsave("analysis/figures/binding_versus_expression_all.pdf")
```

We find two patterns of promoter binding versus expression: 1)
Expression is linear with respect to number of binding events This is
similar to what has been published by Mele et al. Genome Research 2)
There is a population of promoters that are NOT expresed across the
range of bound DBPs

# Filtering by expression value.

We saw abov that although there is a linear trend the expression values
are very low at promoters with less than 100 DBPs bound. Somewhere
around TPM of 0.04 which is very low!

Let’s look at the distribution of expression values to determine where
to filter. It seems common to filter as “expressed” if there is at least
one TPM.

# Plotting distribution of TPMS

``` r
ggplot(promoter_features_df, aes(x = tpm)) +
  geom_density() +
  xlim(0,2.5)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/Distribution%20of%20TPMs-1.png)<!-- -->
We see that most genes have very low expression and we see an inflection
point in the density plot at around 0.25 TPM. Therefore, we’ll call any
gene with &gt; 0.25 TPM as expressed.

# Filtering to “expressed genes” &gt; 0.25 TPM

We will add this to promoter\_features\_df.

``` r
# making "expressed" col by filtering > .25
promoter_features_df <- promoter_features_df %>%
  mutate(expressed = tpm > 0.25)
table(promoter_features_df$expressed)
```

    ## 
    ## FALSE  TRUE 
    ## 17162 19550

If we make this cutoff, 19,550 genes are expressed. This is somewhat
typical \~50% of genes.

# Plotting number of expressed and not expressed genes

``` r
ggplot(promoter_features_df %>% filter(!is.na(tpm)), aes(x = expressed)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1)
```

\[\](Genome\_wide\_dna\_binding\_HEPG2\_files/figure-gfm/number of genes
“expressed” &gt; 0.25 TPM-1.png)<!-- -->

# Binding versus expression of “expressed” genes

Let’s look at the relationship between the number of TFs on a promoter
and the expression only for expressed genes.

``` r
ggplot(promoter_features_df %>% filter(expressed == TRUE), 
            aes(y = log2(tpm), x = number_of_dbp, color = gene_type)) + 
  geom_bin_2d() +
  geom_smooth(method = 'gam', formula = y ~ s(x, bs = "cs")) +
  stat_cor()
```

\[\](Genome\_wide\_dna\_binding\_HEPG2\_files/figure-gfm/binding versus
“expressed” genes-1.png)<!-- --> For expressed genes (TPM &gt; 0.25),
there is still a correlation between higher numbers of DBPs on the
promoter and the expression level. This trend carries through even very
high numbers of DBPs (&gt; 200). And more so for mRNAs than lncRNAs.

Suprisingly, there are genes which have no DBPs bound in this dataset,
but are still expressed. What are the gene types of these genes? Are
they transcribed by a different polymerase? Perhaps this highlights the
fact that although we have a large number of DBPs in this dataset, there
are still many other transcription factors not profiled. We have
approximately 1/3 of the total identified human TFs (460/1200).

# Determining Reservoirs

We previously published a phenomena of promoters bound by many DBPs but
Do not follow the linear increase in expression at these promoters. We
will now do this for HEPG2 cells by determining:

Those promtoers with high binding (second mode) and lack expression TPM
&lt; 0.001

``` r
# reservoir defines as:
# greater than 100 DBPs bound at promoter
# less than 0.001 Tpm

promoter_features_df$hepg2_reservoir <- 
  as.numeric(promoter_features_df$number_of_dbp > 100 & 
               promoter_features_df$tpm < 0.001)
```

# merging in k562 reservoir informaiton

``` r
# reading in file defining k562 reservoir 
k562_df <- read_csv("/scratch/Shares/rinnclass/CLASS_2022/data/2020_k562_promoter_peak_df.csv")

# organizing data frame
k562_df <- k562_df %>% 
  dplyr::select(gene_id, reservoir, conservative_reservoir, tpm, expression, tf_binding, promoter_mean_tpm, promoter_median_tpm, promoter_max_tpm) %>%
  dplyr::rename(k562_reservoir = reservoir, 
                k562_conservative_reservoir = conservative_reservoir,
                k562_expression = expression,
                k562_tpm = tpm,
                k562_tf_binding = tf_binding,
                k562_promoter_mean_tpm =  promoter_mean_tpm,
                k562_promoter_median_tpm = promoter_median_tpm,
                k562_promoter_median_tpm = promoter_median_tpm,
                k562_promoter_max_tpm = promoter_max_tpm)

# Hepg2_DF
hepg2_df <- promoter_features_df %>%
  dplyr::select(gene_id, gene_name, tpm, number_of_dbp, hepg2_reservoir) %>%
   dplyr::rename( hepg2_tpm = tpm)

# merging data frames
hepg2_k562_promoter_features_df <- merge(hepg2_df, k562_df)

# summarizing overlaps
res_status <- hepg2_k562_promoter_features_df %>% 
  group_by(hepg2_reservoir, k562_reservoir, k562_conservative_reservoir) %>%
  summarize(count = n())
```

# Defining high binder promoters

``` r
# look at distribution of binding events
summary(promoter_features_df$number_of_dbp)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##     0.0     2.0    46.0   123.7   263.0   427.0

``` r
# based on this deifining > 230 as high, 11-229 as medium and 10 or less as low
promoter_features_df <- promoter_features_df %>%
  mutate(binding_status = ifelse(number_of_dbp > 230, "high",
                                 ifelse(number_of_dbp < 10, "low", "medium")),
         expression_level = ifelse(tpm > 100, "high", ifelse(tpm > 0.25, "medium", "low")))
promoter_features_df$binding_status <- factor(promoter_features_df$binding_status, 
                                              levels = c("low", "medium", "high"))
```

# High, medium and low binding promoters expression level

We will determine those genes that are expressed as &gt; 0.25 TPM per
above. Then plot the binding status of the promoters accordingly.

``` r
ggplot(promoter_features_df %>% filter(!is.na(expressed)), aes(x = binding_status)) +
  geom_bar() +
facet_wrap(~expressed)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/binding%20category%20versus%20expression-1.png)<!-- -->

``` r
# number of expressed in each binding category
table(promoter_features_df$binding_status)
```

    ## 
    ##    low medium   high 
    ##  13831  11477  11506

# Subsecting promoter peak occurence by high and low binding promoters from above.

``` r
# promoters with more than 230 DBPs from peak occurence matrix
high_binding_promoters <- promoter_peak_occurence[,promoter_features_df %>%
                                                    filter(binding_status == "high") %>%
                                                    pull(gene_id)]

# promoters with less than 10 DBPs from peak occurence matrix
low_binding_promoters <- promoter_peak_occurence[,promoter_features_df %>%
                                                    filter(binding_status == "low") %>%
                                                    pull(gene_id)]

# percentage (occupancy) of promoters bound by each DBP
high_binding_occupancy <- rowSums(high_binding_promoters) / ncol(high_binding_promoters)

low_binding_occupancy <- rowSums(low_binding_promoters) / ncol(low_binding_promoters)

# combining into data.frame
binding_occupancy <- data.frame(dbp = names(high_binding_occupancy),
                                high = high_binding_occupancy,
                                low = low_binding_occupancy) %>%
  # ratio of occupancy on high versus low binding promoters
  mutate(high_vs_low_ratio = log2((high + 0.001) / (low + 0.001)))
```

# PLotting density of occupancy of DBPs on high and low binding promoters

``` r
# Density of DBPs occupancy on high binders
ggplot(binding_occupancy, aes(x = high)) +
  geom_density()
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20density%20of%20occupancy%20on%20high%20and%20low%20binding%20promoters-1.png)<!-- -->

``` r
# Density of DBPs occupancy on low binders
ggplot(binding_occupancy, aes(x = low)) +
  geom_density()
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20density%20of%20occupancy%20on%20high%20and%20low%20binding%20promoters-2.png)<!-- -->
We observe that on high binders most proteins that are bound are bound
to 75% or more of high binding promoters. Thus, if a DBP is bound to a
high binder it is bound to most of them or they have similar
populations.

In contrast, for lowly bound promoters very few DBPs are in common. Most
DBPs are bond to less than 5% of lowly bound promoters.

# Are there some DBPs that seperate the expressed vs not expressed high binding promoters?

This analysis will point us towards a possible repressor of high binding
promoters that results in lower expression despite high binding.

``` r
# subsecting promter_features to highly expressed and high binding status
high_binders <- promoter_features_df %>%
  filter(binding_status == "high")

# DBPs on high binders (hb)  and highly expressed 
expressed_hb <- promoter_peak_occurence[,high_binders %>%
                                                    filter(expression_level == "high") %>%
                                                    pull(gene_id)]

# DBPs on highbinders (hb) that are lowly expressed 
lowly_expressed_hb <- promoter_peak_occurence[,high_binders %>%
                                                    filter(expression_level == "low") %>%
                                                    pull(gene_id)]

# Percentage of DBP representation on expressed versus lowly expressed high binding promters
ehb_occupancy <- rowSums(expressed_hb) / ncol(expressed_hb)
lhb_occupancy <- rowSums(lowly_expressed_hb) / ncol(lowly_expressed_hb)
hb_binding_occupancy <- data.frame(dbp = names(ehb_occupancy),
                                high_exp = ehb_occupancy,
                                low_exp = lhb_occupancy ) %>%
  mutate(high_vs_low_ratio = log2((high_exp + 0.001) / (low_exp + 0.001)))
```

# Plotting DBP occupance on expressed versus lowly expressed high binding promoters

``` r
library(ggrepel)

ggplot(hb_binding_occupancy, aes(x = low_exp, y = high_vs_low_ratio, label = dbp)) +
  geom_point() +
  geom_text_repel(data = hb_binding_occupancy %>% filter(high_vs_low_ratio < -1)) +
  geom_text_repel(data = hb_binding_occupancy %>% filter(high_vs_low_ratio > 0.75)) +
  geom_smooth(method = "lm")
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/Plotting%20DBPs%20enriched%20on%20low%20expressed%20high%20binders%20(vice%20versa)-1.png)<!-- -->
Interesting, we see that EZH2 is associated with low expression
promoters despite high binding. this makes sense since EZH2 is a
repressor of gene expression. However is only on a few of the lowly
expressed high binding promoters (\~10%).

Conversely, High binding - high expression promoters are neriches with
euchromatic complexes. This makes sense as these DBPs are known to be
associated with active genes.

# Testing for the discriminators for the polII positive promoters.

Based on the results above we hypothesize that Pol II would be a good
indicator of expression versus non expressed high binders.

``` r
polII_names <- rownames(promoter_peak_occurence)[grep("POLR", rownames(promoter_peak_occurence))]

# Let's add a column with PolII status to our data.frame
polII_counts <- colSums(promoter_peak_occurence[polII_names,])
polII_counts_df <- data.frame(gene_id = names(polII_counts),
                              polII_status = polII_counts)
polII_counts_df <- polII_counts_df[promoter_features_df$gene_id,]
promoter_features_df$polII_status <- polII_counts_df$polII_status

# Defining high binding 
high_binders <- promoter_features_df %>%
  filter(binding_status == "high")
```

``` r
# at least one Pol II bound high binder and highly expressed and Pol II low expressed
expressed_hb <- promoter_peak_occurence[,high_binders %>%
                                                    filter(expression_level == "high", polII_status > 1) %>%
                                                    pull(gene_id)]
lowly_expressed_hb <- promoter_peak_occurence[,high_binders %>%
                                                    filter(expression_level == "low", polII_status > 1) %>%
                                                    pull(gene_id)]

# percentage of promoters with Pol II and expressed high binders
ehb_occupancy <- rowSums(expressed_hb) / ncol(expressed_hb)

# percentage of promoters with Pol II and lowly expressed high binders
lhb_occupancy <- rowSums(lowly_expressed_hb) / ncol(lowly_expressed_hb)

hb_binding_occupancy <- data.frame(dbp = names(ehb_occupancy),
                                high_exp = ehb_occupancy,
                                low_exp = lhb_occupancy ) %>%
  mutate(high_vs_low_ratio = log2((high_exp + 0.001) / (low_exp + 0.001)))
library(ggrepel)
```

``` r
ggplot(hb_binding_occupancy, aes(x = high_exp, y = high_vs_low_ratio, label = dbp)) +
  geom_point() +
  geom_text_repel(data = hb_binding_occupancy %>% filter(high_vs_low_ratio < -0.5)) +
  geom_text_repel(data = hb_binding_occupancy %>% filter(high_vs_low_ratio > 0.75)) +
  geom_smooth(method = "lm")
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20DBPs%20enriched%20on%20hihg%20binding%20and%20high%20expressed%20promters-1.png)<!-- -->

# How many genes are expressed but don’t have any DBPs bound

``` r
ggplot(promoter_features_df %>% 
         filter(number_of_dbp == 0, !is.na(tpm)), aes(x = expressed)) +
          geom_bar() +
          geom_text(stat='count', aes(label=..count..), vjust=-1) 
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/number%20of%20genes%20expressed%20with%200%20DBPs%20bound-1.png)<!-- -->
This is probably explained that there is a different TSS that is bound –
we are using the longest isoform, but this may not be the one that is
active in this data. A better approach would be to do this on an isoform
level.

## ATAC-seq

Let’s look to see if there are differences in the number of ATAC-seq
peaks over the promoters with different amounts of DBPs.

``` r
# Download data:
# wget https://www.encodeproject.org/files/ENCFF536RJV/@@download/ENCFF536RJV.bed.gz

# Converting downloaded data to "bed" format via read.table
atac_peaks <- read.table("data/ENCFF536RJV.bed.gz",
                         col.names = c("chrom", "start", "end", "name", "score", 
                                       "strand", "signal_value", "pval", 
                                       "qval", "summit"))

# Crateing GRanges of ATAC peaks
atac_peaks_gr <- GRanges(seqnames = atac_peaks$chrom,
                         ranges = IRanges(start = atac_peaks$start,
                                          end = atac_peaks$end))
atac_peaks_list <- list(atac_peaks_gr)
names(atac_peaks_list) <- "atac"

# ATAC peaks that overlap with promoters
atac_promoter_ov <- count_peaks_per_feature(lncrna_mrna_promoters, atac_peaks_list, type = "counts")
atac_promoter_df <- atac_promoter_ov %>% 
  t() %>%
  as.data.frame() %>%
  rownames_to_column("gene_id")
```

# Plotting the distribution of ATAC peaks overlapping promoters.

``` r
ggplot(atac_promoter_df, aes(x = atac)) +
  geom_density(adjust = 1.9)
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/Plotting%20ATAC%20peaks%20overlaps-1.png)<!-- -->
We observe that there is a distribution of 1 or less and another peak
around 5 ATAC peaks overlapping a promoter.

``` r
promoter_features_df <- promoter_features_df %>%
  left_join(atac_promoter_df)
```

# Plotting ATAC peak overlaps versus number of DBPS bound

``` r
ggplot(promoter_features_df %>% filter(number_of_dbp > 100), aes(x = number_of_dbp, y = atac)) +
  geom_bin_2d() +
  geom_smooth() +
  stat_cor()
```

![](Genome_wide_dna_binding_HEPG2_files/figure-gfm/plotting%20ATAC%20promter%20features-1.png)<!-- -->
We observe a slight but significant linear trend between \# atac peaks
and \# DBPs bound. This could lead us to hypothesize that

# writting out useful files made above to results

``` r
write_csv(promoter_features_df, "analysis/results/tables/promoter_features_df.csv")
write_csv(tpm, "analysis/results/tables/mean_tpm_per_condition.csv")
write_csv(samplesheet, "analysis/results/tables/samplesheet.csv")
write_csv2(res_status, "analysis/results/tables/reservoir_overlap_stats.csv")
write_csv2(hepg2_k562_promoter_features_df, "analysis/results/tables/hepg2_k562_promoter_features_df.csv")
```
