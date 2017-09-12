#!/usr/bin/perl -sw
use List::Util qw(first);
#local $SIG{__WARN__} = sub {my $message =shift; die $message;};
# ./makeReport.pl /projects/lihc_hiseq/static/ 170905_D00717_0062_AHTW7FBCXY/Unaligned HTW7FBCXY |mutt -e "my_hdr Content-Type: text/html" -s "test" patidarr@mail.nih.gov

my $fastq_dir=$ARGV[0];
my $run_name=$ARGV[1];
my $run_id=$ARGV[2];
my %ID_NAME;
$ID_NAME{'Undetermined'} ="Undetermined";
my $head=header();
my $stats =fetch_stats();
getSampleID();
fetch_index();
my $index = getSampleInfo();
print "$head\n$stats\n$index\n";
sub header{
	my $string = "<p>Hello,<br><br>Here is the summary of this run:<br></p>\n";	
	return $string;
}
sub fetch_stats{
	my $html = $fastq_dir."/".$run_name."/Reports/html/".$run_id."/all/all/all/lane.html";
	unless (open (IN,"$html")){
		print STDERR "Can not open file $html\n";
	}
	my @line = <IN>;
	close IN;
	my $line;
	foreach my $l (@line){
		$line .= $l;
	}
	$line =~s/\<td><p align="right"><a href="\..\/\..\/\..\/\..\/$run_id\/all\/all\/all\/laneBarcode.html">show barcodes<\/a><\/p><\/td>//;
	return $line;
}
sub fetch_index{
	my $html = $fastq_dir."/".$run_name."/Reports/html/".$run_id."/all/all/all/laneBarcode.html";
	unless (open(FH, $html)){
		print STDERR "Can not open file $html\n";
	}
	open (my $out, ">",$fastq_dir."/".$run_name."/count.txt");
	$/ ="table";
	while(<FH>){
		chomp;
		if ($_=~ /Sample/){
			my @lines=split("<tr>", $_);
			foreach my $line (@lines){
				my @col = split("\n", $line);
				foreach my $raw(@col){
					if($raw =~ /^<th>(.*)<\/th>$/ or $raw =~ /^<td.*>(.*)<\/td>$/ ){
						print $out "$1\t";
					}
				}
				print $out "\n";
			}
		}
	}
	close FH;
}
sub getSampleID{
        unless (open(FH, "$fastq_dir/$run_name/../SampleSheet.csv")){
                print STDERR "Can not open $fastq_dir/$run_name/../SampleSheet.csv\n";
                exit;
        }
        my $idxName = 0;
        my $idxID   = 1;
        while(<FH>){
                chomp;
                next if 1 .. /Data/;
                my @format = split(",", $_);
                if ($_ =~ /Sample_ID/){
                        $idxID   = first { $format[$_] eq 'Sample_ID' } 0..$#format;
                        $idxName = first { $format[$_] eq 'Sample_Name' } 0..$#format;
                }
                $ID_NAME{$format[$idxName]} = $format[$idxID];
        }
        close FH;
}
sub getSampleInfo{
	$/ ="\n";
	unless (open(FH1, "<",$fastq_dir."/".$run_name."/count.txt")){
		print STDERR "Can not open count file\n";
	}
	my %sample_reads_count;
	my $idx_Sample;
	my $idx_PF;
	while(<FH1>){
		chomp;
		if ($_ =~ /^$/){next;};
		my @format = split("\t", $_);
		if( !defined($idx_Sample) ) {
			$idx_Sample = first { $format[$_] eq 'Sample' } 0..$#format;
		}
		if( !defined($idx_PF) ) {
			$idx_PF = first { $format[$_] eq 'PF Clusters' } 0..$#format;
		}
		if($_ =~ /PF Clusters/){next;};
		$format[$idx_PF] =~ s/,//g;
			if ($sample_reads_count{$format[$idx_Sample]}){
				$sample_reads_count{$format[$idx_Sample]} = $sample_reads_count{$format[$idx_Sample]} +$format[$idx_PF];
			}
			else{
				$sample_reads_count{$format[$idx_Sample]} = $format[$idx_PF];
			}
	}
	close FH1;
	unlink $fastq_dir."/".$run_name."/count.txt";
	$index_distribution_html = "<p> <h2>Reads by Sample</h2>\n<table border=\"1\">\n<tr><th>SampleID</th><th>Sample Name</th><th>PF Clusters</th><th>% of the sample</th></tr>\n";
	my $total=0;
	foreach (values %sample_reads_count){
		$total +=$_;
	}

	foreach my $key (sort keys %sample_reads_count){
		my $pct=sprintf("%.2f",$sample_reads_count{$key}/$total*100);
		$sample_reads_count{$key} =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
		$index_distribution_html .= "<tr><td>$ID_NAME{$key}</td><td>$key</td><td>$sample_reads_count{$key}</td><td>$pct</td></tr>\n";
	}
	$index_distribution_html .= "</table></p>\n";
	$index_distribution_html .= "<p><br><br><br>Thanks,<br>Bioinformatics Team<br>MoCha</p>\n";
	return $index_distribution_html;
}
