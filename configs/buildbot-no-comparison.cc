$combinations = [
    [
    '
        --no-mask
        --seed=time
        --threads=5
        --duration=600
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
        --redefine=conf/mariadb/redefine_random_keys.yy
        --redefine=conf/mariadb/redefine_set_session_vars.yy
        --validators=TransformerNoComparator
        --transformers=ConvertSubqueriesToViews,DisableOptimizations,EnableOptimizations,ExecuteAsCTE,ExecuteAsInsertSelect,ExecuteAsPreparedThrice,ExecuteAsSelectItem,ExecuteAsUnion,ExecuteAsUpdateDelete,ExecuteAsView,NullIf,OrderBy,StraightJoin
    '
    ], 
    [
        '--grammar=conf/mariadb/optimizer_basic.yy --gendata=conf/mariadb/optimizer_basic.zz',
        '--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
        '--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM --notnull',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB --notnull',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB',
        '--grammar=conf/optimizer/updateable_views.yy --mysqld=--default-storage-engine=MyISAM --mysqld=--init-file='.getcwd().'/conf/optimizer/updateable_views.init',
        '--grammar=conf/optimizer/updateable_views.yy --mysqld=--default-storage-engine=InnoDB --mysqld=--init-file='.getcwd().'/conf/optimizer/updateable_views.init',
        '--grammar=conf/optimizer/optimizer_access_exp.yy --gendata=conf/optimizer/range_access.zz',
    ]
];

