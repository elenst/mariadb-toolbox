#
# RQG command line to run Cassandra tests (example)
#

perl ./runall-new.pl --gendata=cassandra.zz --grammar=cassandra-dynamic.yy --threads=2 --queries=100M  --reporters=Shutdown --mysqld=--cassandra-default-thrift-host=127.0.0.1 --duration=300 --mysqld=--use_stat_tables=PREFERABLY --basedir=/home/elenst/10.0-base-cassandra/ --vardir=/home/elenst/test_results/cassandra-1  2>&1 | tee ~/test_results/cassandra-1.log
