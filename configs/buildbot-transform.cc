$combinations = [
#        --appverif
    [
    '
        --no-mask
        --seed=time
        --threads=5
        --duration=400
        --queries=100M
        --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
        --redefine=conf/mariadb/redefine_random_keys.yy
        --redefine=conf/mariadb/redefine_set_session_vars.yy
        --validators=TransformerLight
        --transformers=ConvertSubqueriesToViews,DisableOptimizations,EnableOptimizations,ExecuteAsSelectItem,ExecuteAsView,ExecuteAsDerived
    '
    ],
    [
		'--grammar=conf/mariadb/optimizer.yy',
		'--grammar=conf/mariadb/optimizer.yy --notnull',
		'--grammar=conf/mariadb/optimizer.yy --skip-gendata --mysqld=--init-file=$RQG_HOME/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/outer_join.yy --gendata=conf/optimizer/outer_join.zz',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --notnull',
		'--grammar=conf/optimizer/optimizer_access_exp.yy',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --skip-gendata --mysqld=--init-file=$RQG_HOME/conf/mariadb/world.sql',
    ]
];

# TODO:
# ExecuteAsPreparedThrice has been disabled because of MDEV-9619, re-enable when fixed (if ever)

