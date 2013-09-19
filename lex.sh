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
#This program is a simplistic lexer, but it can handle 
#single quoted and double quoted strings, with embedded quotes
#escaped by a backslash character
#
#Punctuation characters are considered operators. 
#It distinguishes the following named operators: '(' ')' '->' ',' 
#These operators are treated specifically in the RPN parser
#Everything else are operands.
#However, an operand followed by a '(' is considered a function
#================================================================
source ./config.sh
#----------------------------------------------------------------
STATE_OPERAND=1
STATE_FUNCTION=2
STATE_BRACKET_LEFT=3
STATE_BRACKET_RIGHT=4
STATE_COMMA=5
STATE_DEREF=6
STATE_QUOTE_SINGLE=7
STATE_QUOTE_DOUBLE=8
STATE_OPERATOR=9
STATE_SPACE=10
STATE_SEMICOLON=11
STATE_BLOCK_START=12
STATE_BLOCK_END=13
STATE=${STATE_OPERAND}

char=""
char2=""
buffer=""

function state_name()
{
	state="$1"
	case "$state" in
		"${STATE_OPERAND}") echo "OPRND" ;;
		"${STATE_FUNCTION}") echo "FUNCT" ;;
		"${STATE_BRACKET_LEFT}") echo "BRLFT" ;;
		"${STATE_BRACKET_RIGHT}") echo "BRGHT" ;;
		"${STATE_COMMA}") echo "COMMA" ;;
		"${STATE_DEREF}") echo "DEREF" ;;
		"${STATE_SEMICOLON}") echo "SEMICOLON" ;;
		"${STATE_QUOTE_SINGLE}") echo "STRNG" ;;
		"${STATE_QUOTE_DOUBLE}") echo "STRNG" ;;
		"${STATE_BLOCK_START}") echo "BLKST" ;;
		"${STATE_BLOCK_END}") echo "BLKEND" ;;
		"${STATE_OPERATOR}") echo "OPER" ;;
		*) echo "ERROR"; exit 1 ;;
	esac
}

function buffer_output()
{
	state="$1"
	state_name=$(state_name "$state")
	if [ "$buffer" != "" ]; then echo "$state_name${TOKFLDSEP}$buffer"; fi
	buffer=""		
}

charcount=0
while read -r charpair; do

	let charcount++

	char=${charpair%%$CHARSEP*}
	char2=${charpair#*$CHARSEP}

	STATE_PREVIOUS=${STATE}

	case "$char" in
		[[:lower:]]) STATE=${STATE_OPERAND};;
		[[:upper:]]) STATE=${STATE_OPERAND};;
		[0-9]) STATE=${STATE_OPERAND};;
		"_") STATE=${STATE_OPERAND};;
		".") STATE=${STATE_OPERAND};;
		'$') STATE=${STATE_OPERAND};;
		"") STATE=${STATE_SPACE};;
		'(') STATE=${STATE_BRACKET_LEFT};;
		')') STATE=${STATE_BRACKET_RIGHT};;
		',') STATE=${STATE_COMMA};;
		';') STATE=${STATE_SEMICOLON};;
		'{') STATE=${STATE_BLOCK_START};;
		'}') STATE=${STATE_BLOCK_END};;
		'"') STATE=${STATE_QUOTE_DOUBLE};;
		"'") STATE=${STATE_QUOTE_SINGLE};;
		*) STATE=${STATE_OPERATOR};;
	esac

	#------------------------------------------------------------------
	#handle state change, for operand
	#------------------------------------------------------------------
	if [ "${STATE}" != "${STATE_PREVIOUS}" ] ; then
		if [ "${STATE_PREVIOUS}" == "${STATE_OPERAND}" ] ; then
			case "${STATE}" in
				"${STATE_BRACKET_LEFT}") buffer_output "${STATE_FUNCTION}" ;;
				*)  buffer_output "${STATE_OPERAND}" ;; 
			esac
			buffer_output "${STATE}"
		fi
	fi

	#------------------------------------------------------------------
	#handle operand
	#------------------------------------------------------------------
	if [ "${STATE}" == "${STATE_OPERAND}" ] ; then
		buffer="${buffer}${char}"
		continue
	fi

	#------------------------------------------------------------------
	#handle unary plus/minus
	#------------------------------------------------------------------
	if [[ "$charcount" -eq 1 && ( "$char" == "+" || "$char" == "-") ]] ; then
		buffer="${UNARY}$char"
		buffer_output "${STATE}"
		continue
	fi	

	if [[ "${STATE}" == "${STATE_BRACKET_LEFT}" && ( "${char2}" == "+" || "${char2}" == "-") ]] ; then
		buffer="$char"
		buffer_output "${STATE_BRACKET_LEFT}"
		buffer="${UNARY}${char2}"
		buffer_output "${STATE_OPERATOR}"
		read -r charpair #drop next char
		continue
	fi	
	#------------------------------------------------------------------
	#handle named punctuation
	#------------------------------------------------------------------
	case "${STATE}" in
		"${STATE_BRACKET_LEFT}" | "${STATE_BRACKET_RIGHT}" | \
		"${STATE_COMMA}" | "${STATE_SEMICOLON}" | \
		"${STATE_BLOCK_START}" | "${STATE_BLOCK_END}" )
			buffer="$char"
			buffer_output "${STATE}"
			continue
		;;
	esac

	#------------------------------------------------------------------
	#handle quote single
	#------------------------------------------------------------------
	if [ "${STATE}" == "${STATE_QUOTE_SINGLE}" ] ; then
		while read -r charpair; do
			char=${charpair%%$CHARSEP*}
			char2=${charpair#*$CHARSEP}
			#handle escaped single quote
			if [[ "${char}" == '\' &&  "${char2}" == "'" ]] ; then
				buffer="${buffer}${char2}"
				read -r charpair #skip next charpair
				continue
			fi
			if [ "${char}" == "'" ]; then break; fi
			if [ "${char}" == "" ]; then char=" "; fi	
			buffer="${buffer}${char}"
		done
		buffer_output "${STATE}"
		continue
	fi

	#------------------------------------------------------------------
	#handle quote double
	#------------------------------------------------------------------
	if [ "${STATE}" == "${STATE_QUOTE_DOUBLE}" ] ; then
		while read -r charpair; do
			char=${charpair%%$CHARSEP*}
			char2=${charpair#*$CHARSEP}
			#handle escaped double quote
			if [[ "${char}" == '\' &&  "${char2}" == '"' ]] ; then
				buffer="${buffer}${char2}"
				read -r charpair  #skip next charpair
				continue
			fi
			if [ "${char}" == '"' ]; then break; fi	
			if [ "${char}" == "" ]; then char=" "; fi	
			buffer="${buffer}${char}"
		done
		buffer_output "${STATE}"
		continue
	fi

	#------------------------------------------------------------------
	#handle operators
	#------------------------------------------------------------------
	if [ "${STATE}" == "${STATE_OPERATOR}" ] ; then
		charpair2="${char}${char2}"
		case "${charpair2}" in
			'&&' | '||' | '<=' | '>=' | '==' | '<<' | '>>') 
				buffer="${charpair2}"; 
				read -r charpair #drop next char
				;;
			'->')
				buffer="${charpair2}"; 
				read -r charpair #drop next char
				STATE=${STATE_DEREF}
				;;

			*) 	buffer="${char}"
				;; 
		esac
		buffer_output "${STATE}"
	fi
	#------------------------------------------------------------------
done
#================================================================

