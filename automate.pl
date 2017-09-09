#!/usr/bin/perl
use strict;
use warnings;
# This is to automate:
#	 bcl2fastq conversion on moab [Done]
#	 change fastq file names as per required [Done]
#	 count # reads in files [Done]
# 	 copy data to biowulf and any other location it should get copied over to [Done]
# 	 send email notification [Done]
my $LOG="/users/n2000747426/patidarr/log/";
my $PIPELINE="/users/n2000747426/patidarr/bcl2fastq/";
my $DIR = "/projects/lihc_hiseq/static/";
opendir(my $DH, $DIR);
while(readdir $DH){
	my $line = $_;
	chomp $line;
	if ($line =~ /(.*)_(.*)_(.*)_[A|B](.*)/){
		my $FCID=$4;
		if (-e "$DIR/$line/RTAComplete.txt"){
			if (-e "$DIR/$line/Unaligned"){
				# Already processed or job running.
			}
			elsif (-M "$DIR/$line/RTAComplete.txt" <5 and -e "$DIR/$line/SampleSheet.csv"){
				# Make a file we need to check the next time
				# launch snakemake pipeline to launch bcl2fastq
				# which should remove this file at the end
				`/usr/local/bin/qsub -N $FCID -o $LOG -e $LOG -v target="$DIR/$line/bcl2fastq.done" $PIPELINE/submit_snakemake.sh`;
			}
		}
		else{
			#print "This is not a complete run??     $DIR/$line\n";
		}
	}
}
closedir $DH;
