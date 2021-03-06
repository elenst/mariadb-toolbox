#!/usr/bin/perl

use strict;

# The argument is stdout.log

my %signatures= (
    'MDEV-18925' => [
        '.*',
        'Invalid read of size',
        'Item_exists_subselect::is_top_level_item',
        'Item_in_optimizer::eval_not_null_tables',
    ],
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
        'innodb_gis.rtree_.*',
        'select count',
        'mysqltest: Result content mismatch',
    ],
    'MDEV-21495' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'sel_arg_range_seq_next',
    ],
    'MDEV-21541' => [
        'main.sum_distinct-big',
        'm_buffer_end == __null',
        'Merge_chunk::set_buffer_end',
    ],
    'MDEV-21542' => [
        'main.order_by_pack_big',
        'Result content mismatch',
    ],
    'MDEV-21403' => [
        'mariabackup.mdev-14447',
        'recv_sys.mlog_checkpoint_lsn <= recv_sys.recovered_lsn',
    ],
    'MDEV-21788' => [
        'mariabackup.*',
        'blocks are definitely lost in loss record',
        'TLS wrapper function for rocksdb::perf_context',
    ],
    'MDEV-22071' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'Binary_string::c_ptr',
        'Field_geom::store',
    ],
    'MDEV-22146' => [
        'federated.federated_server',
        'ALTER SERVER',
        'mysql_ha_flush_tables',
    ],
    'MDEV-22147' => [
        'main.mysqldump',
        'Input filename too long',
    ],
    'MDEV-22244' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'Field::error_generated_column_function_is_not_allowed',
    ],
    'MDEV-22245' => [
        'type_inet.type_inet6',
        'Conditional jump or move depends on uninitialised value',
        'sortlength',
        'create_sort_index',
    ],
    'MDEV-22251' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'get_key_scans_params',
        'get_best_disjunct_quick',
    ],
    'MDEV-22252' => [
        'sys_vars.session_track_system_variables_basic',
        'Conditional jump or move depends on uninitialised value',
        'Session_sysvars_tracker::vars_list::construct_var_list',
    ],
    'MDEV-22253' => [
        '.*',
        'Conditional jump or move depends on uninitialised value',
        'best_access_path',
        'best_extension_by_limited_search',
    ],
    'MDEV-22254' => [
        'main.invisible_field_.*',
        'points to uninitialised byte',
        'inline_mysql_file_write',
        'writefrm',
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

