CREATE DATABASE IF NOT EXISTS travis;
USE travis;

CREATE TABLE IF NOT EXISTS logs (
  build_id INT UNSIGNED,
  job_id SMALLINT UNSIGNED,
  trial_id TINYINT UNSIGNED,
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data` MEDIUMBLOB,
  command_line VARCHAR(8192),
  server_branch VARCHAR(32),
  server_revision VARCHAR(40),
  test_branch VARCHAR(32),
  test_revision VARCHAR(40),
  PRIMARY KEY (build_id, job_id, trial_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS datadirs (
  build_id INT UNSIGNED,
  job_id SMALLINT UNSIGNED,
  trial_id TINYINT UNSIGNED,
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data` LONGBLOB,
  command_line VARCHAR(8192),
  server_branch VARCHAR(32),
  server_revision VARCHAR(40),
  test_branch VARCHAR(32),
  test_revision VARCHAR(40),
  PRIMARY KEY (build_id, job_id, trial_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS coredumps (
  build_id INT UNSIGNED,
  job_id SMALLINT UNSIGNED,
  trial_id TINYINT UNSIGNED,
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data` LONGBLOB,
  command_line VARCHAR(8192),
  server_branch VARCHAR(32),
  server_revision VARCHAR(40),
  test_branch VARCHAR(32),
  test_revision VARCHAR(40),
  PRIMARY KEY (build_id, job_id, trial_id)
) ENGINE=InnoDB;

