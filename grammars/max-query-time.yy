#
# Redefining grammar for max_query_time 
# General description: https://kb.askmonty.org/en/how-to-limittimeout-queries/#max_query_time-variable
# Testing task: TODO-361
#  


thread1:
	my_thread;

thread2:
	my_thread;

my_thread:
	set_max_query_time | query | query | query | query ;

set_max_query_time:
	SET scope max_query_time= { rand() * 10 } ;

scope:
	| SESSION | GLOBAL ;

