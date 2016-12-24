$combinations = [
    ['
        --upgrade-test
        --no-mask
        --seed=time
        --threads=4
        --duration=120
        --queries=100M
        --mysqld=--loose-max-statement-time=20
        --mysqld=--loose-lock-wait-timeout=20
        --mysqld=--innodb-lock-wait-timeout=10
        --grammar=conf/mariadb/oltp.yy
        --basedir2=/data/bld/10.1
        --mysqld=--log-bin
        --mysqld=--binlog-format=ROW
        --mysqld=--server-id=111
        --gendata=conf/mariadb/oltp.zz
        --gendata-advanced
    '],
    [
        '',
        '
            --mysqld=--loose-plugin-load-add=file_key_management.so
            --mysqld=--loose-file-key-management
            --mysqld=--loose-file-key-management-filename=/data/encryption_keys.txt
            --mysqld=--loose-innodb-encrypt-tables
            --mysqld=--loose-innodb-encrypt-log
            --mysqld=--loose-innodb-encryption-threads=4
            --mysqld=--loose-aria-encrypt-tables=1
            --mysqld=--loose-encrypt-tmp-disk-tables=1
            --mysqld=--loose-encrypt-binlog
        '
    ],
#        '--mysqld=--loose-innodb-compression-algorithm=lz4', not installed
#        '--mysqld=--loose-innodb-compression-algorithm=lzo', not installed
#        '--mysqld=--loose-innodb-compression-algorithm=lzma', not installed
#        '--mysqld=--loose-innodb-compression-algorithm=bzip2', not installed
#        '--mysqld=--loose-innodb-compression-algorithm=snappy' not installed
    [
        '--mysqld=--loose-innodb-compression-algorithm=none',
        '--mysqld=--loose-innodb-compression-algorithm=zlib',
    ],

# the option only applicable to XtraDB 5+ and InnoDB 10.0+
# 32K and 64K only applicable to 10.1+ and MySQL 5.7
    [
        '--basedir1=/data/bld/10.0 --mysqld=--loose-innodb-page-size=16K',
        '--basedir1=/data/bld/10.0 --mysqld=--loose-innodb-page-size=8K',
        '--basedir1=/data/bld/10.0 --mysqld=--loose-innodb-page-size=4K',

        '--basedir1=/data/bld/10.0 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb --mysqld=--loose-innodb-page-size=16K',
        '--basedir1=/data/bld/10.0 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb --mysqld=--loose-innodb-page-size=8K',
        '--basedir1=/data/bld/10.0 --mysqld1=--ignore-builtin-innodb --mysqld1=--plugin-load-add=ha_innodb --mysqld=--loose-innodb-page-size=4K',

        '--basedir1=/data/bld/mysql-5.6 --mysqld=--loose-innodb-page-size=16K',
        '--basedir1=/data/bld/mysql-5.6 --mysqld=--loose-innodb-page-size=8K',
        '--basedir1=/data/bld/mysql-5.6 --mysqld=--loose-innodb-page-size=4K',
    ],

    [
        '',
        '--mysqld2=--ignore-builtin-innodb --mysqld2=--plugin-load-add=ha_innodb',
    ]

]
