#!/bin/perl

use Getopt::Long;
use strict;

my ($mode, $help) = ('text', undef);

my $res = &GetOptions (
	"mode=s" => \$mode,
	"help" => \$help,
);

if ($help) {
    print "\nUsage:\n";
    print "perl $0 [--mode=<mode>] <RQG test output files>\n";
    print "\t--mode: jira|text|kb, default 'text'\n\n";
    exit 0;
}

$mode= lc($mode);
if ($mode ne 'jira' and $mode ne 'text' and $mode ne 'kb') {
    print "\nERROR: mode should be either 'jira' or 'text' or 'kb'\n";
    exit 1;
}

my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

my ($trialnum,$result,$type);
my %output= ();
my $teststart= '999';
my $trialstart;
my %old_opts= ();
my %new_opts= ();
my @known_bugs= ();
my @warnings;

my $exit_code= 0;

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
    elsif ($line =~/ Detected possible appearance of known bugs: (.*)/) {
        @known_bugs= split / /, $1;
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
        fix_result(\$result, \@known_bugs, \$trialnum, \%new_opts, \%old_opts);
        
        $exit_code= 1 if ($result ne 'OK' and $result ne 'KNOWN_BUGS');

        if ($mode eq 'jira') {
            $output{$trialnum}= [
                '{color:gray}'.$type.'{color}',
                '{color:blue}*'.$new_opts{pagesize}.'*{color}',
                "$old_opts{version} ($old_opts{innodb})",
                $old_opts{file_format},
                $old_opts{encryption},
                $old_opts{compression},
                '{color:gray}*=>*{color}',
                "$new_opts{version} ($new_opts{innodb})",
                $new_opts{file_format},
                $new_opts{encryption},
                $new_opts{compression},
                $new_opts{innodb_read_only},
                ( $result eq 'OK' ? 'OK' : '{color:red}FAIL{color}' ),
                ( $result eq 'OK' ? "@known_bugs" : "$result @known_bugs")
            ];
        } elsif ($mode eq 'kb') {
            $output{$trialnum}= [
                $type, $new_opts{pagesize},
                "$old_opts{version} ($old_opts{innodb})",
                $old_opts{file_format},
                $old_opts{encryption},
                $old_opts{compression},
                '=>',
                "$new_opts{version} ($new_opts{innodb})",
                $new_opts{file_format},
                $new_opts{encryption},
                $new_opts{compression},
                $new_opts{innodb_read_only},
                ( $result eq 'OK' ? 'OK' : '**FAIL**' ),
                ( $result eq 'OK' ? "@known_bugs" : "$result @known_bugs" )
            ];
        } elsif ($mode eq 'text') {
            $output{$trialnum}= [
                sprintf("%6s",$type),
                sprintf("%8d",$new_opts{pagesize}),
                sprintf("%25s","$old_opts{version} ($old_opts{innodb})"),
                sprintf("%11s",$old_opts{file_format}),
                sprintf("%9s",$old_opts{encryption}),
                sprintf("%10s",$old_opts{compression}),
                '=>',
                sprintf("%25s","$new_opts{version} ($new_opts{innodb})"),
                sprintf("%11s",$new_opts{file_format}),
                sprintf("%9s",$new_opts{encryption}),
                sprintf("%10s",$new_opts{compression}),
                sprintf("%8s",$new_opts{innodb_read_only}),
                sprintf("%6s", ($result eq 'OK' ? 'OK':'FAIL')),
                sprintf("%25s",( $result eq 'OK' ? "@known_bugs" : "$result @known_bugs"))
            ];
        }
        %old_opts = ();
        %new_opts = ();
        $type= 'normal';
        $result= '';
        @known_bugs= ();
    }
}

$teststart =~ s/T/ /;
if ($mode eq 'jira') {
    print "h2. $teststart\n";
    print "|| trial || type || pagesize || OLD version || file format || encrypted || compressed || || NEW version || file format || encrypted || compressed || readonly || result || notes ||\n";
} elsif ($mode eq 'kb') {
    print "=== Tested revision\n";
    print "//add revision link here//\n";
    print "=== Test date\n";
    print "$teststart\n";
    print "=== Summary\n";
    print "//add summary here//\n";
    print "=== Details\n";
    print '<<style class="darkheader-nospace-borders centered">>'."\n";

    print "|= # |= type |= pagesize |= OLD version |= file format |= encrypted |= compressed |= |= NEW version |= file format |= encrypted |= compressed |= readonly |= result |= notes |\n";
} elsif ($mode eq 'text') {
    print "Test date: $teststart\n";
    print "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
    print "| trial |   type | pagesize |               OLD version | file format | encrypted | compressed |    |               NEW version | file format | encrypted | compressed | readonly | result |                     notes |\n";
    print "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
}
foreach my $k (sort {$a <=> $b} keys %output) {
    if ($mode eq 'jira') {
        print "| $k | " . join( ' | ', @{$output{$k}}) ." |\n";
    }
    elsif ($mode eq 'kb') {
        print "| $k | " . join( ' | ', @{$output{$k}}) ." |\n";
    } elsif ($mode eq 'text') {
        print "| ".sprintf("%5d",$k)." | ". join( ' | ', @{$output{$k}}) ." |\n";
    }
}

if ($mode eq 'text') {
    print "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n";
} elsif ($mode eq 'kb') {
    print "<</style>>\n";
}

foreach (@warnings) {
    print $_;
}

exit $exit_code;

### SUBROUTINES

# If the result was STATUS_CUSTOM_OUTCOME, the upgrade test leaves it to the result parser
# to decide whether the detected known bugs should be raised as test failure or demoted to warnings
sub fix_result {
    my ($res, $known_bugs, $trial, $new_opts, $old_opts)= @_;
    return unless $$res eq 'CUSTOM_OUTCOME';
    my $warning_pattern= "WARNING: trial%i: Detected %i possible appearance(s) of MDEV-%i (%s)\n";
    foreach my $b (@$known_bugs) {
        my $jira= '';
        my $jira_subj= '';
        my $occurrences= 0;
        if ($b =~ /MDEV-(\d+)\((\d+)\)/) {
            $jira= $1;
            $occurrences= $2;
        }
        if ($jira == 13094) {
            $jira_subj= '(Wrong AUTO_INCREMENT value on the table after server restart)';
            if ($new_opts{version} =~ /10\.[23]\.?/) {
                push @warnings, sprintf($warning_pattern, $$trial, $occurrences, $jira, $jira_subj);
            } else {
                $$res= 'UPGRADE_FAILURE';
            }
        }
        elsif ($jira == 13112) {
            $jira_subj= 'InnoDB: Corruption: Page is marked as compressed but uncompress failed with error';
            if ($new_opts{version} =~ /10\.1\.?/ and $old_opts{version} =~ /10\.1\.?/) {
                push @warnings, sprintf($warning_pattern, $$trial, $occurrences, $jira, $jira_subj);
            } else {
                $$res= 'UPGRADE_FAILURE';
            }
        }
        elsif ($jira == 13103) {
            $jira_subj= 'Assertion `flags & BUF_PAGE_PRINT_NO_CRASH\' failed in buf_page_print';
            if ($old_opts{encryption} eq 'on' and $new_opts{version} =~ /10\.[23]\.?/) {
                push @warnings, sprintf($warning_pattern, $$trial, $occurrences, $jira, $jira_subj);
            } else {
                $$res= 'UPGRADE_FAILURE';
            }
        }
        elsif ($jira == 13101) {
            $jira_subj= 'Assertion `0 || offs == 0 + (38U + 36 + 2 * 10) + 0 ... 38U + 0 + 6` failed in recv_parse_or_apply_log_rec_body';
            if ($old_opts{encryption} eq 'on' and $old_opts{version} =~ /10\.[23]\.?/ and $new_opts{version} =~ /10\.[23]\.?/) {
                push @warnings, sprintf($warning_pattern, $$trial, $occurrences, $jira, $jira_subj);
            } else {
                $$res= 'UPGRADE_FAILURE';
            }
        }
        else {
            # Something new?
            $$res= 'UPGRADE_FAILURE';
        }
    }
    $$res= 'KNOWN_BUGS' if $$res eq 'CUSTOM_OUTCOME';
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
        $opts->{compression}= ($mode eq 'jira' ? '\-' : '-');
    } else {
        $opts->{compression}= lc($opts->{compression});
    }
}

sub fix_encryption {
    my $opts= shift;
    if (not defined $opts->{encryption} or $opts->{encryption} =~ /(?:0|no|off)/i) {
        $opts->{encryption}= ($mode eq 'jira' ? '\-' : '-');
    } else {
        $opts->{encryption}= 'on';
    }
}

sub fix_readonly {
    my $opts= shift;
    if (not defined $opts->{innodb_read_only} or $opts->{innodb_read_only} =~ /(?:0|no|off)/i) {
        $opts->{innodb_read_only}= ($mode eq 'jira' ? '\-' : '-');
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
    } elsif ($l =~ /[-_]innodb[-_]file[-_]format=(\w*)/) {
        $opts->{file_format}= $1;
    }
}
