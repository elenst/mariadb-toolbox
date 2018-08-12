#!/usr/bin/bash
#
#  Copyright (c) 2017, MariaDB
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */


# The script expects in the environment
# TYPE (mandatory): upgrade | crash-upgrade | undo-upgrade | recovery 
# OLD  (optional): 10.2.6 | 10.1 | ...
# ENCRYPTION (optional): ON | OFF | TURN_ON

COMBINATION="$TYPE"

if [ -z "$COMBINATION" ] ; then
  echo "ERROR: Upgrade type is not defined"
elif [ "$TYPE" == "upgrade" ] ; then
  TYPE=normal
  COMBINATION=upgrade
elif [ "$TYPE" == "crash-upgrade" ] ; then
  TYPE=crash
  COMBINATION=upgrade
elif [ "$TYPE" == "undo-upgrade" ] ; then
  TYPE=undo
fi

if [ -n "$OLD" ] ; then
  major=`echo $OLD | sed -e 's/\([1-9]*\.[0-9]*\).*/\1/'`
  if [ -n "$major" ] ; then
    COMBINATION=${COMBINATION}-from-${major}
  fi
fi

if [ "$ENCRYPTION" == "ON" ] || [ "$ENCRYPTION" == "on" ] || [ "$ENCRYPTION" == "YES" ] || [ "$ENCRYPTION" == "yes" ] ; then
  COMBINATION=${COMBINATION}-encrypted
fi

COMBINATION=${COMBINATION}.cc

echo "Combination file $COMBINATION"
