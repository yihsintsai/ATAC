library(ATACseqQC)
setwd("/mnt/nas/yh/11.ATAC_seq_JAX/PQ111A11/3.align/")
list <- c("")
gene_list<-read.table("../list")
for (i in 1:nrow(gene_list)){
gene_id <-gene_list$V1[i]
bam_name <- paste0(gene_id,"_R1.fq.gz.dedup.bam")
pdf(paste("/mnt/nas/yh/11.ATAC_seq_JAX/PQ111A11/5.QC/",paste(gene_id,"pdf",sep = "."),sep = "/"),
    width = 10, height = 7, onefile=F)
  fragSize <- fragSizeDist(bamFiles = bam_name,
                         index = bam_name,
                         bamFiles.labels = gene_id )
dev.off()
}