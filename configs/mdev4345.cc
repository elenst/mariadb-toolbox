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
        --mysqld1=--innodb_stats_sample_pages=256
        --mysqld1=--max_join_size=1000000
        --mysqld1=--log-output=FILE
	--mysqld2=--innodb_stats_sample_pages=256
	--mysqld2=--max_join_size=1000000
	--mysqld2=--log-output=FILE
	--mysqld1=--use_stat_tables=PREFERABLY
	--rows=2,10,20,100,500,0,1,50,200
    '
    ], 
    [
        '--grammar=conf/optimizer/optimizer_subquery.yy',
        '--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
	'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
	'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
	'--grammar=conf/optimizer/optimizer_no_subquery.yy',
	'--grammar=conf/optimizer/optimizer_access_exp.yy',
    ], 
    [
        '--mysqld1=--optimizer_selectivity_sampling_limit=100',
	'--mysqld1=--optimizer_selectivity_sampling_limit=1',
	'--mysqld1=--optimizer_selectivity_sampling_limit=0',
	'--mysqld1=--optimizer_selectivity_sampling_limit=50',
    ],
    [
        '--views=MERGE',
        '--views=TEMPTABLE',
    ],
    [
        '--engine=Aria',
        '--engine=MyISAM',
        '--engine=InnoDB'
    ],
    [
	'--mysqld1=--optimizer_use_condition_selectivity=5 --mysqld1=--histogram_size=100 --mysqld1=--histogram_type=DOUBLE_PREC_HB',
	'--mysqld1=--optimizer_use_condition_selectivity=5 --mysqld1=--histogram_size=50 --mysqld1=--histogram_type=SINGLE_PREC_HB'
    ],
];
