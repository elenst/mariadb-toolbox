use strict;

my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

my ($trialnum,$result,$type);
my %output = ();
my $teststart= '999';
my $trialstart;
my %old_opts = ();
my %new_opts = ();

LINE:
while (<>) 
{  
    my $line= $_;
    chomp $line;
    if ($line =~ /^\#\s+(\S+).*?Copyright\s\(c\)/) {
        $trialstart= $1;
    }
    elsif ($line =~ /will exit with exit status STATUS_(\w+)/) {
        $result= $1;
    }
    elsif ($line =~ /\#\s+--upgrade[-_]test=(\w+)/) {
        $type= lc($1);
    }
    elsif ($line =~ /-- Old server info: --/) {
        while ($line = <> and $line !~ /-- New server info: --/) {
            process_line($line,\%old_opts);
        }
        while ($line = <> and $line !~ /----------------------/) {
            process_line($line,\%new_opts);
        };

        if ($new_opts{version} =~ /10\.2\.?/ and $result eq 'SCHEMA_MISMATCH') {
            # There have been some "innocent" changes in SHOW CREATE output in 10.2,
            # so there will always be difference. We can ignore it
            $result='OK';
        }
    }
	if (eof) {
        $trialnum= $ARGV;
        close (ARGV);
        print STDERR "HERE:2: $trialnum: $result\n";
        if ($trialnum =~ /trial(\d+)/) {
            $trialnum= $1;
        }
        if ($trialstart lt $teststart) {
            $teststart= $trialstart;
        }
        fix_innodb(\%old_opts);
        fix_innodb(\%new_opts);
        fix_compression(\%old_opts);
        fix_compression(\%new_opts);
        fix_encryption(\%old_opts);
        fix_encryption(\%new_opts);
        fix_readonly(\%new_opts);
        
        $output{$trialnum}= [ '{color:gray}'.$type.'{color}', '{color:blue}*'.$new_opts{pagesize}.'*{color}', "$old_opts{version} ($old_opts{innodb})", $old_opts{encryption}, $old_opts{compression}, '{color:gray}*=>*{color}', "$new_opts{version} ($new_opts{innodb})", $new_opts{encryption}, $new_opts{compression}, $new_opts{innodb_read_only}, ( $result eq 'OK' ? ('OK', '') : ('{color:red}FAIL{color}', $result)) ];
        %old_opts = ();
        %new_opts = ();
        $type= 'normal';
        $result= '';
    }
}

sub fix_innodb {
    my $opts= shift;
    if ($opts->{innodb} =~ /ha_innodb/i) {
        $opts->{innodb} = 'InnoDB plugin';
    } elsif ($opts->{innodb} =~ /ha_xtradb/i) {
        $opts->{innodb} =  'XtraDB plugin';
    } elsif (!$opts->{innodb}) {
#        $opts->{innodb} = (($opts->{version} =~ /(?:10\.2\.|5\.[67]\.)/) ? 'inbuilt InnoDB' : 'inbuilt XtraDB');
        $opts->{innodb} = 'inbuilt';
    }
}

sub fix_compression {
    my $opts= shift;
    if (!$opts->{compression} or $opts->{compression} =~ /none/i) {
        $opts->{compression}= '\-';
    } else {
        $opts->{compression}= lc($opts->{compression});
    }
}

sub fix_encryption {
    my $opts= shift;
    if (not defined $opts->{encryption} or $opts->{encryption} =~ /(?:0|no|off)/i) {
        $opts->{encryption}= '\-';
    } else {
        $opts->{encryption}= 'on';
    }
}

sub fix_readonly {
    my $opts= shift;
    if (not defined $opts->{innodb_read_only} or $opts->{innodb_read_only} =~ /(?:0|no|off)/i) {
        $opts->{innodb_read_only}= '\-';
    } else {
        $opts->{innodb_read_only}= 'on';
    }
}

sub process_line {
    my ($l, $opts) = @_;
    if ($l =~ /\s(\d+\.\d+\.\d+)\s*$/s) {
        $opts->{version}= $1;
    } elsif ($l =~ /[-_]innodb[-_]encrypt[-_]tables(?:=on|=1|=0)?/i) {
        $opts->{encryption}= ( defined $1 ? $1 : '');
    } elsif ($l =~ /[-_]innodb[-_]compression[-_]algorithm=(\w*)/) {
        $opts->{compression}= $1;
    } elsif ($l =~ /[-_]innodb[-_]page[-_]size=(\d+)/) {
        $opts->{pagesize}= $1;
    } elsif ($l =~ /[-_]plugin[-_]load[-_]add=(ha_innodb|ha_xtradb)/i) {
        $opts->{innodb}= $1;
    } elsif ($l =~ /[-_]innodb[-_]read[-_]only(?:=on|=1|=0)/i) {
        $opts->{innodb_read_only}= ( defined $1 ? $1 : '' );
    }
}

$teststart =~ s/T/ /;
print "h2. $teststart\n";
print "|| trial || type || pagesize || OLD version || encrypted || compressed || || NEW version || encrypted || compressed || readonly || result || notes ||\n";
foreach my $k (sort {$a <=> $b} keys %output) {
    print "| $k | " . join( ' | ', @{$output{$k}}) ." |\n";
}
