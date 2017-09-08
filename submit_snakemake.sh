#!/bin/bash
#PBS -S /bin/bash
source /etc/profile.d/modules.sh
time=`date +"%Y%m%d_%H%M%S"`
module load snakemake
export TARGET="$target"
export SOURCE="/users/n2000747426/patidarr/bcl2fastq/"
log="/users/n2000747426/patidarr/log/"
mkdir -p $log
snakemake -r -p --snakefile $SOURCE/bcl2fastq.snakemake\
	--nolock  --ri -k -p -T -r -j 3000\
	--cluster "qsub -W umask=022 -V -o $log -e $log {params.batch}"\
	--stats $log/${time}.stats >& $log/${time}.log
####################################




: <<'END'
module load snakemake
export TARGET="/projects/lihc_hiseq/static/150609_D00748_0024_AC6JF9ANXX/bcl2fastq.done"
export SOURCE="/users/n2000747426/patidarr/bcl2fastq/"
snakemake -r -p --snakefile $SOURCE/bcl2fastq.snakemake --dryrun
END
