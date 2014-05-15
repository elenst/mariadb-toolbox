thread6:
	thread4 ;

thread5:
	thread4 ;

thread4:
	SET GLOBAL server_audit_events = audit_event_list |
	SET GLOBAL server_audit_excl_users = audit_user_list |
	SET GLOBAL server_audit_incl_users = audit_user_list |
	SET GLOBAL server_audit_file_path = audit_file_path |
	SET GLOBAL server_audit_file_rotate_now = audit_on_off |
	SET GLOBAL server_audit_file_rotate_size = _smallint_unsigned |
	SET GLOBAL server_audit_file_rotations = _tinyint_unsigned |
	SET GLOBAL server_audit_logging = audit_on_off |
# only 0 or 1 are allowed, but we'll let it be
	SET GLOBAL server_audit_mode = _digit |
	SET GLOBAL server_audit_output_type = audit_output_type |
	SET GLOBAL server_audit_syslog_facility = audit_syslog_facility |
	SET GLOBAL server_audit_syslog_ident = audit_syslog_ident |
	SET GLOBAL server_audit_syslog_info = audit_syslog_info |
	SET GLOBAL server_audit_syslog_priority = audit_syslog_prio |
	SHOW VARIABLES LIKE '%audit%' |
	SHOW STATUS LIKE '%audit%' ;

# 9 is invalid, but we'll let it be
audit_event_list:
	_digit | audit_event_symbolic_list ;

audit_event_symbolic_list:
	{ $size = int(rand(6)); @vals = ('QUERY','CONNECT','TABLE'); $ev_list = ''; foreach (1 .. $size) { $ev_list = $ev_list . $vals[int(rand(scalar @vals))]. ',' } ; chop $ev_list; "'".$ev_list."'" } ;

audit_user_list:
	{ $size = int(rand(50)); @vals = ('root','foo','bar','qux','foobar',''); $user_list = ''; foreach (1 .. $size) { $user_list = $user_list . $vals[int(rand(scalar @vals))]. ',' } ; chop $user_list; "'".$user_list."'" } ;

audit_file_path:
	'server_audit.log' | '/tmp/' | _letter | '/tmp/server_audit.log' | '/nonexisting/file' ;

audit_on_off:
	ON | OFF | 0 | 1 ;

audit_output_type:
	syslog | file | 0 | 1 ;

audit_syslog_facility:
# only up to 18 are allowed, but we'll let it be
	{ int(rand(20)) } | LOG_USER | LOG_MAIL | LOG_DAEMON | LOG_AUTH | LOG_SYSLOG | LOG_LPR | LOG_NEWS | LOG_UUCP | LOG_CRON | LOG_AUTHPRIV | LOG_FTP | LOG_LOCAL0 | LOG_LOCAL1 | LOG_LOCAL2 | LOG_LOCAL3 | LOG_LOCAL4 | LOG_LOCAL5 | LOG_LOCAL6 | LOG_LOCAL7 ;

audit_syslog_ident:
	'mysql-server_auditing' | '' | char(16) | char(64) ;

audit_syslog_info:
	'' | char(16) | char(64) ;

audit_syslog_prio:
# only up to 7 are allowed, but we'll let it be
	_digit | LOG_EMERG | LOG_ALERT | LOG_CRIT | LOG_ERR | LOG_WARNING | LOG_NOTICE | LOG_INFO | LOG_DEBUG ;


