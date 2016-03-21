$combinations = [
    [
    '
        --no-mask
        --notnull
        --seed=time
        --threads=4
        --duration=300
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
        --mysqld1=--innodb_stats_sample_pages=256
        --mysqld2=--innodb_stats_sample_pages=256
        --mysqld1=--max_join_size=1000000
        --mysqld2=--max_join_size=1000000
        --mysqld1=--character-set-server=latin1
        --mysqld2=--character-set-server=latin1
        --mysqld1=--collation-server=latin1_general_cs
        --mysqld2=--collation-server=latin1_general_cs
    '
    ], 
    [
        '--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
        '--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',

        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM',
        '--grammar=conf/optimizer/updateable_views.yy --engine=MyISAM',
        '--grammar=conf/optimizer/optimizer_access_exp.yy --engine=MyISAM',

        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB',
        '--grammar=conf/optimizer/updateable_views.yy --engine=InnoDB',
        '--grammar=conf/optimizer/optimizer_access_exp.yy --engine=InnoDB',
    ], 
    [
        '--views=MERGE',
        '--views=TEMPTABLE',
    ],
    [
        '--mysqld1=--sql_mode=ONLY_FULL_GROUP_BY --mysqld2=--sql_mode=ONLY_FULL_GROUP_BY',
        ''
    ]
];

