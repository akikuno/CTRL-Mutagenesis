<!--
# Author: Akihiro Kuno (akuno@md.tsukuba.ac.jp)
# Last updated: 2025-01-27
 -->

# CTRL-Mutagenesis

- The code quantifies the amount of sgRNA cassettes in FASTQ reads.

# Requirements

- bash
- R (>4.0)
  - tidyverse


# Procedure

- Prepare a directory including FASTQ files
- Save the gRNA sequence information in CSV format with the first column as ID and the second column as sequences
  - Refer to `data/grna.csv`.

- Based on the PATH of the FASTQ directory and the gRNA sequence table, run the following command:

```bash
bash scripts/00-format.sh <PATH of the FASTQ directory> <PATH of gRNA sequence table>
Rscript --vanilla --slave scripts/01-visualize.R -w=15 -h=50 -ncol=4
```

- In `Rscript`, you can specify the width, height and number of colmuns of the plot using the `-w`, `-h` and `-ncol` options, respectively.
  - The default values are `-w=15`, `-h=50` and `ncol=4`.


## Output

- Results are outputted in the folder `reports/{analysis date}`.
  - Refer to `reports/2022-05-30`
