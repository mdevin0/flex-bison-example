%{

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;

typedef struct _my_complex my_complex;
void yyerror(const char* s);
char* get_print(my_complex x1, char* name);
struct _tuple calculate_solutions(double a, double b, double c);
%}
	

%code requires {
	typedef struct _my_complex my_complex;
	struct _my_complex {
		double real;
		double imaginary;
	};
	
    struct _tuple {
		my_complex x1;
		my_complex x2;
	};
}

%union {
	int ival;
	float fval;
	struct _tuple tuple;
}

%token<ival> T_INT
%token<fval> T_FLOAT
%token<tuple> T_TUPLE
%token T_PLUS T_MINUS T_MULTIPLY T_DIVIDE T_LEFT T_RIGHT T_POWER T_VAR
%token T_NEWLINE T_QUIT
%left T_PLUS T_MINUS
%left T_MULTIPLY T_DIVIDE
%left T_POWER

%type<ival> expression
%type<fval> mixed_expression
%type<tuple> equation
%type<fval> a b c

%start calculation

%%

calculation:
	   | calculation line
;

line: T_NEWLINE
    | mixed_expression T_NEWLINE { printf("\tResult: %f\n", $1);}
    | expression T_NEWLINE { printf("\tResult: %i\n", $1); }
	| equation T_NEWLINE {printf("\tResult: %s, %s\n", get_print($1.x1, "x1"), get_print($1.x2, "x2"));}
    | T_QUIT T_NEWLINE { printf("bye!\n"); exit(0); }
;

mixed_expression: T_FLOAT                 		 { $$ = $1; }
	  | mixed_expression T_PLUS mixed_expression	 { $$ = $1 + $3; }
	  | mixed_expression T_MINUS mixed_expression	 { $$ = $1 - $3; }
	  | mixed_expression T_MULTIPLY mixed_expression { $$ = $1 * $3; }
	  | mixed_expression T_DIVIDE mixed_expression	 { $$ = $1 / $3; }
	  | mixed_expression T_POWER mixed_expression	 { $$ = pow($1,$3); }
	  | T_LEFT mixed_expression T_RIGHT		 { $$ = $2; }
	  | expression T_PLUS mixed_expression	 	 { $$ = $1 + $3; }
	  | expression T_MINUS mixed_expression	 	 { $$ = $1 - $3; }
	  | expression T_MULTIPLY mixed_expression 	 { $$ = $1 * $3; }
	  | expression T_DIVIDE mixed_expression	 { $$ = $1 / $3; }
	  | expression T_POWER mixed_expression	     { $$ = pow($1,$3); }
	  | mixed_expression T_PLUS expression	 	 { $$ = $1 + $3; }
	  | mixed_expression T_MINUS expression	 	 { $$ = $1 - $3; }
	  | mixed_expression T_MULTIPLY expression 	 { $$ = $1 * $3; }
	  | mixed_expression T_DIVIDE expression	 { $$ = $1 / $3; }
	  | expression T_DIVIDE expression		 { $$ = $1 / (float)$3; }
	  | expression T_POWER expression		 { $$ = pow($1, $3); }
;

expression: T_INT				{ $$ = $1; }
	  | expression T_PLUS expression	{ $$ = $1 + $3; }
	  | expression T_MINUS expression	{ $$ = $1 - $3; }
	  | expression T_MULTIPLY expression	{ $$ = $1 * $3; }
	  | T_LEFT expression T_RIGHT		{ $$ = $2; }
;

a: T_VAR T_POWER T_INT { $$ = 1; }
	| T_INT   T_MULTIPLY T_VAR T_POWER T_INT { $$ = $1; }
	| T_FLOAT T_MULTIPLY T_VAR T_POWER T_INT { $$ = $1; }
	| T_MINUS T_INT   T_MULTIPLY T_VAR T_POWER T_INT { $$ = -$2; }
	| T_MINUS T_FLOAT T_MULTIPLY T_VAR T_POWER T_INT { $$ = -$2; }
;

b: { $$ = 0; }
	| T_INT   T_MULTIPLY T_VAR { $$ = $1; }
	| T_FLOAT T_MULTIPLY T_VAR { $$ = $1; }
;

c: { $$ = 0; }
	| T_INT   { $$ = 1; }
	| T_FLOAT { $$ = $1; }
;

equation: a T_PLUS b T_PLUS c  {double complex a = $1; double complex b = $3; double c = $5; $$ = calculate_solutions(a, b, c); }
;
%%

char* get_print(my_complex x1, char* name){
	char* result = malloc(80);
	if(x1.imaginary != 0){
		sprintf(result, "%s = %.1f%+.1fi", name,  x1.real, x1.imaginary);
	} else {
		sprintf(result, "%s = %.1f", name, x1.real);
	}
	return result;
};

struct _tuple calculate_solutions(double a, double b, double c){
	double d = pow(b, 2) - 4 * a * c;
	double x1r = creal((-b + csqrt(d)) / (2 * a));
	double x1i = cimag((-b + csqrt(d)) / (2 * a));
	double x2r = creal((-b - csqrt(d)) / (2 * a));
	double x2i = cimag((-b - csqrt(d)) / (2 * a));
	struct _tuple r = {x1r, x1i, x2r, x2i};
	return r;
};

int main() {
	yyin = stdin;

	do {
		yyparse();
	} while(!feof(yyin));

	return 0;
}

void yyerror(const char* s) {
	fprintf(stderr, "Parse error: %s\n", s);
	exit(1);
}
