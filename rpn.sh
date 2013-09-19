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
#This program is an extended RPN parser
#RPN=Reverse Polish notation
#Its purpose is to extend Dijkstra's Shunting Yard algorithm to
#handle function calls and object-oriented dereferencing.
#================================================================
source ./config.sh
#---------------------------------
#token
#---------------------------------
token=""
type=""
value=""

#---------------------------------
#stack
#---------------------------------
stack=()
stack_last_item=""
stack_type=""
stack_value=""

#---------------------------------
#comma count
#---------------------------------
commacount=0

#---------------------------------
#precedence
#---------------------------------
precedence_currtoken=0
precedence_stack==0

#---------------------------------
#debug information
#---------------------------------
debug=""
area=""
output=""

#---------------------------------
# ERROR HANDLER
#---------------------------------
function err()
{
	echo "${TOKFLDSEP}error: $area, $1"
	exit 1
}

#---------------------------------
# ERROR MESSAGES
#---------------------------------
ERR_OUT_OF_STACK="out of stack"
ERR_OPERATOR_UNKNOWN="operator unknown"
ERR_LEFT_BRACKET="left bracket '(' missing"
ERR_RIGHT_BRACKET="right bracket ')' missing"
ERR_COMMA="unexpected comma"
#---------------------------------
# STACK
#---------------------------------
function stack_push()
{
	item="$1"
	stack=( "${stack[@]}" "$item" )
}

function get_stack_last_item()
{
	if [ ${#stack[@]} -eq 0 ] ; then
		stack_last_item=""
		stack_type=""
		stack_value=""
	else
		stack_last_item="${stack[${#stack[@]}-1]}"
		stack_type=${stack_last_item%%$TOKFLDSEP*}
		stack_value=${stack_last_item#*$TOKFLDSEP}
	fi
}

function stack_pop()
{
	get_stack_last_item
	if [ ${#stack[@]} -ne 0 ] ; then
		unset stack[${#stack[@]}-1]
	else
		err "$ERR_OUT_OF_STACK"
	fi
}

function stack_debug()
{
	if [ -n "$debug" ]; then
		echo "---> $area stack:[[ ${stack[@]} ]]"
	fi
}

#---------------------------------
# PRECEDENCE
#---------------------------------
function get_precedence()
{
area="get_precedence"
	local token="$1"
	local type=${token%%$TOKFLDSEP*}
	local operator=${token#*$TOKFLDSEP}
	if [[ "$type" == "FUNCT" || "$type" == "FUNC0" ]] ; then
		return 200
	else
		case "$operator" in 
			"") return 0 ;;
			"(") return 10 ;;
			",") return 20 ;;
			"=") return 30 ;;
			"==") return 40 ;;
			"-" | "+") return 50 ;;
			".-" | ".+") return 60 ;;
			"*" | '/' | "%") return 70 ;;
			"^") return 80 ;;
			"->") return 90 ;;
			*) err "$ERR_OPERATOR_UNKNOWN : $operator" ;;
		esac
	fi
}

function get_precedence_stack()
{
	get_stack_last_item
	get_precedence "$stack_last_item"
	precedence_stack=$?
}

function get_precedence_token()
{
	get_precedence "$token"
	precedence_currtoken=$?
}

#---------------------------------
# OUTPUT 
#---------------------------------
function output_token_line()
{
	if [ -n "$debug" ]; then
		echo "output>>$area:$1"
	else
		echo "$1"
	fi
}

function output_function()
{
	case "$stack_type" in
		"FUNC0")
			output_token_line "FUNCT${TOKFLDSEP}$stack_value"
			output_token_line "ARGS${TOKFLDSEP}0"
			let commacount=0
		;;
		"FUNCT")
			let commacount++
			output_token_line "$stack_last_item"
			output_token_line "ARGS${TOKFLDSEP}$commacount"
			let commacount=0
		;;
		*) output_token_line "$stack_last_item" ;;
	esac
}

function output_control_construct()
{
	construct=$(echo "$stack_value"|  tr [:lower:] [:upper:])
	output_token_line "$construct${TOKFLDSEP}$stack_value"	
}

function output_operator()
{
	if [[ "$stack_type" != "FUNC0" && "$stack_type" != "FUNCT" ]] ; then
		output_token_line "$stack_last_item"
	else
		case "$stack_value" in
			'if' | 'while' | 'foreach' | 'switch' | 'case' )
				output_control_construct ;;
			*) output_function ;;
		esac
	fi
}

#---------------------------------
# HANDLE OPERATOR
#---------------------------------
function handle_operator()
{
area="handle_operator"
stack_debug

	get_precedence_token
	get_precedence_stack
	while [ "$precedence_currtoken" -le "$precedence_stack" ]; do
		case "$stack_type" in
			"COMMA")
				if [ "$type" == "COMMA" ]; then
					break
				fi
			;;
			*) output_operator ;;
		esac
		stack_pop
		get_precedence_stack
	done
	stack_push "$token"
}

#---------------------------------
# HANDLE FUNCTION START
#---------------------------------
function handle_function_start()
{
	case "$value" in 
		'while' | 'foreach') 
			output_token_line "SYS${TOKFLDSEP}LOOPST" ;;
		'case')
			output_token_line "SYS${TOKFLDSEP}CASEST" ;;
	esac
}

#---------------------------------
# HANDLE FUNCTION END
#---------------------------------
function handle_function_end()
{
area="handle_function"
	output_operator
	stack_pop
}

#---------------------------------
# HANDLE RIGHT BRACKET
#---------------------------------
function handle_bracket_right()
{
area="handle_bracket_right"
stack_debug

	commacount=0
	while true; do
		get_stack_last_item
		case "$stack_type" in
			"BRLFT") 
				stack_pop
				#handle function, if needed
				get_stack_last_item
				if [ "$stack_type" == "FUNCT" ] ; then
					handle_function_end
				fi
				return
				;;
			"COMMA") let commacount++ ;;
			*) output_operator ;;
		esac
		#pop the stack
		if [ ${#stack[@]} -ne 0 ]; then
			stack_pop
		else
			err "$ERR_LEFT_BRACKET"
		fi
	done
}

#---------------------------------
# HANDLE REMAINING STACK
#---------------------------------
function handle_remaining_stack()
{
area="handle_remaining_stack"
stack_debug
	while [ ${#stack[@]} -ne 0 ]; do
		stack_pop
		case "$stack_type" in
			"BRLFT") err "$ERR_RIGHT_BRACKET" ;;
			"COMMA") err "$ERR_COMMA" ;;
			*) output_operator ;;
		esac
	done
}

#---------------------------------
# HANDLE SEMICOLON
#---------------------------------
function handle_semicolon()
{
	handle_remaining_stack
	output_token_line "SYS${TOKFLDSEP}RESET"
}

#---------------------------------
# HANDLE SEMICOLON
#---------------------------------
function handle_block_end()
{
	handle_remaining_stack
	output_token_line "$token"
}

#---------------------------------
# MAIN
#---------------------------------
while read -r token; do
area="main"
stack_debug

	type=${token%%$TOKFLDSEP*}
	value=${token#*$TOKFLDSEP}
	if [ -n "$debug" ]; then echo "new token: $token"; fi

	case "$type" in 
		"OPRND" | "STRNG" | "BLKST" | "FUNCDEF") output_token_line "$token" ;;
		"BLKEND") handle_block_end ;;
		"BRLFT") stack_push "$token" ;;
		"BRGHT") handle_bracket_right ;;
		"SEMICOLON") handle_semicolon ;;
		"FUNCT" | "FUNC0") handle_function_start; handle_operator ;;
		*) handle_operator ;;
	esac
done

handle_remaining_stack
#================================================================

