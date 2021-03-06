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
# Crash upgrade from pre-10.2 to 10.2+ is not supported
    [
        '--upgrade-test=normal --duration=60',
        '--upgrade-test=undo --duration=200',
    ],

# Page size combinations
    [
        '--mysqld=--innodb-page-size=16K',
        '--mysqld=--innodb-page-size=8K',
        '--mysqld=--innodb-page-size=4K',
        '--mysqld=--innodb-page-size=32K',
        '--mysqld=--innodb-page-size=64K',
    ],

# Compression combinations
# (Other possible values: lz4 lzo lzma bzip2 snappy)
    [
        '--mysqld=--innodb-compression-algorithm=none',
        '--mysqld=--innodb-compression-algorithm=zlib',
    ],
# Encryption combinations
# - both old and new server are unencrypted and don't have the plugin;
# - old server is unencrypted and does not have the plugin, the new server is encrypted and has the plugin;
# - both old and new server are encrypted and have the plugin;
# - old server is encrypted and has the plugin, new server is unencrypted but has the plugin (so it can decrypt);
    [
        '',
        '
            --mysqld=--file-key-management
            --mysqld=--file-key-management-filename=$BUILD_HOME/encryption_keys.txt
            --mysqld=--plugin-load-add=file_key_management.so
            --mysqld=--innodb-encrypt-tables
            --mysqld=--innodb-encrypt-log
            --mysqld=--innodb-encryption-threads=4
            --mysqld=--aria-encrypt-tables=1
            --mysqld=--encrypt-tmp-disk-tables=1
            --mysqld=--encrypt-binlog
        ',
    ],
    [
        '--mysqld1=--innodb-file-format=Antelope',
        '--mysqld1=--innodb-file-format=Barracuda'
    ]
]
