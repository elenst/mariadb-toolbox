#!/usr/bin/perl

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

use lib 'lib';
use lib "$ENV{RQG_HOME}/lib";

use POSIX ":sys_wait_h";
use Getopt::Long qw( :config pass_through );
use GenTest::Constants;
use DBServer::DBServer;

use strict;

$| = 1;
if (osWindows()) {
	say("ERROR: This test flow is Linux-specific for now");
	exit STATUS_ENVIRONMENT_FAILURE;
}

my $opt_crashtest_mode = 'local';
my @opt_reporters;
my $opt_duration = 3600;
my $opt_build = 0;
my $opt_vm_port = 2201;
my $opt_vm_user = $ENV{USER};
my $opt_bzr_branch;
my $opt_base_vm = '/home/kvm/vms/mdev232.rqg.crash.test.qcow2';
my $opt_workdir = '$HOME';
my $opt_basedir;
my $opt_vardir;
my $opt_queries_after_recovery = '100M';

my $vm_pid;
my $cmd_prefix = '';
my @reporters;
my @reporters_with_Crash;
my @reporters_with_BinlogConsistency;

# If you want just pull and rebuild an existing tree (and RQG),
# set $opt_build, but don't set $opt_bzr_branch.
# If $opt_bzr_branch is set, the source tree will be fully rebranched
# and built from scratch

my $opt_result = GetOptions(
	'crashtest-mode=s' => \$opt_crashtest_mode,
	'crashtest_mode=s' => \$opt_crashtest_mode,
	'reporters=s@' => \@opt_reporters,
	'reporter=s@' => \@opt_reporters,
	'duration=i' => \$opt_duration,
	'build!' => \$opt_build,
	'vm-port=i' => \$opt_vm_port,
	'vm_port=i' => \$opt_vm_port,
	'vm-user=s' => \$opt_vm_user,
	'vm_user=s' => \$opt_vm_user,
	'bzr-branch=s' => \$opt_bzr_branch,
	'bzr_branch=s' => \$opt_bzr_branch,
	'base-vm=s' => \$opt_base_vm,
	'base_vm=s' => \$opt_base_vm,
	'workdir=s' => \$opt_workdir,
	'basedir=s' => \$opt_basedir,
	'vardir=s' => \$opt_vardir,
	'queries-after-recovery=s' => \$opt_queries_after_recovery,
	'queries_after_recovery=s' => \$opt_queries_after_recovery,
);


# Checking and adjusting options

unless ($opt_crashtest_mode eq 'local' || $opt_crashtest_mode eq 'vm') {
	say("ERROR: crashtest-mode should be either 'local' or 'vm'");
	exit STATUS_ENVIRONMENT_FAILURE;
}

# We just needed to know the duration of the test, for the vm mode
push @ARGV, "--duration=$opt_duration";

if ($opt_bzr_branch and ! $opt_basedir) {
	$opt_basedir = "$opt_workdir/$opt_bzr_branch";
}

if (!$opt_basedir) {
	say("ERROR: basedir is not defined");
	exit STATUS_ENVIRONMENT_FAILURE;
}

push @ARGV, "--basedir=$opt_basedir";

if (!$opt_vardir) {
	$opt_vardir = "$opt_workdir/crashtest_results_".time();
} else {
	$opt_vardir =~ s/[\\\/]$//;
}
push @ARGV, "--vardir=$opt_vardir";


foreach my $r (@opt_reporters) {
	my @rep = ($r =~ /,/ ? split /,/, $r : ($r));
	foreach (@rep) {
		next if $_ eq 'Crash' or $_ eq 'BinlogConsistency';
		push @reporters, "--reporter=$_";
	}
}

@reporters_with_Crash = (@reporters,'--reporter=Crash');
@reporters_with_BinlogConsistency = ('--reporter=BinlogConsistency',@reporters);


# In VM mode, we will need to SSH to the VM before running commands

if ($opt_crashtest_mode eq 'vm') {
	$cmd_prefix = 'ssh -p '.$opt_vm_port.' '.$opt_vm_user.'@localhost ';
}

# Preparation phase, part 1
# In case of VM mode, we need to start the VM

if ($opt_crashtest_mode eq 'vm') {

	start_vm($opt_base_vm,"$opt_workdir/crashtest.qcow2");
}

# Preparation phase, part 2
# If requested, we need to clone/pull trees and rebuild

if ($opt_build) {
	my $cmd = 'bzr pull -d $HOME/rqg && bzr pull -d $HOME/mariadb-toolbox';
	if ($opt_bzr_branch) {
		$cmd .= ' && rm -rf '.$opt_basedir.' && bzr branch lp:~maria-captains/maria/'.$opt_bzr_branch.' '.$opt_basedir;
	# TODO: Something is wrong here
	} else {
		$cmd .= ' && ( bzr pull -d '.$opt_basedir.' || bzr branch lp:~maria-captains/maria/'.$opt_bzr_branch.' '.$opt_basedir.' )';
	}
	$cmd .= ' && cd '.$opt_basedir.' && cmake . -DCMAKE_BUILD_TYPE=Debug && make';
	$cmd = $cmd_prefix.'"'.$cmd.'"';	

	say("Cloning trees and building the server: $cmd ...");
	my $status = system($cmd) >> 8;
	if ($status) {
		say("ERROR: bzr/build finished with status $status");
		kill(9, $vm_pid);
		exit $status;
	}
}

# Phase 1
# Test flow and server/VM crash 

say("############################");
say("Executing the first part of the test: clean server start, test flow + crash");
say("############################");

# In local mode we add Crash reporter to the flow, start RQG and wait till it crashes the server.
# In vm mode no need to use the Crash reporter. Instead, we start RQG and then crash the VM.

if ($opt_crashtest_mode eq 'local') {
	
	my $cmd = "perl runall-new.pl @ARGV @reporters_with_Crash";
	say("Running $cmd...");
	my $status = system($cmd) >> 8;
	# Crash reporter should return STATUS_SERVER_KILLED.
	# But currently RQG returns STATUS_OK, if the test finished with STATUS_SERVER_KILLED.
	# Also, it might probably happen that an executor would notice that the server was lost,
	#   and report STATUS_SERVER_CRASHED.
	# So, we will have all three variants here.
	unless ($status == STATUS_OK || $status == STATUS_SERVER_KILLED || $status == STATUS_SERVER_CRASHED ) {
		say("ERROR: the first part of the test finished with unexpected result, won't continue");
		exit STATUS_ENVIRONMENT_FAILURE;
	}

} else {
	my $remote_rqg_pid = fork();
	die "Could not fork for running RQG remotely: $!" unless defined $remote_rqg_pid;
	if ($remote_rqg_pid) {
		# TODO:
		# For now we presume that server startup in the VM will be fast enough, 
		# so we will have a good part of the test flow executed before <duration>.
		# In fact, especially with small duration values, it might be not so,
		# e.g. if duration is 1 min, we might end up killing the VM before the actual flow
		# has even started. Later we'll need a better check for that
		foreach (1..$opt_duration) {
			waitpid($vm_pid, WNOHANG);
			if ($? > -1) { # process exited
				say("ERROR: remote RQG process exited earlier than expected");
				exit $? >> 8;
			}
			sleep 1;
		}
		say("Killing the VM...");
		kill(9, $vm_pid);
	} else {
		my $cmd = $cmd_prefix.'"cd $HOME/rqg && perl runall-new.pl '. "@ARGV @reporters".'"';
		say("Running $cmd ...");
		my $remote_rqg_status = system($cmd) >> 8;
		say("Remote RQG process (1st part) exited with status $remote_rqg_status");
		exit;
	}
}

# Let the system to settle down a bit
sleep(3);

# Phase 2: recovery, test flow, dump, restore, data comparison

push(@ARGV, "--mysqld=--loose-myisam-recover-options=FORCE --mysqld=--loose-myisam-recover=FORCE");
push(@ARGV, "--mysqld=--loose-aria-recover=FORCE");
push(@ARGV, "--start-dirty");
push(@ARGV, "--duration=180");
push(@ARGV, "--queries=$opt_queries_after_recovery");

say("############################");
say("Executing the second part of the test: server recovery, test flow, dump, restore, comparison");
say("############################");

my $cmd = 'perl runall-new.pl ' . "@ARGV @reporters_with_BinlogConsistency";

if ($opt_crashtest_mode eq 'local') {
	say("Running $cmd ...");
	my $status = system($cmd) >> 8;
	exit $status;
} else {
	# We will restart the VM, and run the rest of the test there
	start_vm(undef,"$opt_workdir/crashtest.qcow2");

	my $cmd1 = $cmd_prefix.'"rm -rf '.$opt_vardir.'-before-recovery && cp -r '.$opt_vardir.' '.$opt_vardir.'-before-recovery"';
	say("Saving vardir of the 1st part of the test: $cmd1 ...");
	system($cmd1);

	$cmd = $cmd_prefix . '"cd $HOME/rqg && '.$cmd.'"';
	say("Running $cmd ...");
	my $remote_rqg_status = system($cmd) >> 8;
	say("Remote RQG process (2nd part) exited with status $remote_rqg_status");

	say("Killing the VM (as a cleanup measure)...");
	kill(9,$vm_pid);
	exit $remote_rqg_status;
}

sub start_vm {
	my ($base_image, $image) = @_;
	my $vm_pidfile = "$ENV{HOME}/.runvmkvm_$opt_vm_port.pid";
	$base_image = ($base_image ? "--base-image=$base_image" : '');
	my $cmd = "runvm --port=$opt_vm_port --user=$opt_vm_user --smp=1 --mem=2048 --startup-timeout=600 --shutdown-timeout=300 --cpu=qemu64 $base_image $image bash 2>&1";
	say("Starting the VM: $cmd...");
	my $pid = open(VM, "$cmd | ");
	my $started = 0;
	while (<VM>) {
		print;
		if (/^\s*\+\s+bash/) {
			$started = 1;
			$vm_pid = readpipe("head -n 1 $vm_pidfile") || $pid;
			chomp $vm_pid;
			say("VM started with PID $vm_pid");
			last;
		}
	}
	die "Failed to start the VM" unless $started;
}
