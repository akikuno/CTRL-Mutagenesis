#!/bin/bash

###########################################################
# Author: Akihiro Kuno (akuno@md.tsukuba.ac.jp)
# Last updated: 2025-01-27
###########################################################

fastq_path="$1"
grna_path="$2"

###############################################################################
# format line code
###############################################################################

# Remove CR code: CR codes can cause unexpected behavior or errors in bash, so they will be removed.

cat "$grna_path" | tr -d "\r" >tmp_grna_path.csv
grna_path="tmp_grna_path.csv"

###############################################################################
# make output directory
###############################################################################

reports_dir=reports/"$(date '+%Y-%m-%d')/"

mkdir -p "$reports_dir"/
echo "*" >"$reports_dir"/.gitignore

###############################################################################
# count read numbers
###############################################################################

#------------------------------------------------------------------------------
## Count reads with gRNAs
#------------------------------------------------------------------------------

true >tmp_grna.csv
for fq in "$fastq_path"/*.gz; do
    # 最後のsedは、得られた文字列の末尾にある1桁の数字をゼロ埋めして、2桁のフォーマットに統一するためのものです
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")
    if echo "$fq" | grep -q "_R1_"; then
        index="R1"
    else
        index="R2"
    fi

    echo "Counting gRNA reads in ${sample_name} ${index}..."

    cat "$grna_path" |
        tr "," " " |
        while read -r id grna_fw; do
            # Convert to uppercase
            grna_fw=$(echo "$grna_fw" | tr "acgt" "ACGT")

            # Reverse complement
            grna_rv=$(echo "$grna_fw" | tr "ACGT" "TGCA" | rev)

            # Count read numbers
            gzip -dc "$fq" |
                paste - - - - |
                cut -f 2 |
                grep -i -c -e "$grna_fw" -e "$grna_rv" |
                sed "s|^|${sample_name},${index},${id},${grna_fw},${grna_rv},|" |
                cat >>tmp_grna.csv
        done
done

#------------------------------------------------------------------------------
## Count reads without gRNAs
#------------------------------------------------------------------------------

cat "$grna_path" |
    cut -d, -f 2 |
    tr "acgt" "ACGT" |
    tee tmp_grnalist.csv |
    # Reverse complement
    tr "ACGT" "TGCA" |
    rev |
    # Remove empty lines
    grep ^ >>tmp_grnalist.csv

true >tmp_nogrna.csv
for fq in "$fastq_path"/*.gz; do
    # 最後のsedは、得られた文字列の末尾にある1桁の数字をゼロ埋めして、2桁のフォーマットに統一するためのものです
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")

    if echo "$fq" | grep -q "_R1_"; then
        index="R1"
    else
        index="R2"
    fi

    echo "Counting reads without gRNAs in ${sample_name} ${index}..."

    gzip -dc "$fq" |
        paste - - - - |
        cut -f 2 |
        grep -i -c -v -f tmp_grnalist.csv |
        sed "s|^|${sample_name},${index},no,no,no,|" |
        cat >>tmp_nogrna.csv
done

cat tmp_grna.csv tmp_nogrna.csv |
    sort -n |
    # Insert header line
    awk 'BEGIN{print "sample_name,index,id,grna_fw,grna_rv,read number"}1' |
    cat >"$reports_dir"/read_numbers_by_grnas.csv

# Remove temporary files
rm tmp_grna_path.csv tmp_grna.csv tmp_grnalist.csv tmp_nogrna.csv
