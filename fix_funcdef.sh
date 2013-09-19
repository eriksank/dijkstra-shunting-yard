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
#This program reads a token with 2 lookahead tokens
#if it finds the keyword 'function' it will downgrade the next token
#to operand.
#================================================================
source ./config.sh
#----------------------------------------------------------------
while read -r tokentriplet; do
	OLD_IFS=$IFS
	IFS="${TOKSEP}"; read token1 token2 token3 <<<"$tokentriplet"
	IFS="${TOKFLDSEP}"; read type1 value1 <<<"$token1"
	IFS="${TOKFLDSEP}"; read type2 value2 <<<"$token2"
	IFS="${TOKFLDSEP}"; read type3 value3 <<<"$token3"

	if [ "$value1" == "function" ] ; then
		if [[ "$type2" != "FUNCT" && "$type2" != "FUNC0" ]]; then
			echo "${TOKFLDSEP}error: identifier expected after keyword 'function'"
			exit 1
		fi
		echo "FUNCDEF${TOKFLDSEP}FUNCDEF"
		echo "OPRND${TOKFLDSEP}$value2"
		IFS=$OLD_IFS; read -r tokentriplet #skip next token
	else
		echo "$type1${TOKFLDSEP}$value1"
	fi
	IFS=$OLD_IFS
done
#================================================================

