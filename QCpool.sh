#!/bin/bash


		for l in $list

			do

			wdir="/mnt/nas/yh/11.ATAC_seq_JAX/PQ111A11"
			echo ${l} > $wdir/${l}_QC2.txt
			
			##Total reads
			grep -A 2 "\"before_filtering"\" \
			$wdir/2.trim/${l}/${l}_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
			| tr ":" "\t" \
			| cut -f 2 \
			| echo "Total_reads:" $(awk '{print}') \
			>> $wdir/${l}_QC2.txt

			##Total pair reads
			grep -A 2 "\"before_filtering"\" \
			$wdir/2.trim//${l}/${l}_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
			| tr ":" "\t" \
			|cut -f 2 \
			| echo "Total_pair_reads:" $(awk '{print $1/2}') \
			>>$wdir/${l}_QC2.txt

			##Total reads passed q20
			grep -A 2 "\"after_filtering"\" \
			$wdir/2.trim//${l}/${l}_fastp.gz.json \
			| grep "\"total_reads"\" \
			| echo $(awk '{gsub(/^\s+|,|"/, "");print}') \
                        | tr ":" "\t" \
                        | cut -f 2 \
			| echo "Total_reads_passed_q20:" $(awk '{print}') \
			>>$wdir/${l}_QC2.txt

			##Total mapped reads
			grep "^PAIR" \
			$wdir/3.align/${l}.bam_alignment_metrics \
			| echo "Total_mapped_reads:" $(awk '{print $6}') \
			>>$wdir/${l}_QC2.txt



			##Total uniquely mapped reads
			awk '{print $4}' $wdir/3.align/${l}_dedup_metrics \
			| sed -n "7,8p" \
			| echo $(sed -z 's/\n/ /g') \
			| echo 'Total_uniquely_mapped_reads:' $(awk '{print $2*2}') \
			>> $wdir/${l}_QC2.txt


			##Redundancy
			awk '{print $10}' $wdir/3.align/${l}_dedup_metrics \
			| sed -n "7,8p" \
			| echo $(sed -z 's/\n/ /g') \
			| echo 'Redundancy:' $(awk '{print $2*100}') '%' \
			>> $wdir/${l}_QC2.txt

		
		
		##pooling data
		for c in $list
			
			do
			 
			wdir="/mnt/nas/yh/11.ATAC_seq_JAX/PQ111A11"
			
			cat $wdir/${c}_QC2.txt >> $wdir/QCpool.txt
		done &
done
wait


#excel f


dir="/mnt/nas/yh/11.ATAC_seq_JAX/PQ111A11"
for q in Total_reads: Total_pair_reads Total_reads_passed_q20 Total_mapped_reads Total_uniquely_mapped_reads Redundancy

	do
	
	grep $q $dir/QCpool.txt \
	| tr ":" "\t" \
	| cut -f 2 \
	 > $dir/${q%:}.txt
	
	sed -i "1 i ${q%:}" $dir/${q%:}.txt
done &
wait 



paste $dir/Total_reads.txt $dir/Total_pair_reads.txt $dir/Total_reads_passed_q20.txt $dir/Total_mapped_reads.txt $dir/Total_uniquely_mapped_reads.txt $dir/Redundancy.txt > $dir/QCexcel.txt
wait

sed -i 's/_/ /g' $dir/QCexcel.txt
wait
