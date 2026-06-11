<!--
# Author: Akihiro Kuno (akuno@gwe.md.tsukuba.ac.jp)
# Last updated: 2026-06-10
 -->

# CTRL-Mutagenesis

- The code quantifies the amount of sgRNA cassettes in FASTQ reads.

# Requirements

- bash
- seqkit
- R (>4.0)
  - tidyverse


# Procedure

- Prepare a directory including FASTQ files
- Save the gRNA sequence information in CSV format with the first column as ID and the second column as sequences
  - Refer to `data/grna.csv`.

- Based on the PATH of the FASTQ directory and the gRNA sequence table, run the following command:

```bash
bash scripts/00-format.sh <PATH of the FASTQ directory> <PATH of gRNA sequence table> <Integer>
Rscript --vanilla --slave scripts/01-visualize.R -w=15 -h=50 -ncol=4
```

- In `00-format.sh`, <Integer> specifies the number of parallel jobs used for counting reads.
  - The default value is `4`.
- In `Rscript`, you can specify the width, height and number of colmuns of the plot using the `-w`, `-h` and `-ncol` options, respectively.
  - The default values are `-w=15`, `-h=50` and `ncol=4`.


## `exists` column

The `exists` column indicates whether each gRNA/barcode is considered to be reliably detected based on the read-count distribution.

For each FASTQ sample, read counts of each gRNA are sorted in descending order, and a curvature-based knee point is estimated from the rank versus log10(read count) curve. The read count at the knee point is used as the threshold. This method is inspired by [kneeliverse.curvature](https://mariolpantunes.github.io/knee/kneeliverse/curvature.html).

* `True`: The read count is greater than or equal to the knee threshold.
* `False`: The read count is below the knee threshold and is treated as low-count noise.

This annotation is intended to separate confidently detected gRNAs/barcodes from low-read candidates that may reflect sequencing errors, barcode noise, or insufficient read support.


## Output

- Results are outputted in the folder `reports/{analysis date}`.
