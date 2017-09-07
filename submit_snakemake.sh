#!/bin/bash
#PBS -S /bin/bash
source /etc/profile.d/modules.sh
time=`date +"%Y%m%d_%H%M%S"`
module load snakemake
export TARGET="$target"
snakemake -r -p --snakefile /users/n2000747426/patidarr/bcl2fastq/bcl2fastq.snakemake\
	--nolock  --ri -k -p -T -r -j 3000\
	--cluster "qsub -W umask=022 -V -o /users/n2000747426/patidarr/bcl2fastq/log/{params.rulename}.%j.o -e /users/n2000747426/patidarr/bcl2fastq/log/{params.rulename}.%j.o {params.batch}"\
	--stats /users/n2000747426/patidarr/bcl2fastq/log/${time}.stats\
	$target >& /users/n2000747426/patidarr/bcl2fastq/log/${time}.log
