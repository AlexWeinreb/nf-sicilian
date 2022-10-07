#!/bin/bash
#SBATCH --partition=general
#SBATCH --job-name=nf-sicilian-wrapper
#SBATCH -c 1
#SBATCH --mem=500M
#SBATCH --time=5-5:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=alexis.weinreb@yale.edu

module load miniconda
module load Java/11.0.2

conda activate sicilian_no_nf

nextflow run main.nf -resume -with-dag dag.dot -c 221007_3samples.conf -profile singularity

