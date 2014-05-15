# MDEV-3862: Lift limitation for merging VIEWS with Subqueries in SELECT_LIST
# TODO-336: testing task

# This grammar is supposed to be used for comparing results of selecting from MERGE views 
# on different versions. The grammar converts queries into such views.
# Presumedly, a version before the patch won't be able to create a MERGE view 
# from a query of an interesting kind, thus converting it to UNDEFINED instead.

mdev_thread_init:
	{ $count{$$} = 0; '' } ;

thread1_init:
	mdev_thread_init;

thread2_init:
	mdev_thread_init;

thread3_init:
	mdev_thread_init;

mdev_thread:
	{ $count{$$}++; '' } CREATE OR REPLACE ALGORITHM=MERGE VIEW mdev_view AS query ; mdev_explain SELECT * FROM mdev_view ;
thread1:
	mdev_thread;

thread2:
	mdev_thread;

thread3:
	mdev_thread;

mdev_view:
	{ 'mdev_view_'.abs($$).'_'.$count{$$} } ;


# We don't want EXPLAIN under view definition, 
# but we do want to run it for our query sometimes
explain_extended:
	;

mdev_explain:
	| | | | | | EXPLAIN | EXPLAIN EXTENDED ;


# Any other ORDER BY makes results unreliable

order_by_clause:
	ORDER BY total_order_by limit ;

