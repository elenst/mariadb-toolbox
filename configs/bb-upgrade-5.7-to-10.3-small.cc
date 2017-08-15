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
        --gendata=conf/mariadb/innodb_upgrade.zz
        --gendata-advanced
    '],
#        '--upgrade-test=crash'
    [
        '--upgrade-test=normal',
        '--upgrade-test=undo'
    ],
# Old servers
    [
        '--basedir1=$BUILD_HOME/mysql-5.7',
    ],
# New servers
    [
        '--basedir2=$BUILD_HOME/build',
    ],

# Page size combinations
    [
        '--mysqld=--loose-innodb-page-size=16K',
        '--mysqld=--loose-innodb-page-size=8K',
        '--mysqld=--loose-innodb-page-size=4K',
        '--mysqld=--innodb-page-size=32K',
        '--mysqld=--innodb-page-size=64K',
    ],

# Encryption combinations
# - new server is unencrypted and don't have the plugin;
# - new server is encrypted and has the plugin;

    [
        '',
        '
            --mysqld2=--file-key-management
            --mysqld2=--file-key-management-filename=$BUILD_HOME/encryption_keys.txt
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
