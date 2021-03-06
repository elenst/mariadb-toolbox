$combinations = [
    [
    '
	--appverif
        --no-mask
        --seed=time
        --threads=4
        --duration=400
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
        --mysqld=--loose-max-statement-time=60
        --querytimeout=60
        --store-binaries
    '
    ],
    [
        '--grammar=conf/mariadb/optimizer_basic.yy --gendata=conf/mariadb/optimizer.zz --redefine=conf/mariadb/redefine_set_session_vars.yy',
        '--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
        '--grammar=conf/mariadb/oltp-readonly.yy --gendata=conf/mariadb/oltp.zz',
        '--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM --views=MERGE --mysqld1=--sql_mode=ONLY_FULL_GROUP_BY --mysqld2=--sql_mode=ONLY_FULL_GROUP_BY',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM --views=TEMPTABLE --notnull',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB --views=MERGE',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB --views=TEMPTABLE --mysqld1=--sql_mode=ONLY_FULL_GROUP_BY --mysqld2=--sql_mode=ONLY_FULL_GROUP_BY --notnull',
        '--grammar=conf/optimizer/optimizer_access_exp.yy --gendata=conf/optimizer/range_access.zz',
    ]
];

