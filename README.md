# Project-hybrid-sterility

- The code quantifies the amount of each gRNA integration for each ES clone.

# Requirements

- bash
- R (>3.6)
  - tidyverse
  - RColorBrewer


# Procedure

- Prepare a directory including FASTQ files
- Save the gRNA sequence information in CSV format with the first column as ID and the second column as sequences
  - Refer to `data/grna.csv`.

- Based on the PATH of the FASTQ directory and the gRNA sequence table, run the following command

```bash
bash scripts/00-format.sh {path_fastqs} {path_grna}
Rscript --vanilla --slave scripts/01-visualize.R
```

## Output

- Results are outputted in the folder `reports/{analysis date}`.
  - Refer to `reports/2022-05-30`
