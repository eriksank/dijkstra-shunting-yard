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
#This program juxtaposes the next character to a character,
#in order to lookahead one character.
#================================================================
source ./config.sh
#----------------------------------------------------------------
char=""
char2=""
IFS=''
function readChar()
{
	char="$char2"
	read -r char2
	#handle EOF
	if [ "$?" -ne 0 ]; then
		char2=$EOF
	fi
	#uncollapse spaces
	if [ "$char2" == "" ] ; then
		char2=" "
	fi	
}

readChar
readChar
while [ "$char" != "$EOF" ] ; do
	echo "$char${CHARSEP}$char2"
	readChar
done
#================================================================

