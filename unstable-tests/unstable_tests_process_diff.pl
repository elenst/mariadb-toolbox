#!/bin/perl

unless (-e 'mysql-test/unstable-tests') {
    print "ERROR: Wrong starting point, go to <basedir>\n";
    exit 1;
}

my $version= `cat VERSION`;
my @ver= $version =~ /=(\d+)/gs;
$version= join '.', @ver;

# file => change (modified, added, deleted, etc)
my %tests= ();
my %other= ();
my %processed= ();
my %orphans= ();
my $path;
while (<>)
{
    unless (/diff --git a\/(\S+)/) {
        next;
    }
    $path= $1;

    if ($path =~ /\.result$/ or $path =~ /^suite\/galera/ or $path =~ /^storage\/rocksdb/ or $path=~ /\/storage_engine\//) {
        next;
    }

    my $change=<>;
    if ($change =~ /^new file mode/) {
        $change= 'added';
    } elsif ($change =~ /^index/) {
        $change= 'modified';
    } elsif ($change =~ /^deleted file mode/) {
        $change= 'deleted';
    } else {
        die "Unknown change type: $change\n";
    }
    print "Processing $change path $path\n";

    process_path($path, $change);
}

print "\n\nTests:\n\n";
foreach my $f (sort keys %tests) {
    my $text= $tests{$f};
    $text =~ s/^(\w)//;
    $text = uc($1).$text;
    print "$f : $text in $version\n";
}

print "\n\nOther:\n\n";
foreach my $f (sort keys %other) {
    print "$f : $other{$f}\n";
}
print "\n";

print "\n\nNot found references for:\n\n";
foreach my $f (sort keys %orphans) {
    print $f,"\n";
}

sub process_path
{
    my ($path, $change)= @_;
    my $orig_path= $path;

    if ($path =~ /(.*?)(?:-master|-slave)?\.(?:opt|cnf)$/) {
        my $base= $1;
        if (-e "$base.test") {
            process_path("$base.test", "Configuration $change");
        } elsif (-e "$base.inc") {
            process_path("$base.inc", "Configuration for included file $change");
        } else {
            if ($change ne 'deleted') {
                print "Couldn't find where $path belongs to\n";
                $orphans{$path}=1;
            }
        }
        return;
    }

    my $plugin;
    if ($path =~ s/^(?:(?:storage|plugin)\/(\w+)\/)?mysql-test\///) {
        $plugin= $1;
    }
    $path =~ s/^suite\///;

    if ($path =~ /^(?:(?:storage|plugin)\/\w+\/mysql-test\/)?(?:extra|include)\/|\/(?:extra|include)\// or $path =~ /\.inc$/) {
        # Avoid loops
        return if $processed{$orig_path};
        # If include file was added or removed, there will be a change in the referencing file
        return if $change eq 'added' or $change eq 'deleted';
        $processed{$orig_path}= 1;
        my $files= `grep -rlE 'source.*$path' mysql-test/* storage/*/mysql-test/* plugin/*/mysql-test/*`;
        chomp $files;
#        # Drop the path and search for sourcing by name only
#        unless ($files) {
#            if ($path =~ /\/([^\/]+)$/) {
#                my $n= $1;
#                print "Searching for $n\n";
#                $files= `grep -rlE 'source.*$n' mysql-test/* storage/*/mysql-test/* plugin/*/mysql-test/*`;
#            }
#        }
        if ($files) {
            my @files= split /\n/, $files;
            foreach my $f (@files) {
                next if $f eq $orig_path;
                process_path($f, "Include file $change");
            }
        }
        else {
            print "Could not find any tests referencing include $path\n";
            $orphans{$path}= 1;
        }
        return;
    }

    if ($path =~ /(\S+)\/(\S+)\.(\S+)/) {
        my ($suite, $file, $ext) = ($1, $2, $3);
        $suite =~ s/\/t$//;
        if (defined $plugin) {
            # Checking whether the suite is an overlay
            if (-e "mysql-test/suite/$suite") {
                $suite=$suite.'-'.$plugin;
            }
        }
        if ($suite eq 't') {
            $suite= 'main';
        }
        if ($ext eq 'test') {
            $tests{"$suite.$file"}= $change unless exists $tests{"$suite.$file"} and $tests{"$suite.$file"} =~ /^(?:added|modified|deleted)$/i;
        } else {
            $other{$path}= $change;
        }
    } else {
        $other{$path}= $change;
    }

}
