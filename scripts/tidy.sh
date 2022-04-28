#!/bin/bash

fastq_path="data/20220425_FS10002129_2_BPN80007-1119/Alignment_1/20220426_164553/Fastq/"
reports_dir=reports/"$(date '+%Y-%m-%d')/"

# ###############################################################################
# # quality check
# ###############################################################################

# mkdir -p "$reports_dir"/fastqc

# for fq in "$fastq_path"/*.gz; do
#     echo $fq
#     fastqc "$fq" -o "$reports_dir"/fastqc
# done

###############################################################################
# count read numbers
###############################################################################

mkdir -p "$reports_dir"/

#------------------------------------------------------------------------------
## Count total reads
#------------------------------------------------------------------------------

: >tmp.csv

for fq in "$fastq_path"/*R1*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1)
    # 辞書順にソートする都合上、サンプル番号1-1などを"1-01”と変更します
    sample_name=$(echo $sample_name | sed "s/-\([1-9]\)$/-0\1/")
    echo $sample_name
    # リード数を数えます
    gzip -dc "$fq" |
        grep "^@" |
        wc -l |
        sed "s/^/${sample_name},/" |
        cat >>tmp.csv
done

sort tmp.csv >"$reports_dir"/read_numbers.csv

rm tmp.csv

#------------------------------------------------------------------------------
## Count reads with gRNAs
#------------------------------------------------------------------------------

: >tmp_grna.csv
for fq in "$fastq_path"/*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")
    echo $sample_name
    if echo "$fq" | grep -q "_R1_"; then
        index="R1"
    else
        index="R2"
    fi
    # 17種類のgRNAに対してマッチしたリードをカウントします
    for i in $(seq 1 17); do
        id=$(cat data/grna.csv | cut -d, -f 1 | head -n "$i" | tail -n 1)
        grna_fw=$(cat data/grna.csv | cut -d, -f 2 | head -n "$i" | tail -n 1)
        grna_rv=$(echo "$grna_fw" | tr "ACGT" "TGCA" | rev)
        gzip -dc "$fq" |
            grep -c -e "$grna_fw" -e "$grna_rv" |
            sed "s|^|${sample_name},${index},${id},${grna_fw},${grna_rv},|" |
            cat >>tmp_grna.csv
    done
done

#------------------------------------------------------------------------------
## Count reads without gRNAs
#------------------------------------------------------------------------------

cat data/grna.csv | cut -d, -f 2 >tmp_grnalist.csv
cat data/grna.csv | cut -d, -f 2 | tr ACGT TGCA | rev >>tmp_grnalist.csv

: >tmp_nogrna.csv
for fq in "$fastq_path"/*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")
    echo $sample_name
    if echo "$fq" | grep -q "_R1_"; then
        index="R1"
    else
        index="R2"
    fi
    gzip -dc "$fq" |
        paste - - - - |
        cut -f 2 |
        grep -c -v -f tmp_grnalist.csv |
        sed "s|^|${sample_name},${index},no,no,no,|" |
        cat >>tmp_nogrna.csv
done

cat tmp_grna.csv tmp_nogrna.csv |
    sort |
    # ヘッダー行を挿入します
    awk 'BEGIN{print "sample_name,index,id,grna_fw,grna_rv,read number"}1' |
    cat >"$reports_dir"/read_numbers_by_grnas.csv

rm tmp*

### supplementary  --------------------------------------------------

# 合計リード数の確認
# fq="$fastq_path"/1-1_S1_L001_R2_001.fastq.gz
# zcat $fq | grep "^@" | wc -l # 243,342配列

# cat "$reports_dir"/read_numbers_by_grnas.csv |
#     grep 1-01,R2 |
#     awk -F, '{sum+=$NF} END{print sum}' # 243,342
