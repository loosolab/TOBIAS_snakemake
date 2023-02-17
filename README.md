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
git clone https://github.molgen.mpg.de/loosolab/TOBIAS_snakemake.git
```

Make sure the included conda environments are installed:
```
$ conda env create -f environments/snakemake.yaml
```

You can use the example config (example_config.yaml) or adjust to your own data by replacing the values for each key. Run using:
```bash
$ conda activate tobias_snakemake_env
$ snakemake --configfile example_config.yaml --use-conda --cores [number of cores]
```
In case of systems where symbolic links are not possible, you can set --conda-prefix to another folder (for writing environments to):
```
$ snakemake --configfile example_config.yaml --use-conda --cores [number of cores] --conda-prefix /tmp 
```

More information on input/output is found in the [wiki](https://github.molgen.mpg.de/loosolab/TOBIAS_snakemake/wiki)

Contact
------------
Mette Bentsen (mette.bentsen (at) mpi-bn.mpg.de)
