$combinations = [

# Common options
#        --mysqld=--log-bin
#        --mysqld=--binlog-format=ROW
    ['
        --no-mask
        --seed=time
        --threads=4
        --queries=100M
        --mysqld=--loose-max-statement-time=20
        --mysqld=--loose-lock-wait-timeout=20
        --mysqld=--innodb-lock-wait-timeout=10
        --mysqld=--server-id=111
        --grammar=conf/mariadb/oltp.yy
        --gendata=conf/mariadb/innodb_upgrade.zz
        --gendata-advanced
    '],
#        '--upgrade-test=crash --duration=60'
    [
        '--upgrade-test=normal --duration=60',
        '--upgrade-test=undo --duration=200'
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
