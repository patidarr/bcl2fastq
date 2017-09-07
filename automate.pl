#!/usr/bin/perl
use strict;
use warnings;
# This is to automate:
#	 bcl2fastq conversion on moab
#	 change fastq file names as per required
#	 count # reads in files
# 	 copy data to biowulf and any other location it should get copied over to
# 	 send email notification
my $DIR = "/projects/lihc_hiseq/static/";
opendir(my $DH, $DIR);
while(readdir $DH){
	my $line = $_;
	chomp $line;
	if ($line =~ /(.*)_(.*)_(.*)_[A|B](.*)/){
		if (-e "$DIR/$line/RTAComplete.txt"){
			if (-e "$DIR/$line/Unaligned"){
			}
			elsif (-M "$DIR/$line/RTAComplete.txt" <5){
				# Make a file we need to check the next time
				# launch snakemake pipeline to launch bcl2fastq
				# which should remove this file at the end
				`/usr/local/bin/qsub -o /users/n2000747426/patidarr/bcl2fastq/log/ -e /users/n2000747426/patidarr/bcl2fastq/log/ -v target="$DIR/$line/bcl2fastq.done" /users/n2000747426/patidarr/bcl2fastq/submit_snakemake.sh`;
			}
		}
		else{
			#print "This is not a complete run??     $DIR/$line\n";
		}
	}
}
closedir $DH;
