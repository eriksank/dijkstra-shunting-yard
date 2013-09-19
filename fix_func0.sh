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
#if it finds a function token FUNCT, followed by a left and a right bracket
#it will replace it by tokentype FUNC0
#
#The RPN parser counts the commas inside the brackets in order
#to determine the number of arguments. The problem is that 
#A function with only one argument has exactly the same number
#of commas as a function with no arguments.
#
#Therefore, we must distinguish between zero and one arguments.
#================================================================
source ./config.sh
#----------------------------------------------------------------
while read -r tokentriplet; do
	OLD_IFS=$IFS
	IFS="${TOKSEP}"; read token1 token2 token3 <<<"$tokentriplet"
	IFS="${TOKFLDSEP}"; read type1 value1 <<<"$token1"
	IFS="${TOKFLDSEP}"; read type2 value2 <<<"$token2"
	IFS="${TOKFLDSEP}"; read type3 value3 <<<"$token3"

	if [[ "$type1" == "FUNCT" && "$type2" == "BRLFT" && "$type3" == "BRGHT" ]] ; then
		echo "FUNC0${TOKFLDSEP}$value1"
		IFS=$OLD_IFS; read -r tokentriplet;  read -r tokentriplet #skip next two tokens
	else
		echo "$type1${TOKFLDSEP}$value1"
	fi
	IFS=$OLD_IFS
done
#================================================================

