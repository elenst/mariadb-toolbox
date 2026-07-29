#!/usr/bin/perl

# Copyright (c) 2026, Elena Stepanova and MariaDB
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1335  USA

# Convert a MariaDB/MySQL general query log into a plain list of SQL
# statements that can be replayed or fed to a syntax checker.
#
# Same basic idea as mysql_log_to_mysqltest.pl, but the output is just SQL:
#   * connect / disconnect / change-user and any parallelism are ignored --
#     statements are emitted serially, in the order they appear in the log,
#     regardless of which connection issued them;
#   * only actual SQL text (logged as 'Query') is output. Anything that is not
#     a server-side SQL statement is skipped -- including Init DB (the
#     COM_INIT_DB protocol command, a client/API operation) and binary-protocol
#     prepared statements (Prepare/Execute). Nothing is synthesized that was not
#     logged as SQL text; we preserve the syntax as is, we do not enrich it;
#   * statements are reproduced verbatim -- comments, whitespace and line
#     breaks inside a statement are preserved, nothing is reformatted;
#   * the default statement delimiter is ';'. When a statement itself contains
#     ';' (multi-statements, compound blocks, stored routine bodies, ...),
#     it is wrapped in "DELIMITER $$ ... $$ / DELIMITER ;" so the result stays
#     syntactically valid.
#
# The parser is intentionally server-version-independent and works for both
# MariaDB and MySQL general logs. It recognises both timestamp formats a
# general log may use:
#     MariaDB / older MySQL :  YYMMDD HH:MM:SS
#     MySQL 5.7+ (ISO 8601) :  YYYY-MM-DDTHH:MM:SS.ffffffZ  (or with +hh:mm)
#
# Usage:
#     mysql_log_to_sql.pl [options] [logfile ...]        (reads STDIN if none)
#
# Options:
#     -o, --output FILE     write the SQL to FILE (default: STDOUT)
#         --delimiter TOK   alternate delimiter for statements that need one
#                           (default: '$$')
#     -h, --help            this help

use strict;
use Getopt::Long;

my $opt_output    = '';
my $opt_alt_delim = '$$';
my $opt_help      = 0;

GetOptions(
  "output|o=s"                              => \$opt_output,
  "delimiter|alt-delimiter|alt_delimiter=s" => \$opt_alt_delim,
  "help|h"                                  => \$opt_help,
) or usage(1);

usage(0) if $opt_help;

if ($opt_alt_delim eq '' or $opt_alt_delim eq ';' or $opt_alt_delim =~ /\s/) {
  print STDERR "ERROR: --delimiter must be a non-empty, whitespace-free token other than ';'\n";
  exit 1;
}

my $OUT;
if (length $opt_output) {
  open($OUT, '>', $opt_output) or die "Could not open $opt_output for writing: $!\n";
} else {
  $OUT = \*STDOUT;
}

# Timestamp that may prefix a general-log record line (see header comment).
my $TS = qr/
    \d{6}\s+\d{1,2}:\d\d:\d\d                                        # YYMMDD HH:MM:SS
  |
    \d{4}-\d\d-\d\d[ T]\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:?\d\d)?  # ISO 8601
/x;

# Text of the statement currently being accumulated.
# undef means we are not inside a statement-producing record.
my $pending;

while (my $line = <>) {

  # Server banner / log-rotation header block. A statement in progress belongs
  # to the run that just ended, so flush it before skipping these lines.
  if ($line =~ /Version:.*started with:/
      or $line =~ /^Tcp port:/
      or $line =~ /^Time\s+Id\s+Command\s+Argument/) {
    flush_statement();
    next;
  }

  # A real record line either carries a timestamp, or -- for a same-second
  # event -- begins with the two-tab marker the server writes instead of one.
  # Detect on a copy so that continuation lines are never altered.
  my $work   = $line;
  my $had_ts = ($work =~ s/^$TS//);

  if ( ($had_ts || $line =~ /^\t\t/)
       && $work =~ /^[ \t]*(\d+)[ \t]+([^\t]*?)(?:\t(.*))?$/ )
  {
    my $cmd = $2;
    my $arg = defined $3 ? $3 : '';

    flush_statement();

    if ($cmd eq 'Query') {
      # Actual SQL text. Keep the trailing newline so multi-line statements
      # join to their continuation lines correctly; it is trimmed on flush.
      $pending = $arg . "\n";
    }
    else {
      # Anything that is not server-side SQL text: Connect / Quit / Change /
      # Init DB (a client/API operation, not a statement) / Prepare / Execute /
      # Close / Statistics / ... We do not synthesize statements that were never
      # logged as SQL, so these records -- and their continuation lines -- are
      # dropped.
      $pending = undef;
    }
  }
  elsif (defined $pending) {
    # Continuation of a multi-line statement -- keep it byte for byte.
    $pending .= $line;
  }
  # else: content outside any collected record (blank lines, stray text) -- skip.
}

flush_statement();

close($OUT) if length $opt_output;
exit 0;

###########################################################################

# Emit the accumulated statement, adding DELIMITER clauses if it needs them.
sub flush_statement {
  return unless defined $pending;
  my $stmt = $pending;
  $pending = undef;

  # Remove only the single line terminator left by the last log line;
  # any line breaks *inside* the statement are preserved.
  $stmt =~ s/\r?\n\z//;

  return if $stmt =~ /^\s*$/;   # ignore empty / whitespace-only statements

  # The terminator always goes on its own line: the statement's last line may
  # end with an inline "-- ..." or "#..." comment, which would otherwise
  # swallow a terminator appended to the same line and unterminate the statement.
  my $delim = choose_delimiter($stmt);
  if ($delim eq ';') {
    print $OUT $stmt, "\n;\n";
  }
  else {
    print $OUT "DELIMITER $delim\n";
    print $OUT $stmt, "\n", $delim, "\n";
    print $OUT "DELIMITER ;\n";
  }
}

# Choose a terminator that keeps the statement valid:
#   no embedded ';'  -> plain ';'
#   embedded ';'     -> a DELIMITER token not present in the statement
#                       (the requested one, '$$' by default, when it is safe).
sub choose_delimiter {
  my ($stmt) = @_;
  return ';' unless index($stmt, ';') >= 0;
  for my $cand ($opt_alt_delim, '$$', '//', '|||', '~~~~', 'ZZ_DELIMITER_ZZ') {
    next unless length $cand;
    return $cand if index($stmt, $cand) < 0;
  }
  print STDERR "WARNING: no collision-free delimiter found; using '$opt_alt_delim'. "
             . "Output around this statement may need manual fixing.\n";
  return $opt_alt_delim;
}

sub usage {
  my $code = shift;
  print STDERR <<"EOF";
Convert a MariaDB/MySQL general query log into a plain list of SQL statements.

Usage:
    $0 [options] [logfile ...]      (reads STDIN if no file is given)

Options:
    -o, --output FILE     write the SQL to FILE (default: STDOUT)
        --delimiter TOK   alternate delimiter for statements that contain ';'
                          (default: '\$\$')
    -h, --help            show this help

Connect/disconnect and parallelism are ignored; statements are emitted
serially in log order and reproduced verbatim. Statements containing ';'
(multi-statements, compound blocks, stored routines) are wrapped in
DELIMITER clauses to stay syntactically valid.
EOF
  exit $code;
}
