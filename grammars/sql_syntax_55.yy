query:

    ddl | dml | txn_locking | replication | prepared_statements | 
    compound | administration | utility ;

ddl:

    alter | create | drop | rename | truncate ;

alter:

    alter_database | alter_event | alter_logfile_group | 
    alter_function | alter_procedure | alter_server | alter_table | 
    alter_tablespace | alter_view ;

create:

    create_database | create_event | create_function | create_index | 
    create_logfile_group | create_procedure | create_function | 
    create_server | create_table | create_tablespace | create_trigger | create_view ;

drop:

    drop_database | drop_event | drop_function | drop_index | 
    drop_logfile_group | drop_procedure | drop_function | drop_server | 
    drop_table | drop_tablespace | drop_trigger | drop_view ;


alter_database:

    ALTER database_schema db_name_or_nil alter_specification | 
    ALTER database_schema _db UPGRADE DATA DIRECTORY NAME ;
    
# TODO: Check if _db is resolved

db_name_or_nil:

    _db | ;
    
database_schema:

    DATABASE | SCHEMA ;

# TODO: find out how to resolve charset_name and collation_name
    
alter_specification:

    default_or_nil CHARACTER SET eq_or_nil charset_name |
    default_or_nil COLLATE eq_or_nil collation_name ;
    
eq_or_nil:

    = | ;
  
default_or_nil:

    DEFAULT | ;


# TODO: check if _event is resolved

alter_event:

    definer_or_nil EVENT _event schedule_or_nil completion_or_nil rename_or_nil enable_disable_or_nil comment_or_nil do_or_nil ;
    
definer_or_nil:

    DEFINER = _user | DEFINER = CURRENT_USER | ;
    
schedule_or_nil:

    ON SCHEDULE schedule | ;
    
completion_or_nil:

    ON COMPLETION not_or_nil PRESERVE | ;
    
not_or_nil:

    NOT | ;     
    
# TODO: check what to do with _name
rename_or_nil:

    RENAME TO _name | ;

enable_disable_or_nil:

    ENABLE | DISABLE | DISABLE ON SLAVE | ;
    
comment_or_nil:

    COMMENT '_varchar(1024)' | ;

do_or_nil:

    DO event_body | ;

# TODO    
event_body:
    ;

schedule:

    AT '_timestamp' plus_interval_or_nil |
    EVERY interval_with_quantity starts_or_nil ends_or_nil ;
    
plus_interval_or_nil:

    + INTERVAL interval_with_quantity | ;
    
interval_with_quantity:

    _tinyint interval ;
    
interval:

    YEAR | QUARTER | MONTH | DAY | HOUR | MINUTE |
    WEEK | SECOND | YEAR_MONTH | DAY_HOUR | DAY_MINUTE |
    DAY_SECOND | HOUR_MINUTE | HOUR_SECOND | MINUTE_SECOND ;
    
starts_or_nil:

    STARTS '_timestamp' plus_interval_or_nil ;
    
ends_or_nil:

    ENDS '_timestamp' plus_interval_or_nil ;

# TODO: dml 
# TODO: txn_locking
# TODO: replication
# TODO: prepared_statements
# TODO: compound
# TODO: administration
# TODO: utility
# TODO: rename
# TODO: truncate
# TODO: alter_event
# TODO: alter_logfile_group
# TODO: alter_function
# TODO: alter_procedure
# TODO: alter_server
# TODO: alter_table
# TODO: alter_tablespace
# TODO: alter_view
# TODO: create_database
# TODO: create_event
# TODO: create_function
# TODO: create_index
# TODO: create_logfile_group
# TODO: create_procedure
# TODO: create_function
# TODO: create_server
# TODO: create_table
# TODO: create_tablespace
# TODO: create_trigger
# TODO: create_view
# TODO: drop_database
# TODO: drop_event
# TODO: drop_function
# TODO: drop_index
# TODO: drop_logfile_group
# TODO: drop_procedure
# TODO: drop_function
# TODO: drop_server
# TODO: drop_table
# TODO: drop_tablespace
# TODO: drop_trigger
# TODO: drop_view
# TODO: charset_name
# TODO: collation_name

     