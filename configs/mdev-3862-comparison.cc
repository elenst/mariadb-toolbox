# MDEV-3862: Lift limitation for merging VIEWS with Subqueries in SELECT_LIST
# TODO-336: testing task

# This configuration is supposed to compare results of using MERGE views 
# on different versions. The redefining grammar converts queries into such views.
# Presumedly, a version before the patch won't be able to create a MERGE view 
# from a query of an interesting kind, thus converting it to UNDEFINED instead.

$combinations = [
    [
    '
        --no-mask
        --notnull
        --seed=time
        --threads=4
        --duration=600
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
	--validator=ResultsetComparator
        --mysqld1=--innodb_stats_sample_pages=256
        --mysqld2=--innodb_stats_sample_pages=256
        --mysqld1=--max_join_size=1000000
        --mysqld2=--max_join_size=1000000
        --mysqld1=--log-output=FILE
        --mysqld2=--log-output=FILE
	--redefine=/home/elenst/mariadb-toolbox/grammars/mdev-3862-comparison-redefine.yy
    '
    ], 
    [
        '--grammar=conf/optimizer/optimizer_subquery.yy',
        '--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
        '--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple.yy',
	'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy',
	'--grammar=conf/optimizer/updateable_views.yy',
    ], 
    [
        '--engine=MyISAM',
        '--engine=InnoDB',
	'--engine=Aria',
    ],
    [
        '--mysqld1=--join-cache-level=8 --mysqld2=--join-cache-level=8',
        ''
    ],
];
