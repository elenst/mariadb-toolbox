#!/usr/bin/perl

use strict;

# The argument is stdout.log

my %signatures= (
    'MDEV-21288' => [
        'innodb.full_crc32_import',
        "Variable 'innodb_compression_algorithm' can't be set to the value of",
    ],
    'MDEV-21336' => [
        '.*',
        'blocks are still reachable in loss record',
        'operator new',
        'pfs_rw_lock_create_func',
    ],
    'MDEV-21344' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'dict_table_open_on_id',
        'row_purge',
    ],
    'MDEV-21378' => [
        'connect.pivot',
        'MYSQLtoPLG',
        'connect_assisted_discovery'
    ],
    'MDEV-21379' => [
        'main.func_gconcat',
        'Invalid read of size',
        'tree_insert',
        'copy_to_tree',
        'tree_walk_left_root_right',
    ],
    'MDEV-21380' => [
        'innodb.doublewrite',
        'Failing assertion: block->page.space == page_get_space_id'
    ],
    'MENT-551' => [
        'plugins.server_audit2_client',
        '-TIME',
        '+TIME',
    ],
    'MDEV-21490' => [
        'binlog.*',
        'Conditional jump or move depends on uninitialised value',
        'sql_ex_info::init',
    ],
    'MDEV-15284' => [
        'innodb_gis.rtree_concurrent_srch',
        'select count',
        'mysqltest: Result content mismatch',
    ],
    'MDEV-21495' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'sel_arg_range_seq_next',
    ],
);

unless ($ARGV[0]) {
    print "ERROR: Usage: $0 <path to stdout.log>\n";
    exit 1;
}

unless (-e $ARGV[0]) {
    print "ERROR: $ARGV[0] does not exist\n";
    exit 1;
}

my %failed_tests= ();

while (<>)
{
    # 1st match is test name, 2nd (optional) is combination
    next unless /^(\S+)\s+(?:(\'[^']+\')\s+)?(?:w\d+\s+)?\[ fail \]/;
    my $test_name= $1;
    $failed_tests{$test_name}= $2;
    my $test_output= '';
    while (<>) {
        last if (/\[ (?:pass|fail|retry)|--------------------------------------/);
        $test_output.= $_;
    }
    my @matches= ();
    SIGNATURE:
    foreach my $jira (keys %signatures) {
        my @signature_lines= @{$signatures{$jira}};
        my $test_name_pattern= shift @signature_lines;
        next unless $test_name =~ /$test_name_pattern/;
        foreach my $s (@signature_lines) {
            next SIGNATURE unless $test_output =~ /$s/is;
        }
        push @matches, $jira;
    }
    if (scalar @matches) {
        foreach my $jira (@matches) {
            print "\"$test_name\" \"$jira\" \"$jira\" \"strong\"\n";
        }
    }
    else {
        print "\"$test_name\" \"\" \"\" \"no_match\"\n";
    }
}

