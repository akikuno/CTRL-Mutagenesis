#!/bin/bash

fastq_path="$1"
grna_path="$2"

###############################################################################
# format line code
###############################################################################

cat "$grna_path" | tr -d "\r" >tmp_grna_path.csv
grna_path="tmp_grna_path.csv"

###############################################################################
# make output directory
###############################################################################

reports_dir=reports/"$(date '+%Y-%m-%d')/"

mkdir -p "$reports_dir"/

###############################################################################
# count read numbers
###############################################################################

#------------------------------------------------------------------------------
## Count reads with gRNAs
#------------------------------------------------------------------------------

: >tmp_grna.csv
for fq in "$fastq_path"/*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")
    echo "$sample_name"
    if echo "$fq" | grep -q "_R1_"; then
        index="R1"
    else
        index="R2"
    fi
    # 17種類のgRNAに対してマッチしたリードをカウントします
    for i in $(seq 1 17); do
        id=$(cat "$grna_path" | cut -d, -f 1 | head -n "$i" | tail -n 1)
        grna_fw=$(cat "$grna_path" | cut -d, -f 2 | head -n "$i" | tail -n 1)
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

cat "$grna_path" | cut -d, -f 2 >tmp_grnalist.csv
cat "$grna_path" | cut -d, -f 2 | tr ACGT TGCA | rev >>tmp_grnalist.csv

: >tmp_nogrna.csv
for fq in "$fastq_path"/*.gz; do
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")
    echo "$sample_name"
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
    sort -n |
    # ヘッダー行を挿入します
    awk 'BEGIN{print "sample_name,index,id,grna_fw,grna_rv,read number"}1' |
    cat >"$reports_dir"/read_numbers_by_grnas.csv

rm tmp*
