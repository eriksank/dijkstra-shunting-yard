# Parsing object-oriented expressions with Dijkstra's shunting yard algorithm

## Dijkstra's standard shunting yard algorithm

Dijkstra's standard shunting yard algorithm converts infix expressions to RPN (Reverse Polish Notation).

For example:

	$ echo "a+b" | ./shunt2.sh
	a b +

The standard algorithm is able to handle operator precedence:

	$ echo "a+b*5" | ./shunt2.sh
	a b 5 * +

As you can see, the multiplication * will be evaluated before the sum +. The standard algorithm is also able to distiguish between unary minus/plus (.-/.+) and binary minus/plus (-/+) in the input:

	$ echo '-a+b' | ./shunt2.sh
	a .- b +

The standard parser can also handle brackets ( ). For example:

	$ echo "(a+b)*(5-x)/(-y-2)" | ./shunt2.sh
	a b + 5 x - * y .- 2 - /

Assignments are also just expressions with the assignment operator = having very low precedence. For example:

	$ echo 'a=x+1/(a+b)' | ./shunt2.sh
	a x 1 a b + / + =

The assignment operator assigns the top of the stack to the variable just below it. For the prototype, that you can download at the top of this blog post, I have implemented a simple lexer that can handle single -and double quoted strings:

	$ echo 'a="hello\" with an embedded quote using an escape sequence"' | ./shunt.sh
	OPRND·a
	STRNG·hello" with an embedded quote using an escape sequence
	OPER·=

## How does it work?

The infix-to-rpn algorithm was originally developed by Dijkstra. You can find a good description here.

In short, there are operands and operators. Take for example the expression: a+b*5:

    the operands are: a b 5
    the operators are: + *

The operands always go through to the output immediately. The operators always have to wait: Every operator must always first be shunted, until the next operator comes along. If the next operator has lower precedence, the operator can go through, otherwise, it must wait even longer. When the input has come to an end, the operators left in the shunting yard, can all finally go through.

In the example, a+b*5, a goes through immediately, while + is shunted. Then, b, being an operand, goes through immediately. The next token is *. Now we must choose, shall we let + go through first? The answer is no. The operator * will have to be executed first, because the multiplication operator has precedence over the addition operator. Therefore, we shunt * without letting + go through first. Next, we see 5. It goes through immediately. Now that the input is empty, we can let the still-shunted * and + operators go through as well.

The example script that you can download, only handles a few example operators. If you want to test the script with more operators, you can add them to the get_precedence() function in the rpn.sh script.

 
## Stack-based evaluation of expressions and virtual machines

The RPN version of an expression is quite interesting, because it allows for stack-based evaluation, for which it is relatively simple to implement a virtual machine. For example, for the expression: a b 5 * +, the stack-based instructions become:

    push operand a
    push operand b
    push operand 5
    multiply the last two operands and push the resulting operand
    sum the last two operands and push the resulting operand

After the virtual machine has completed executing this series of instructions, you can find the final result for the expression on the stack.

 
## Extending the parser to handle function calls

The standard shunting yard algorithm does not parse function calls. Here you can find an example of how to extend a shunting yard parser by using additional stacks.

My own solution does not use additional stacks. Whenever the lexer script lex.sh detects the presence of an identifier followed by a left bracket (, it flags the identifier as a function. For example, in the expression f(x), f is followed by a left bracket (, and therefore, represents a function call.

For example:

	$ echo 'process(x,y,z)' | ./shunt2.sh
	x y z process FUNARG·3 INVOKE

The identifier process is followed by a left bracket (, and is therefore a function call. The parser, therefore, treats it as an operator and not as an operand. Function operators have the highest precedence of all operators. When the virtual machine evaluates an expression in which a function token appears, the function token will simply be pushed onto the stack. It is only when the virtual machine encounters the instruction INVOKE, that the virtual machine will invoke the function symbol at the top of the stack. For the example, x y z process FUNARG·3 INVOKE:

    push operand x
    push operand y
    push operand z
    push operand process
    assert that function signature has 3 arguments
    invoke top of stack and push the resulting operand

The virtual machine's assert function signature functional will verify that the function truly has 3 operands. If not, it will fail with an error message. The parser can also handle embedded function calls:

	$ echo 'process(x,y,do_something(a,b,c))' | ./shunt2.sh
	x y a b c do_something FUNARG·3 INVOKE process FUNARG·3 INVOKE

The shunt2.sh script simplifies the output and puts all tokens onto one line. With the shunt.sh script, you can see the full output of the parser, including token types:

	$ echo 'process(x,y,do_something(a,b,c))' | ./shunt.sh
	OPRND·x
	OPRND·y
	OPRND·a
	OPRND·b
	OPRND·c
	FUNCT·do_something
	FUNARG·3
	SYS·INVOKE
	FUNCT·process
	FUNARG·3
	SYS·INVOKE

## Extending the parser to handle object-oriented expressions

Another extension to the standard algorithm, is the ability to parse object-oriented expressions. For example:

	$ echo 'a-≻f()' | ./shunt2.sh
	a f OBJARG·0 DEREF INVOKE
 
	$ echo 'a-≻f(x)' | ./shunt2.sh
	a x f OBJARG·1 DEREF INVOKE

The stack-based instructions become:

    push operand a
    push operand x
    push operand f
    dereference f with 1 arg from the entry on position 1+1=2 below the top of the stack, and push the resulting operand on the stack
    invoke top of stack and push the resulting operand

The essence of object-oriented expressions, is that the function to call must first be resolved from the variable being dereferenced. Next, the function found gets invoked with this variable and all other function arguments. It is a two-stage resolution process. You can chain and embed object-oriented expressions. For example:

	$ echo 'r=a-≻f(x)-≻g(y)-≻h(x1-≻resolve(m),x2+3)' | ./shunt2.sh
	r a x f OBJARG·1 DEREF INVOKE y g OBJARG·1 DEREF INVOKE x1 m resolve OBJARG·1 DEREF INVOKE x2 3 + h OBJARG·2 DEREF INVOKE =

In principle -- unless its implementation still contains bugs -- the extended shunting yard parser should be able to parse object-oriented expressions of arbitrary complexity. The algorithm also distiguishes between method (=function) calls and object-property dereferencing. For example:

	$ echo 'a-≻b+95' | ./shunt2.sh
	a b DEREFP 95 +
	$ echo 'a-≻b+95/g-≻draw()' | ./shunt2.sh 
	a b DEREFP 95 g draw OBJARG·0 DEREF INVOKE / +

The DEREF instruction will dereference a function, while the DEREFP instruction will dereference a property.

## Extending the parser to handle more than one expression

Traditionally, we use semicolons ; to separate one expression from the other. In terms of the extended shunting yard parser, we will simply force the parser to handle the remaining stack, before proceeding with the next expression. For the virtual machine, it means that it should drop all existing values on the current stack frame. For example:

	$ echo 'a=2;b=5;x=23+12;' | ./shunt2.sh
	a 2 = RESET b 5 = RESET x 23 12 + = RESET

The RESET instruction resets the stack to its lowest level. All values on the stack's current frame will be dropped. For example, the following expression is never assigned to any variable. Therefore, the virtual machine computes it and then simply drops it:

	$ echo 'a*b-2+3;' | ./shunt2.sh
	a b * 2 - 3 + RESET

In this example, computing the expression is meaningless. Its result is never assigned to a variable, and it does not cause any useful side-effects. Therefore, it is actually a waste of computer resources.

## Extending the parser to handle 'if' statements

It is quite straightforward to extend the parser to handle statement blocks. For example:

	$ echo 'if(a==12) x=9;' | ./shunt2.sh
	a 12 == if x 9 = RESET

Internally, the parser will treat the if statement as if it has seen a function. Some later logic will rename the token type from FUNCT to IF. The full output for the example above is:

	$ echo 'if(a==12) x=9;' | ./shunt.sh
	OPRND·a
	OPRND·12
	OPER·==
	IF·if
	OPRND·x
	OPRND·9
	OPER·=
	SYS·RESET

In the example above, if the condition is false, the virtual machine should jump till the next SYS·RESET. The parser can also handle statement blocks. For example:

	$ echo 'if(a==12) {x=9;y=b-1;}' | ./shunt2.sh
	a 12 == if { x 9 = RESET y b 1 - = RESET }

The full output is:

	$ echo 'if(a==12) {x=9;y=b-1;}' | ./shunt.sh
	OPRND·a
	OPRND·12
	OPER·==
	IF·if
	BLKST·{
	OPRND·x
	OPRND·9
	OPER·=
	SYS·RESET
	OPRND·y
	OPRND·b
	OPRND·1
	OPER·-
	OPER·=
	SYS·RESET
	BLKEND·}

When the condition is false, instead of skipping instructions until the next SYS·RESET token, as for single statements, the virtual machine will skip instructions until the corresponding block end, BLKEND·} token.

 
## Extending the parser to handle 'switch' statements

Using the following syntax, it is again not a big deal to extend the parser to handle switch/case:

	$ echo 'switch(a+1) \
	{ \
	case(4) dofirst(); \
	case(c*12/x) donext(); \
	case(default) doother(); \
	}' \
	| ./shunt.sh
 
	OPRND·a
	OPRND·1
	OPER·+
	SWITCH·switch
	BLKST·{
	SYS·CASEST
	OPRND·4
	CASE·case
	FUNCT·dofirst
	FUNARG·0
	SYS·INVOKE
	SYS·RESET
	SYS·CASEST
	OPRND·c
	OPRND·12
	OPER·*
	OPRND·x
	OPER·/
	CASE·case
	FUNCT·donext
	FUNARG·0
	SYS·INVOKE
	SYS·RESET
	SYS·CASEST
	OPRND·default
	CASE·case
	FUNCT·doother
	FUNARG·0
	SYS·INVOKE
	SYS·RESET
	BLKEND·} 

## Extending the parser to handle 'while' and 'foreach' statements

Adding support for traditional for(statement; statement; statement) instructions, is difficult in this extended shunting yard parser, because the parser uses the semicolon token to reset the operator stack. The parser would balk over the unhandled left bracket ( left on the stack. It would, therefore, take some substantial fiddling to add support for a traditional for loop. But then again, the while and foreach statements are equally powerful looping constructs. For example:

	$ echo 'while(true) { a-≻eat(); b-≻drink(); if(a-≻done) break; }' | ./shunt.sh 
	SYS·LOOPST
	OPRND·true
	WHILE·while
	BLKST·{
	OPRND·a
	FUNCT·eat
	OBJARG·0
	DEREF·DEREF
	SYS·INVOKE
	SYS·RESET
	OPRND·b
	FUNCT·drink
	OBJARG·0
	DEREF·DEREF
	SYS·INVOKE
	SYS·RESET
	OPRND·a
	OPRND·done
	DEREFP·DEREFP
	IF·if
	OPRND·break
	SYS·RESET
	BLKEND·}
 
	$ echo 'foreach(item in items) { item-≻pick(); item-≻pack(); if(item-≻done) item-≻ship(); }' | ./shunt.sh
	SYS·LOOPST
	OPRND·item
	OPRND·in
	OPRND·items
	FOREACH·foreach
	BLKST·{
	OPRND·item
	FUNCT·pick
	OBJARG·0
	DEREF·DEREF
	SYS·INVOKE
	SYS·RESET
	OPRND·item
	FUNCT·pack
	OBJARG·0
	DEREF·DEREF
	SYS·INVOKE
	SYS·RESET
	OPRND·item
	OPRND·done
	DEREFP·DEREFP
	IF·if
	OPRND·item
	FUNCT·ship
	OBJARG·0
	DEREF·DEREF
	SYS·INVOKE
	SYS·RESET
	BLKEND·} 

Obviously, this output would need to be post-processed in order to add labels and conditional and unconditional jumps for the looping contructs. This can actually be effected with a simple script. We will probably also need to fiddle with the output to avoid the need to look ahead in the token stream.

 
## Extending the parser to handle function definition statements

Support for function definitions can be added by applying special treatment to the function keyword:

	$ echo 'function f(x1,x2,x3) { return x1+x2+x3; }' | ./shunt.sh
	FUNCDEF·FUNCDEF
	OPRND·f
	OPRND·x1
	OPRND·x2
	OPRND·x3
	BLKST·{
	OPRND·return
	OPRND·x1
	OPRND·x2
	OPER·+
	OPRND·x3
	OPER·+
	SYS·RESET
	BLKEND·}

For the parser, handling function definitions is relatively simple, but for the virtual machine less so. The virtual machine will need to create a function table to keep track of the function definitions. The parser does not need to be extended in order to support class definitions. It is again the virtual machine that would need to add specific support for them:

	$ echo 'class whatever inherits anything { function f(x1,x2,x3) { return x1+x2+x3; } }' | ./shunt.sh
	OPRND·class
	OPRND·whatever
	OPRND·inherits
	OPRND·anything
	BLKST·{
	FUNCDEF·FUNCDEF
	OPRND·f
	OPRND·x1
	OPRND·x2
	OPRND·x3
	BLKST·{
	OPRND·return
	OPRND·x1
	OPRND·x2
	OPER·+
	OPRND·x3
	OPER·+
	SYS·RESET
	BLKEND·}
	BLKEND·}

To facilitate the processing of the parser output, it would undoubtedly be useful to introduce specific token types for class and inherits.

 
## Validating input to the parser

Even though, it would be easy to add, it would also be rather time consuming, to add validation to the parser, and fail as early as possible for syntax and grammar errors. It can be done, but I only added little validation in this prototype. Furthermore, this is where traditional LALR and LL parsers shine. Most of the validation can be implemented automatically from the grammar definition file. But then again, Dijkstra's shunting yard algorithm is so simple, that it is very attractive to use it for small embedded scripting engines.


12. The script

The shunt.sh script works by chaining a series of smaller scripts that accept input on stdin and write their results to stdout:

	./line2char.sh \
	| ./lookahead_char.sh \
	| ./lex.sh \
	| ./lookahead_2tokens.sh \
	| ./fix_func0.sh \
	| ./lookahead_2tokens.sh \
	| ./fix_funcdef.sh \
	| ./rpn.sh \
	| ./lookahead_2tokens.sh \
	| ./fix_invoke.sh

    line2char.sh: puts every character in the input on one line.
    lookahead_char.sh: juxtaposes each character with the next character; it allows the next script to lookahead, when needed.
    lex.sh: simplistic manual lexer; groups characters into operands; identifies functions and unary operators, and outputs qualified tokens.
    lookahead_2tokens.sh: juxtaposes each token with the next two tokens; it allows the next script to lookahead two tokens, when needed.
    fix_func0.sh: the rpn.sh script determines the number of arguments in a function call by counting the number of commas. Therefore, it cannot distinguish between zero (e.g. f()) and one argument (e.g. f(x)). Therefore, we must mark functions without arguments distinctively.
    rpn.sh: the extended shunting yard algorithm.
    fix_invoke.sh: adds the INVOKE instruction where appropriate, and creates the distinction between between DEREF and DEREFP.
    fix_funcdef.sh: makes sure the function keyword is followed by an identifier.

 
## Conclusion

It is absolutely possible to extend Dijkstra's original shunting yard algorithm to translate object-oriented function definitions and expressions of arbitrary complexity from infix to RPN notation. Since the RPN version of an expression can be executed by a relatively simple virtual machine, it would be possible to write a fully-fledged bytecode compiler around such extended shunting yard algorithm, which could supply its output to an existing scripting engine, such as the Php, perl, javascript, .NET, java, neko or other virtual machine. It would also be possible to build a new scripting engine and a new bytecode format, but why re-invent the wheel?

I have built the shunt.sh and shunt2.sh scripts, in order to support my conjecture concerning extending Dijkstra's shunting yard algorithm, with a functioning prototype. Even though the scripts manage to parse numerous examples correctly, I do not guarantee that they will always work correctly. There is also a general need for more validation of the input. If you find errors, please, let me know.

