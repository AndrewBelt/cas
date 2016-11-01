%lex

%%
\s+                             /* skip whitespace */
[0-9]+(\.[0-9]+)?([eE][0-9]+)?  return 'NUMBER';
[A-Za-z][A-Za-z0-9]*            return 'IDENT';
\$[A-Za-z0-9]+                  return 'PLACEHOLDER'
"*"                             return '*';
"/"                             return '/';
"-"                             return '-';
"+"                             return '+';
"^"                             return '^';
"("                             return '(';
")"                             return ')';
"["                             return '[';
"]"                             return ']';
","                             return ',';
<<EOF>>                         return 'EOF';

/lex


%start start
%%

start:
  EOF {return null;}
| expr EOF {return $1;}
;

args:
  %empty {$$ = [];}
| expr {$$ = [$1];}
| args ',' expr {$1.push($3); $$ = $1;}
;

/* Expressions are in order from weakest to strongest precedence. */

expr:
	add_expr {$$ = $1;}
;

add_expr:
	mult_expr {$$ = $1;}
| add_expr '+' mult_expr {$$ = new Func(new Symbol('Plus'), [$1, $3]);}
| add_expr '-' mult_expr {$$ = new Func(new Symbol('Plus'), [$1, new Func(new Symbol('Times'), [new Numeric(-1), $3])]);}
;

mult_expr:
	juxt_expr {$$ = $1;}
|	mult_expr '*' juxt_expr {$$ = new Func(new Symbol('Times'), [$1, $3]);}
|	mult_expr '/' juxt_expr {$$ = new Func(new Symbol('Times'), [$1, new Func(new Symbol('Power'), [$3, new Numeric(-1)])]);}
;

juxt_expr:
	unary_expr {$$ = $1;}
| juxt_expr pow_expr {$$ = new Func(new Symbol('Times'), [$1, $2]);}
;

unary_expr:
	pow_expr {$$ = $1;}
| '-' unary_expr {$$ = new Func(new Symbol('Times'), [new Numeric(-1), $2]);}
;

pow_expr:
	func_expr {$$ = $1;}
| func_expr '^' unary_expr {$$ = new Func(new Symbol('Power'), [$1, $3]);}
;

func_expr:
	prim_expr {$$ = $1;}
| func_expr '[' args ']' {$$ = new Func($1, $3);}
;

prim_expr:
	IDENT {$$ = new Symbol(yytext);}
|	NUMBER {$$ = new Numeric(Number(yytext));}
| '(' expr ')' {$$ = $2;}
/*| PLACEHOLDER {$$ = new Placeholder(yytext.substr(1));}*/
;
