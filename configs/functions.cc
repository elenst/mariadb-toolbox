# slave-skip-errors: 
# 1064 : MDEV-5462

$combinations = [
   [
   '
      --no-mask
      --seed=time
      --duration=600
      --queries=100M
      --mysqld=--log-output=FILE
      --grammar=conf/mariadb/functions.yy
      --reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
      --threads=6
      --rows=0,1,2,3,5,10,20,50,100
      --mysqld=--slow_query_log
      --mysqld=--slave-skip-errors=1064
   '], 
   [
      '--views=MERGE',
      '--views=TEMPTABLE'
   ], 
   [
      '--basedir=/home/elenst/bzr/5.5 --engine=Aria',
      '--basedir=/home/elenst/bzr/5.5 --engine=MyISAM',
      '--basedir=/home/elenst/bzr/5.5 --engine=InnoDB',
      '--basedir=/home/elenst/bzr/5.5 --engine=TokuDB --mysqld=--plugin-load=ha_tokudb.so',
      '--basedir=/home/elenst/bzr/10.0 --engine=Aria --use_gtid=current_pos --mysqld=--log_slow_verbosity=query_plan,explain --mysqld=--long_query_time=0.000001',
      '--basedir=/home/elenst/bzr/10.0 --engine=MyISAM --mysqld=--log_slow_verbosity=query_plan,explain --mysqld=--long_query_time=0.000001',
      '--basedir=/home/elenst/bzr/10.0 --engine=InnoDB --use_gtid=current_pos --mysqld=--log_slow_verbosity=query_plan,explain --mysqld=--long_query_time=0.000001',
      '--basedir=/home/elenst/bzr/10.0 --engine=TokuDB --mysqld=--plugin-load=ha_tokudb.so --use_gtid=current_pos --mysqld=--log_slow_verbosity=query_plan,explain --mysqld=--long_query_time=0.000001'
   ],
   [
      '',
      '--rpl_mode=MIXED',
      '--rpl_mode=ROW'
   ],
   [
      '', 
      '--mysqld=--query_cache_size=64M'
   ]
];

