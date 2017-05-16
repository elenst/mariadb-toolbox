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
        --transformers=ConvertSubqueriesToViews,DisableOptimizations,EnableOptimizations,ExecuteAsCTE,ExecuteAsInsertSelect,ExecuteAsPreparedOnce,ExecuteAsSelectItem,ExecuteAsUnion,ExecuteAsUpdateDelete,ExecuteAsView,NullIf,OrderBy,StraightJoin,ExecuteAsExecuteImmediate
    '
    ],
    [
        '--grammar=conf/mariadb/optimizer_basic.yy --gendata=conf/mariadb/optimizer_basic.zz',
        '--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
        '--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
        '--grammar=conf/runtime/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz',
        '--grammar=conf/runtime/metadata_stability.yy --gendata=conf/runtime/metadata_stability.zz',
        '--grammar=conf/runtime/alter_online.yy --gendata=conf/runtime/alter_online.zz',
        '--grammar=conf/runtime/concurrency_1.yy --gendata=conf/runtime/concurrency_1.zz',
        '--grammar=conf/temporal/temporal_functions.yy --gendata=conf/temporal/temporal_functions.zz',
        '--grammar=conf/temporal/temporal_ranges.yy --gendata=conf/temporal/temporal_ranges.zz',
        '--grammar=conf/runtime/performance_schema.yy --mysqld=--performance-schema',
        '--grammar=conf/mariadb/functions.yy',
        '--grammar=conf/mariadb/oltp-transactional.yy --gendata=conf/mariadb/oltp.zz',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM --notnull',
        '--grammar=conf/mariadb/optimizer.yy --engine=MyISAM',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB --notnull',
        '--grammar=conf/mariadb/optimizer.yy --engine=InnoDB',
        '--grammar=conf/optimizer/updateable_views.yy --mysqld=--default-storage-engine=MyISAM --mysqld=--init-file='.getcwd().'/conf/optimizer/updateable_views.init',
        '--grammar=conf/optimizer/updateable_views.yy --mysqld=--default-storage-engine=InnoDB --mysqld=--init-file='.getcwd().'/conf/optimizer/updateable_views.init',
        '--grammar=conf/optimizer/optimizer_access_exp.yy --gendata=conf/optimizer/range_access.zz',
    ]
];

# TODO: restore when MDEV-10504 is fixed
#        '--grammar=conf/runtime/information_schema.yy',
# ExecuteAsPreparedThrice has been disabled because of MDEV-9619, re-enable when fixed (if ever)

