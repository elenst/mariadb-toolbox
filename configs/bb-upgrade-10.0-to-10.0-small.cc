$combinations = [

# Common options
    ['
        --no-mask
        --seed=time
        --threads=4
        --duration=60
        --queries=100M
        --mysqld=--loose-max-statement-time=20
        --mysqld=--loose-lock-wait-timeout=20
        --mysqld=--innodb-lock-wait-timeout=10
        --mysqld=--log-bin
        --mysqld=--binlog-format=ROW
        --mysqld=--server-id=111
        --grammar=conf/mariadb/oltp.yy
        --gendata=conf/mariadb/oltp.zz
        --gendata-advanced
    '],
    [
        '--upgrade-test=normal',
        '--upgrade-test=crash'
    ],
# Old servers
    [
        '--basedir1=$BUILD_HOME/10.0',
    ],
# New servers
    [
        '--basedir2=$BUILD_HOME/build',
    ],

# Page size combinations
# (32K and 64K values are only applicable to 10.1+ and MySQL 5.7, so they are not present here)
    [
        '--mysqld=--loose-innodb-page-size=16K',
        '--mysqld=--loose-innodb-page-size=8K',
        '--mysqld=--loose-innodb-page-size=4K'
    ],

# Compression combinations are only applicable to 10.1+, so they are not present here
# Encryption combinations are only applicable to 10.1+, so they are not present here
]
