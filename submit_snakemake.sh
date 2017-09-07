#!/bin/bash
#PBS -S /bin/bash
source /etc/profile.d/modules.sh
time=`date +"%Y%m%d"`
module load snakemake
export TARGET="$target"
snakemake -r -p --snakefile /users/n2000747426/patidarr/bcl2fastq/bcl2fastq.snakemake\
	--nolock  --ri -k -p -T -r -j 3000\
	--cluster "qsub -W umask=022 -V -o log/ -e log/ {params.batch}"\
	--stats ${time}.stats\
	$target >& ${time}.log
