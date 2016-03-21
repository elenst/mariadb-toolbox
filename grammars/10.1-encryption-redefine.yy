thread2:
	encrypt_table | encrypt_table | encrypt_table | set_encrypt_option |
	query | query
;

encrypt_table:
	ALTER TABLE _basetable encrypt_yes_no encryption_key ;

encrypt_yes_no:
	| | | ENCRYPTED=YES | ENCRYPTED=NO ;

encrypt_on_off:
	ON | OFF ;

encryption_key:
	| | | ENCRYPTION_KEY_ID = _digit;

set_encrypt_option:
	SET GLOBAL aria_encrypt_tables = encrypt_on_off |
	SET GLOBAL encrypt_tmp_disk_tables = encrypt_on_off |
	SET GLOBAL innodb_default_encryption_key_id = _digit |
	SET GLOBAL innodb_encrypt_tables = enc_tables |
	SET GLOBAL innodb_encryption_rotate_key_age = _smallint_unsigned |
	SET GLOBAL innodb_encryption_rotation_iops = _smallint_unsigned |
	SET GLOBAL innodb_encryption_threads = _digit |
	SET GLOBAL innodb_immediate_scrub_data_uncompressed = encrypt_on_off |
	SET GLOBAL innodb_scrub_log_interval = _smallint_unsigned |
	SET GLOBAL innodb_scrub_log_speed = _smallint_unsigned 
;

enc_tables:
	'ON' | 'OFF' | 'FORCE' ;

