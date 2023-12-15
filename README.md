TOBIAS Snakemake pipeline
=======================================

Introduction
------------

ATAC-seq (Assay for Transposase-Accessible Chromatin using high-throughput sequencing) is a sequencing assay for investigating genome-wide chromatin accessibility. The assay applies a Tn5 Transposase to insert sequencing adapters into accessible chromatin, enabling mapping of regulatory regions across the genome. Additionally, the local distribution of Tn5 insertions contains information about transcription factor binding due to the visible depletion of insertions around sites bound by protein - known as _footprints_.

**TOBIAS** is a collection of command-line bioinformatics tools for performing footprinting analysis on ATAC-seq data. Please see the [TOBIAS github repository](https://github.com/loosolab/TOBIAS/) for details about the individual tools.

Snakemake how-to:
-----------------

To use the snakemake pipeline, clone the github repository:
```
$ git clone https://github.com/loosolab/TOBIAS_snakemake.git
$ cd TOBIAS_snakemake
```

Make sure the included conda environment is installed and loaded:
```
$ conda env create -f environments/snakemake.yaml
$ conda activate tobias_snakemake_env
```
Note: if the conda environments take a long time to build, we recommend using the conda reimplementation mamba, e.g. `mamba env create (....)`.

Download the test data using TOBIAS (only used to run the example):
```
$ TOBIAS DownloadData
$ mv data-tobias-2020 data
```

You can now use the example config (example_config.yaml) or adjust to your own data by replacing the values for each key. To run snakemake with 10 cores, use:
```bash
$ snakemake --configfile example_config.yaml --use-conda --cores 10
```
In case of systems where symbolic links are not possible, you can set --conda-prefix to another folder (for writing environments to):
```
$ snakemake --configfile example_config.yaml --use-conda --cores 10 --conda-prefix /tmp
```

More information on input/output is found in the [wiki](https://github.com/loosolab/TOBIAS_snakemake/wiki)

Help 
--------
In case of any issues/questions/comments, please write an issue [here](https://github.com/loosolab/TOBIAS_snakemake/issues).
