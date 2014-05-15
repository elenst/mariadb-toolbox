mdev_extra_add_vcol:
	ALTER TABLE _table ADD COLUMN mdev_col_name mdev_col_type AS (ADDDATE( mdev_col_name, INTERVAL 1 DAY )) mdev_extra_vcol_type ;

mdev_extra_vcol_type:
	PERSISTENT | VIRTUAL ;

