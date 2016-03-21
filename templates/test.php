<?php

$pid=pcntl_fork();

// connect to database
$conn=mysql_connect('127.0.0.1:3306','root');

// create an Aria table
mysql_query("DROP DATABASE IF EXISTS mdev6817");
mysql_query("CREATE DATABASE mdev6817");
mysql_select_db('mdev6817');
mysql_query("CREATE TABLE IF NOT EXISTS t1 (id INT NOT NULL DEFAULT '0', PRIMARY KEY (id)) ENGINE=Aria");

// enable query cache
mysql_query("SET GLOBAL query_cache_type = 1");
mysql_query("SET GLOBAL query_cache_size = 1024*1024*256");

// this is just for further logging
$con_id=mysql_result(mysql_query("SELECT CONNECTION_ID()"),0,0);

// $counter will count sequential SELECT MAX() queries executed after the last successful INSERT 
$counter=0;

// and start a infinite loop
while(1){
		$SQL=	"SELECT MAX(id) FROM t1";
		$tmp_tbl=mysql_query($SQL);
		$id=mysql_result($tmp_tbl,0,0);
		mysql_free_result($tmp_tbl);
		// 1000 is for throttling
		if($counter%1000==0 && $counter>1000) {
			echo "Connection $con_id: Executed $counter 'SELECT MAX(id)...' queries, result is $id\n";
		}
		$id++; 
		// probably to avoid overflow? It was like that in the initial test, keeping as is
		if($id<=0) $id=1;

		$SQL=	"INSERT INTO t1 VALUES ($id)";
		$ok=mysql_query($SQL); /* autocommit = 1 */
		
		if($ok){
			echo "Connection $con_id: Successfully inserted id=$id\n";
			$counter=0;
			continue;
		}
		$counter++;
		usleep(500); // wait a bit...
}

