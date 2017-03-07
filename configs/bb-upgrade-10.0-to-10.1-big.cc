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
        '--basedir1=$BUILD_HOME/10.0 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb',
        '--basedir1=$BUILD_HOME/10.0.10',
        '--basedir1=$BUILD_HOME/10.0.10 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb',
    ],
# New servers
    [
        '--basedir2=$BUILD_HOME/build',
        '--basedir2=$BUILD_HOME/build --mysqld2=--ignore-builtin-innodb --mysqld2=--plugin-load-add=ha_innodb',
    ],

# Page size combinations
# (32K and 64K values are only applicable to 10.1+ and MySQL 5.7, so they are not present here)
    [
        '--mysqld=--loose-innodb-page-size=16K',
        '--mysqld=--loose-innodb-page-size=8K',
        '--mysqld=--loose-innodb-page-size=4K'
    ],

# Compression combinations are only applicable to 10.1+, so they are not present here

# Encryption combinations
# - both old and new server are unencrypted and don't have the plugin;
# - old server is unencrypted and does not have the plugin, the new server is encrypted and has the plugin;
# Other encryption combinations are only applicable to 10.1+, so they are not present here

    [
        '',
        '
            --mysqld2=--file-key-management
            --mysqld2=--file-key-management-filename=/data/encryption_keys.txt
            --mysqld2=--plugin-load-add=file_key_management.so
            --mysqld2=--innodb-encrypt-tables
            --mysqld2=--innodb-encrypt-log
            --mysqld2=--innodb-encryption-threads=4
            --mysqld2=--aria-encrypt-tables=1
            --mysqld2=--encrypt-tmp-disk-tables=1
            --mysqld2=--encrypt-binlog
        '
    ],

]