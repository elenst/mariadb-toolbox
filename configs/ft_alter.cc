# Copyright (C) 2013 Monty Program Ab
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#		--mysqld=--innodb_ft_aux_table=test/table100_innodb_int_autoinc 

$combinations = [
	['
		--no-mask
		--seed=time
		--duration=300
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--engine=InnoDB
		--mysqld=--innodb_lock_wait_timeout=2
		--mysqld=--lock_wait_timeout=5
		--mysqld=--log_output=FILE
		--grammar=conf/mariadb/ft_alter.yy
		--gendata=conf/mariadb/ft_alter.zz
	'], 
	[
		'--mysqld=--innodb_file_format=Barracuda --mysqld=--innodb_file_per_table=1',
	],
	[
		'
		--mysqld=--innodb_ft_cache_size=0 
		--mysqld=--innodb_ft_enable_diag_print=1 
		--mysqld=--innodb_ft_enable_stopword=0
		--mysqld=--innodb_ft_max_token_size=10
		--mysqld=--innodb_ft_min_token_size=0
		--mysqld=--innodb_ft_num_word_optimize=1
		--mysqld=--innodb_ft_sort_pll_degree=1
		',
	],
	[
		'--threads=1',
	]
];

