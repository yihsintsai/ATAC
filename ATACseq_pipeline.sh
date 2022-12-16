#!/bin/bash

PATH=$PATH:/home/software/FastQC/
PATH=$PATH:/home/software/TrimGalore-0.6.1/
PATH=$PATH:/home/software/cutadapt/bin/
PATH=$PATH:/home/software/bowtie2-2.3.5.1/
PATH=$PATH:/home/software/samtools/

# picard jar
picard="/home/software/picard.jar"

# parameter
wor_dir=""
cpu=""
genome_index="/data2/reference/index/bowtie2/hg38/hg38"
multimappers="/home/software/atac_dnase_pipelines/utils/assign_multimappers.py"
multimapping="4"
blacklist="/data2/reference/hg38.blacklist.bed"
# bamCoverage --effectiveGenomeSize
GRCh38="2913022398"



for var in  
do

## FASTQ read adaptor trimming


trim_galore --gzip -o $wor_dir/trim  --paired \
$wor_dir/${var}_R1.fq.gz $wor_dir/${var}_R2.fq.gz \
 2>$wor_dir/trim/${var}_trimmed.log \
echo $var 'end time of Trimming step $var' `date`

## Alignment

bowtie2 -k $multimapping -X2000 --local --mm --threads $cpu \
 -x $genome_index \
 -1 $wor_dir/trim/${var}_R1_val_1.fq.gz \
 -2 $wor_dir/trim/${var}_R2_val_2.fq.gz \
 2>$wor_dir/trim/${var}_align.log | \
 samtools view -Su /dev/stdin | \
 samtools sort -@ $cpu_num -m 3gb \
 > $wor_dir/trim/${var}_align.bam
echo $var 'end time of alignment step $var' `date`

## Alignment filtering
# remove unmapped, mate unmapped
# not primary alignment, reads failing platform

samtools view -@ $cpu -F 524 -f 2 -u $wor_dir/trim/${var}_align.bam \
 | samtools sort -@ $cpu_num -m 3gb -n \
 >  $wor_dir/${var}_sort.bam

samtools view -@ $cpu -h $wor_dir/${var}_sort.bam \
 | $multimappers -k $multimapping --paired-end \
 | samtools view -@ $cpu_num -bS  > $wor_dir/${var}_filter.bam

samtools fixmate -@ $cpu -r $wor_dir/${var}_filter.bam \
  $wor_dir/${var}_fixmate.bam

samtools view -@ $cpu -F 1804 -f 2 -u $wor_dir/${var}_fixmate.bam  \
 | samtools sort  -@ $cpu  > $wor_dir/${var}_Dup.bam

echo $var 'end time of filtering step $var' `date`

## Markduplicates
java -jar $picard MarkDuplicates \
 I=$wor_dir/${var}_Dup.bam \
 O=$wor_dir/${var}_MarkDup.bam \
 M=$wor_dir/${var}_Matrix.txt \
 REMOVE_DUPLICATES=false \
 VALIDATION_STRINGENCY=LENIENT \
 ASSUME_SORTED=true \
 2>$wor_dir/${var}_MarkDup.log

echo $var 'end time of deduplicate step' `date`


samtools view -@ $cpu -F 1804 -f 2 \
 -b $wor_dir/${var}_MarkDup.bam \
 > $wor_dir/${var}_final.bam

samtools index -@ $cpu  $wor_dir/${var}_final.bam

echo $var 'end time of last filter step' `date`

#shift
alignmentSieve -b  $wor_dir/${var}_final.bam -o  $wor_dir/${var}_shift.bam \
 --filterMetrics $wor_dir/${var}_shift.txt --ignoreDuplicates \
 --ATACshift

samtools sort  -O bam -o  $wor_dir/${var}_shiftFinal.bam -@ $cpu $wor_dir/${var}_shift.bam

samtools index -@ $cpu  $wor_dir/${var}_shiftFinal.bam

echo $var 'end time of shift step' `date`


#call peak
macs2 callpeak -t $wor_dir/${var}_shiftFinal.bam \
 -n ${var} -g hs -f BAMPE --shift -75 --extsize 150 --nomodel \
 --call-summits --nolambda --keep-dup  all -p 0.01  \
 --outdir $wor_dir/${var} \
 2>$wor_dir/${var}_callpeak.log

echo $var 'end time of call peak step' `date`


# coverage 
bamCoverage --bam $wor_dir/${var}_final.bam --outFileName $wor_dir/bigwig/${var}.bigwig \
 --binSize  5 --effectiveGenomeSize   2864785220 --normalizeUsing  CPM   --extendReads  201  -p  $cpu
echo $var 'end time of bamCoverage step' `date`




echo $var 'end of the script'


done &

