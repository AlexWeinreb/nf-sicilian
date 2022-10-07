#!/bin/bash
#SBATCH --partition=general
#SBATCH --job-name=nf-sicilian-wrapper
#SBATCH -c 1
#SBATCH --mem=50M
#SBATCH --time=5-5:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=alexis.weinreb@yale.edu

nextflow run main.nf -resume -with-dag dag.dot -c 221007_3samples.conf -profile singularity

