#!/bin/bash

###########################################################
# Author: Akihiro Kuno (akuno@md.tsukuba.ac.jp)
# Last updated: 2026-06-10
###########################################################

fastq_path="$1"
grna_path="$2"

###############################################################################
# Check dependencies
###############################################################################

if ! command -v seqkit >/dev/null 2>&1; then
    echo "Error: seqkit is not installed or not found in PATH." >&2
    exit 1
fi

###############################################################################
# Format line code
###############################################################################

# Remove CR codes because they can cause unexpected behavior in bash.
tr -d "\r" <"$grna_path" >tmp_grna_lists.csv
grna_path="tmp_grna_lists.csv"

###############################################################################
# Make output directory
###############################################################################

reports_dir=reports/"$(date '+%Y-%m-%d')/"

mkdir -p "$reports_dir"/
echo "*" >"$reports_dir"/.gitignore

###############################################################################
# Count read numbers
###############################################################################

#------------------------------------------------------------------------------
# Count reads with gRNAs
#------------------------------------------------------------------------------

# Number of parallel jobs.
num_jobs="${3:-4}"

tmp_grna_dir=$(mktemp -d)

count_grna_in_fastq() {
    local fq="$1"
    local grna_path="$2"
    local tmp_grna_dir="$3"

    local sample_name
    local index
    local out_file
    local id
    local grna_fw
    local grna_rv
    local count

    # Zero-pad the final one-digit sample number.
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")

    if [[ "$fq" == *"_R1_"* ]]; then
        index="R1"
    else
        index="R2"
    fi

    echo "Counting gRNA reads in ${sample_name} ${index}..."

    # Write to a job-specific file to avoid race conditions.
    out_file="${tmp_grna_dir}/$(basename "$fq").csv"
    true >"$out_file"

    while IFS=, read -r id grna_fw _; do
        # Skip empty gRNA sequences.
        if [[ -z "$grna_fw" ]]; then
            continue
        fi

        # Convert to uppercase.
        grna_fw=$(echo "$grna_fw" | tr "acgt" "ACGT")

        # Reverse complement.
        grna_rv=$(echo "$grna_fw" | tr "ACGT" "TGCA" | rev)

        # Count reads containing the forward or reverse-complement gRNA sequence.
        count=$(
            seqkit grep \
                -s \
                -i \
                -P \
                -m 1 \
                -p "$grna_fw" \
                -p "$grna_rv" \
                -C \
                "$fq"
        )

        echo "${sample_name},${index},${id},${grna_fw},${grna_rv},${count}" >>"$out_file"
    done <"$grna_path"
}

export -f count_grna_in_fastq
export grna_path
export tmp_grna_dir

find "$fastq_path" -maxdepth 1 -type f -name "*.gz" -print0 |
    xargs -0 -n 1 -P "$num_jobs" bash -c \
        'count_grna_in_fastq "$1" "$grna_path" "$tmp_grna_dir"' _

echo "$tmp_grna_dir"/
ls -l "$tmp_grna_dir"/

cat "$tmp_grna_dir"/*.csv >tmp_grna.csv

rm -r "$tmp_grna_dir"

#------------------------------------------------------------------------------
# Count reads without gRNAs
#------------------------------------------------------------------------------

true >"tmp_grnalist.csv"

while IFS=, read -r id grna_fw _; do
    # Skip empty gRNA sequences.
    if [[ -z "$grna_fw" ]]; then
        continue
    fi

    # Convert to uppercase.
    grna_fw=$(echo "$grna_fw" | tr "acgt" "ACGT")

    # Reverse complement.
    grna_rv=$(echo "$grna_fw" | tr "ACGT" "TGCA" | rev)

    # Store both forward and reverse-complement sequences.
    echo "$grna_fw" >>tmp_grnalist.csv
    echo "$grna_rv" >>tmp_grnalist.csv
done <"$grna_path"

# Remove empty lines and duplicated patterns.
awk 'NF' tmp_grnalist.csv | sort -u >tmp_grnalist.unique.csv
mv tmp_grnalist.unique.csv tmp_grnalist.csv


tmp_nogrna_dir=$(mktemp -d)

count_nogrna_in_fastq() {
    local fq="$1"
    local tmp_nogrna_dir="$2"

    local sample_name
    local index
    local out_file
    local count

    # Zero-pad the final one-digit sample number.
    sample_name=$(basename "$fq" | cut -d "_" -f 1 | sed "s/-\([1-9]\)$/-0\1/")

    if [[ "$fq" == *"_R1_"* ]]; then
        index="R1"
    else
        index="R2"
    fi

    echo "Counting reads without gRNAs in ${sample_name} ${index}..."

    out_file="${tmp_nogrna_dir}/$(basename "$fq").csv"

    # Count reads that do not contain any gRNA sequence within one mismatch.
    # -s: search in read sequences
    # -i: ignore case
    # -P: search only the positive strand
    # -m 1: allow up to one mismatch
    # -f: read patterns from file
    # -v: invert match, i.e., count reads without gRNAs
    # -C: print only the number of matching reads
    count=$(
        seqkit grep \
            -s \
            -i \
            -P \
            -m 1 \
            -f tmp_grnalist.csv \
            -v \
            -C \
            "$fq"
    )

    echo "${sample_name},${index},no,no,no,${count}" >"$out_file"
}

export -f count_nogrna_in_fastq
export tmp_nogrna_dir

find "$fastq_path" -maxdepth 1 -type f -name "*.gz" -print0 |
    xargs -0 -n 1 -P "$num_jobs" bash -c \
        'count_nogrna_in_fastq "$1" "$tmp_nogrna_dir"' _

cat "$tmp_nogrna_dir"/*.csv >tmp_nogrna.csv

rm -r "$tmp_nogrna_dir"


cat tmp_grna.csv tmp_nogrna.csv |
    sort -n |
    # Insert header line.
    awk 'BEGIN{print "sample_name,index,id,grna_fw,grna_rv,read number"}1' |
    cat > tmp_read_numbers_by_grnas.csv

Rscript scripts/knee_exists_poisson.R tmp_read_numbers_by_grnas.csv "$reports_dir"/read_numbers_by_grnas.csv

# Rscript scripts/knee_exists.R "$reports_dir"/read_numbers_by_grnas_before.csv tmp_read_numbers_by_grnas.csv 


# Remove temporary files.
rm tmp_grna_lists.csv tmp_grna.csv tmp_grnalist.csv tmp_nogrna.csv tmp_read_numbers_by_grnas.csv
