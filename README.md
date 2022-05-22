# Project-hybrid-sterility

森本さんとの共同研究です


## 環境構築

- [condaをインストール](https://conda.io/en/latest/miniconda.html)してください。
  - **WindowsはWSL2をセットアップし、Linux版のcondaをインストールしてください。**
  - [WSL2のインストールについて](https://docs.microsoft.com/ja-jp/windows/wsl/install)

```bash
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda install -y r-base r-essentials
```

## 使用方法

1. gRNAの配列情報を`data/grna.csv`を参考に更新してください。

2. `scripts/00-format.sh`の`fastq_path`と`grna_path`にそれぞれのパスを入力して、以下のコマンドを実行してください

```bash
bash scripts/00-format.sh
Rscript --vanilla --slave scripts/01-visualize.R
```

3. `reports/{解析日時}`のフォルダの中に結果一覧が出力されます。