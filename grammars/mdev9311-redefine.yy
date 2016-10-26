thread2:
    query | query | query | query | query | query | query | query | query | 
    query | query | query | query | query | query | query | query | query | 
    query | query | query | query | query | query | query | query | query | 
    query | query | query | query | query | query | query | query | query | 
    query | query | query | query | query | query | query | query | query | 
    query | query | query | query | query | query | query | query | query | 
    SET GLOBAL innodb_buffer_pool_size = @@innodb_buffer_pool_chunk_size * _digit |
    SET GLOBAL innodb_buffer_pool_dump_now = ON | 
    SET GLOBAL innodb_buffer_pool_load_now = ON |
    SET GLOBAL innodb_buffer_pool_evict = ON | 
    SET GLOBAL innodb_buffer_pool_load_abort = ON
;

thread3:
    thread2;

