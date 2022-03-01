#!/bin/bash

# rm data/Alignment_1/20220227_214619/Fastq/*.fastq

ls -lh data/Alignment_1/20220227_214619/Fastq/
zcat data/Alignment_1/20220227_214619/Fastq/1-1_S1_L001_R1_001.fastq.gz | head

###############################################################################
# fastqc
###############################################################################

mkdir -p reports/fastqc

for fq in data/Alignment_1/20220227_214619/Fastq/*.gz; do
    echo $fq
    fastqc "$fq" -o reports/fastqc
done
