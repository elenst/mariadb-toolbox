$combinations = [

# Common options
    ['
        --upgrade-test
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
# Old servers
    [
        '--basedir1=$BUILD_HOME/10.1',
        '--basedir1=$BUILD_HOME/10.1 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb',
        '--basedir1=$BUILD_HOME/10.1.10',
        '--basedir1=$BUILD_HOME/10.1.10 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb',
    ],
# New servers
    [
        '--basedir2=$BUILD_HOME/build',
        '--basedir2=$BUILD_HOME/build --mysqld2=--ignore-builtin-innodb --mysqld2=--plugin-load-add=ha_innodb',
    ],

# Page size combinations
    [
        '--mysqld=--innodb-page-size=16K',
        '--mysqld=--innodb-page-size=8K',
        '--mysqld=--innodb-page-size=4K'
        '--mysqld=--innodb-page-size=32K',
        '--mysqld=--innodb-page-size=64K',
    ],

# Compression combinations
# (Other possible values: lz4 lzo lzma bzip2 snappy)
    [
        '--mysqld=--innodb-compression-algorithm=none',
        '--mysqld=--innodb-compression-algorithm=zlib',
        '--mysqld1=--innodb-compression-algorithm=none --mysqld2=--innodb-compression-algorithm=zlib',
        '--mysqld1=--innodb-compression-algorithm=zlib --mysqld2=--innodb-compression-algorithm=none',
    ],
# Encryption combinations
# - both old and new server are unencrypted and don't have the plugin;
# - old server is unencrypted and does not have the plugin, the new server is encrypted and has the plugin;
# - both old and new server are encrypted and have the plugin;
# - old server is encrypted and has the plugin, new server is unencrypted but has the plugin (so it can decrypt);
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
        ',
        '
            --mysqld=--file-key-management
            --mysqld=--file-key-management-filename=/data/encryption_keys.txt
            --mysqld=--plugin-load-add=file_key_management.so
            --mysqld=--innodb-encrypt-tables
            --mysqld=--innodb-encrypt-log
            --mysqld=--innodb-encryption-threads=4
            --mysqld=--aria-encrypt-tables=1
            --mysqld=--encrypt-tmp-disk-tables=1
            --mysqld=--encrypt-binlog
        ',
        '
            --mysqld=--file-key-management
            --mysqld=--file-key-management-filename=/data/encryption_keys.txt
            --mysqld=--plugin-load-add=file_key_management.so
            --mysqld1=--innodb-encrypt-tables
            --mysqld1=--innodb-encrypt-log
            --mysqld1=--innodb-encryption-threads=4
            --mysqld1=--aria-encrypt-tables=1
            --mysqld1=--encrypt-tmp-disk-tables=1
            --mysqld1=--encrypt-binlog
        ',
    ],

]
