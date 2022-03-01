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

###############################################################################
# count read numbers
###############################################################################

: >tmp.csv

for fq in data/Alignment_1/20220227_214619/Fastq/*R1*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1)
    # 辞書順にソートする都合上、サンプル番号1-1などを"1-01”と変更いたします
    sample_name=$(echo $sample_name | sed "s/-\([1-9]\)$/-0\1/")
    echo $sample_name
    # リード数を数えます
    gzip -dc "$fq" |
        grep "^@" |
        wc -l |
        sed "s/^/${sample_name},/" |
        cat >>tmp.csv
done

sort tmp.csv >reports/read_numbers.csv

rm tmp.csv

###############################################################################
# count gRNAs
###############################################################################

: >tmp.csv
for fq in data/Alignment_1/20220227_214619/Fastq/*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1)
    if echo "$fq" | grep -q "_R1_"; then
        sample_name="$sample_name"_R1
    else
        sample_name="$sample_name"_R2
    fi
    sample_name=$(echo $sample_name | sed "s/-\([1-9]\)_/-0\1_/")
    # 17種類のgRNAに対してマッチしたリードをカウントします
    for i in $(seq 1 17); do
        id=$(cat misc/grna.csv | cut -d, -f 1 | head -n "$i" | tail -n 1)
        grna_fw=$(cat misc/grna.csv | cut -d, -f 2 | head -n "$i" | tail -n 1)
        grna_rv=$(echo "$grna_fw" | tr "ACGT" "TGCA" | rev)
        gzip -dc "$fq" |
            grep -e "$grna_fw" -e "$grna_rv" |
            wc -l |
            sed "s|^|${sample_name},${id},${grna_fw},${grna_rv},|" |
            cat >>tmp.csv
    done
done

sort tmp.csv >reports/read_numbers_by_grnas.csv

rm tmp.csv
