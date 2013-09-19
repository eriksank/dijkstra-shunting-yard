#!/bin/bash
#================================================================
#Written by Erik Poupaert
#Copyright (C) 2010, Erik Poupaert
#email: erik@sankuru.biz
#web site: http://sankuru.biz
#October 2010, Phnom Penh, Cambodia
#================================================================
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,USA.
#
#The "GNU General Public License" (GPL) is available at
#http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#================================================================
#This program simplifies the output of the shunt.sh script
#by only keeping the token values and putting them all in one line.
#================================================================
source ./config.sh
#----------------------------------------------------------------
./shunt.sh | \
while read -r token; do
	OLD_IFS=$IFS
	IFS="${TOKFLDSEP}"; read type1 value1 <<<"$token"
	case "$type1" in
		"OBJARG") echo -n "$token " ;;
		"FUNARG") echo -n "$token " ;;
		*) echo -n "$value1 "
	esac
	IFS=$OLD_IFS
done
echo ""
#================================================================

