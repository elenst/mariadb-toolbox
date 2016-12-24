use strict;

my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

my ($trialnum,$old,$new,$oldver,$newver,$encryption,$compression,$pagesize,$result,$oldinno,$newinno);
my %output = ();
my $teststart= '999';
my $trialstart;

LINE:
while (<>) 
{  
#	$lineno = $.;
	if (eof) {
        # The last line might be not empty (no end of line at the end of the file)
        process_line($_);
        close (ARGV);
        if ($new =~ /10\.2\.?/ and $result eq 'SCHEMA_MISMATCH') {
            # There have been some "innocent" changes in SHOW CREATE output in 10.2,
            # so there will always be difference. We can ignore it
            $result='OK';
        }
        if ($trialnum =~ /trial(\d+)/) {
            $trialnum= $1;
        }
        if ($compression eq 'NONE') {
            $compression= '';
        }
        if ($trialstart lt $teststart) {
            $teststart= $trialstart;
        }
        $oldinno= fix_innodb($oldinno);
        $newinno= fix_innodb($newinno);
        $oldinno ||= 'default InnoDB';
        $newinno ||= 'default InnoDB';
        $output{$trialnum}= [ "$old ($oldver) ($oldinno)", "$new ($newver) ($newinno)", $encryption, $compression, $pagesize, $result ];
        $oldver= undef;
        $newver= undef;
        $result= undef;
        $encryption= undef;
        $compression= undef;
        $trialstart= undef;
        $oldinno= undef;
        $newinno= undef;
    }

    $trialnum= $ARGV;
    process_line($_);
}

sub fix_innodb {
    my $inno= shift;
    if ($inno =~ /ha_innodb/i) {
        return 'InnoDB plugin';
    } elsif ($inno =~ /ha_xtradb/i) {
        return 'XtraDB plugin';
    } elsif (!$inno) {
        return 'inbuilt InnoDB';
    }
}

sub process_line {
    if ($_ =~ /\# --basedir1=\/data\/bld\/([-\w\d\.]*)/) {
        $old= $1;
    } elsif ($_ =~ /\# --basedir2=\/data\/bld\/([-\w\d\.]*)/) {
        $new= $1;
    } elsif ($_ =~ /\# --mysqld=--loose-innodb-encrypt-tables/) {
        $encryption= 'ON';
    } elsif ($_ =~ /\# --mysqld=--loose-innodb-compression-algorithm=(\w*)/) {
        $compression= uc($1);
    } elsif ($_ =~ /\# --mysqld=--loose-innodb-page-size=([\dK]*)/) {
        $pagesize= $1;
    } elsif ($_ =~ /\# --mysqld1=--plugin-load-add=(ha_innodb|ha_xtradb)/i) {
        $oldinno= $1;
    } elsif ($_ =~ /\# --mysqld2=--plugin-load-add=(ha_innodb|ha_xtradb)/i) {
        $newinno= $1;
    } elsif ($_ =~ /^\#\s+(\S+).*?Copyright\s\(c\)/) {
        $trialstart= $1;
    } elsif ($_ =~ /will exit with exit status STATUS_(\w+)/) {
        $result= $1;
    } elsif ($_ =~ /MySQL Version: (.*)/) {
        if (defined $oldver) {
            $newver= $1;
        } else { 
            $oldver= $1;
        }
    }
   
}

$teststart =~ s/T/ /;
print "h2. $teststart\n";
print "|| trial || old server || new server || encryption || compression || pagesize || result ||\n";
foreach my $k (sort {$a <=> $b} keys %output) {
    print "| $k | " . join( ' | ', @{$output{$k}}) ." |\n";
}
