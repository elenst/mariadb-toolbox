# MDEV-3862: Lift limitation for merging VIEWS with Subqueries in SELECT_LIST
# TODO-336: testing task

$combinations = [
    [
    '
        --no-mask
        --notnull
        --seed=time
        --threads=4
        --duration=1200
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
	--validator=Transformer
	--transformers=ConvertLiteralsToSubqueries,ConvertSubqueriesToViews,ConvertTablesToViews,ConvertTablesToDerived,ExecuteAsView,InlineSubqueries,ExecuteAsDerived,ExecuteAsInsertSelect,ExecuteAsSelectItem,ExecuteAsUpdateDelete,ExecuteAsWhereSubquery,StraightJoin,ExecuteAsPreparedTwice
        --mysqld=--innodb_stats_sample_pages=256
        --mysqld=--max_join_size=1000000
        --mysqld=--log-output=FILE
	--views=MERGE
    '
    ], 
    [
        '--grammar=conf/optimizer/optimizer_subquery.yy',
        '--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
        '--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple.yy',
	'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
	'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
	'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy',
	'--grammar=conf/optimizer/outer_join.yy --gendata=conf/optimizer/outer_join.zz',
	'--grammar=conf/optimizer/updateable_views.yy',
	'--grammar=conf/optimizer/optimizer_no_subquery.yy',
	'--grammar=conf/optimizer/optimizer_access_exp.yy',
    ], 
    [
        '--engine=MyISAM',
        '--engine=InnoDB',
	'--engine=Aria',
    ],
];
