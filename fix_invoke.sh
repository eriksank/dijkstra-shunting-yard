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
#The RPN parser knows when a symbol is a function, but not when to
#invoke it. When the function token is followed by a deref instruction,
#it must be dereferenced first. Otherwise, it can be invoked right away.
# FUNCT ARGS DEREF ==> FUNCT ARGO DEREF INVOKE
# FUNCT ARGS X     ==> FUNCT ARGF INVOKE X
#================================================================
source ./config.sh
#----------------------------------------------------------------
function output_line()
{
	type="$1"
	value="$2"
	if [ "$type" != "$EOF" ]; then
		echo "$type${TOKFLDSEP}$value"
	fi
}

while read -r tokentriplet; do
	OLD_IFS=$IFS
	IFS="${TOKSEP}"; read token1 token2 token3 <<<"$tokentriplet"
	IFS="${TOKFLDSEP}"; read type1 value1 <<<"$token1"
	IFS="${TOKFLDSEP}"; read type2 value2 <<<"$token2"
	IFS="${TOKFLDSEP}"; read type3 value3 <<<"$token3"

	if [ "$type1" == "FUNCT" ] ; then
		if [ "$type3" == "DEREF" ] ; then
			output_line "$type1" "$value1"
			output_line "OBJARG" "$value2"
			output_line "$type3" "DEREF"
			echo "SYS${TOKFLDSEP}INVOKE"
			IFS=$OLD_IFS; read -r triplet; read -r triplet
		else
			output_line "$type1" "$value1"
			output_line "FUNARG" "$value2"
			echo "SYS${TOKFLDSEP}INVOKE"
			IFS=$OLD_IFS; read -r triplet
		fi
	elif [ "$type1" == "DEREF" ] ; then
		output_line "DEREFP" "DEREFP"
	else
		echo "$token1"
	fi
	IFS=$OLD_IFS
done
#================================================================

