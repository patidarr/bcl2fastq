#!/usr/bin/perl -sw
use List::Util qw(first);
local $SIG{__WARN__} = sub {my $message =shift; die $message;};

my $fastq_dir=$ARGV[0];
my $run_name=$ARGV[1];
my $run_id=$ARGV[2];


my $stats =fetch_stats();
my $index =fetch_index();
#my $index_distribution =index_distribution();
print "$stats\n";

sub fetch_stats{
	my $html = $fastq_dir."/".$run_name."/Reports/html/".$run_id."/all/all/all/lane.html";
	open my $in,"$html";
	my @line = <$in>;
	close $in;
	my $line;
	foreach my $l (@line){
		$line .= $l;
	}
	$line =~s/\<td><p align="right"><a href="\..\/\..\/\..\/\..\/$run_id\/all\/all\/all\/laneBarcode.html">show barcodes<\/a><\/p><\/td>//;
	#  print $line;
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
$index_distribution_html = "<p> <h2>Reads by Sample</h2>\n<table border=\"1\">\n<tr><th>Sample</th><th>PF Clusters</th><th>% of the sample</th></tr>\n";
foreach (keys %sample_reads_count){
	$index_distribution_html .= "<tr><td>$_</td><td>$sample_reads_count{$_}</td><td></td></tr>\n";
}
$index_distribution_html .= "</table></p>\n";
print $index_distribution_html;

close FH1;

sub index_distribution{
	my @samples = `ls -d $fastq_dir/$run_name/*/*`;
	my $total_reads_count = 0;
	my $total_undtmt_reads_count = `/bin/zcat $fastq_dir/$run_name/Undetermined_*_R1_*.fastq.gz | /bin/grep \@ | /usr/bin/wc -l`;
	my %sample_reads_count;
	my $index_distribution_html = "";
	my @childs;
	foreach my $sample_dir (@samples){
		my $pid = fork();
		if ($pid){
			push @childs, $pid;
		}
		elsif ($pid == 0){
			chomp $sample_dir;
			my @a = split("/",$sample_dir);
			my $sample = pop @a;
			print $sample."\n";
			#$total_undtmt_reads_count = `/bin/zcat $fastq_dir/$run_name/Undetermined_*_R1_*.fastq.gz | /bin/grep \@ | /usr/bin/wc -l`;
			my $reads_count = `/bin/zcat $sample_dir/*_R1_*.fastq.gz | /bin/grep \@ | /usr/bin/wc -l`;
			my $count_file = "$log_dir/$sample\_$run_id\_count";
			open (my $out, ">",$count_file);
			print $out $reads_count;
			close $out;
			exit;
		}
		else{
			die " !!! couldn't fork: $!\n";
		}
	}
	foreach (@childs){
		my $tmp = waitpid($_,0);
		warn "Done with pid $tmp\n";
	}
	
	my @count_files = `ls $log_dir/*\_$run_id\_count`;
	foreach my $count_file(@count_files){
		chomp $count_file;
		my $sample = $count_file;
		$sample =~s/^$log_dir\///;
		$sample =~s/\_$run_id\_count$//;
		my $count = `cat $count_file`;
		$sample_reads_count{$sample} = $count;
		$total_reads_count += $count;
		unlink $count_file;
	}
	$total_reads_count += $total_undtmt_reads_count;
	$index_distribution_html = "<p> <h2>Reads by Sample</h2>\n<table border=\"1\">\n<tr><th>Sample</th><th>PF Clusters</th><th>% of the sample</th></tr>\n";
	foreach my $key (keys %sample_reads_count){
		my $display_count = $sample_reads_count{$key};
		$display_count =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
		$index_distribution_html .= "<tr><td>$key</td><td>$display_count</td><td>".nearest(.01,($sample_reads_count{$key}/$total_reads_count*100))."</td></tr>\n";
	}
	my $display_count = $total_undtmt_reads_count;
	$display_count =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
	$index_distribution_html .= "<tr><td>Undetermined Reads</td><td>$display_count</td><td>".nearest(.01,($total_undtmt_reads_count/$total_reads_count*100))."</td></tr>\n";
	$index_distribution_html .= "</table></p>\n";
	return $index_distribution_html;
}

