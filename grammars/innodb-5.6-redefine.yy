thread4:
	SET GLOBAL innodb_buffer_pool_dump_now = ON { sleep 3; '' } |
	SET GLOBAL innodb_buffer_pool_load_now = ON { sleep 3; '' } ;

