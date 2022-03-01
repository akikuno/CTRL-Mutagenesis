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

# NGS関連ツール
conda install -y fastqc

# R言語
conda install -y r-base r-essentials
```