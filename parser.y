///mnt/c/Users/sathi/Downloads/MS_EndSem/COM
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct {char k, op[3], a[16], b[16], r[16] ; } Q;
Q q[500]; int n, t, l, sp, st[50], tk;

Q ub[5][20]; int un[5], ud;

int yylex(); void yyerror(const char *s) { printf("%s\n", s); }

void yyrestart(FILE *f);
int yyparse();

char *nt() {char *s = malloc(8); sprintf(s, "t%d", ++t); return s; }
char *ln(int i) {char *s = malloc(8); sprintf(s, "L%d", i); return s; }

void e(char k, char *op, char * a, char *b, char *r) {
    Q *p = &q[n++];
    p->k = k;
    strcpy(p->op, op); strcpy(p->a, a); strcpy(p->b, b); strcpy(p->r, r);
}

void pr() {
    for(int i=0; i<n; i++) {
        Q *p = q + i;
        switch(p->k) {
            case 'B': case 'R': printf("\t%s = %s %s %s \n", p->r, p->a, p->op, p->b); break;
            case 'C': printf("\t%s = %s \n", p->r, p->a); break;
            case 'L': printf("%s: \n", p->r); break;
            case 'G': printf("\tGOTO %s \n", p->r); break;
            case 'F': printf("\tIFFALSE %s GOTO %s \n", p->a, p->r); break;
        }
    }
}

int code_motion() {
    FILE *f = fopen("input2.txt", "r");

    tk = n = t = l = sp = ud = 0;      /* reset all counters for a fresh file */
    yyrestart(f);                 /* point flex at the new file */
    yyparse();          /* build the quads */
    fclose(f);
    printf("Optimized Code\n");
    pr();
    return 0;
}

void gen() {
    for(int i=0; i<n; i++) {
        Q *p = q + i;
        switch(p->k) {
            case 'R': printf("\tMOV R0, %s \n\tCMP R0, %s \n\tSET %s R0 \n\tMOV %s, R0 \n", p->a, p->b, p->op, p->r); break;
            case 'B': { char *m = p->op[0] == '+' ? "ADD" : p->op[0] == '-' ? "SUB" : p->op[0] == '*' ? "MUL" : "DIV";
                printf("\tMOV R0, %s \n\t%s r0, %s \n\tMOV %s, R0 \n", p->a, m, p->b, p->r); break;
            }
            case 'C': printf("\tMOV R0, %s \n\tMOV %s, R0 \n", p->a, p->r); break;
            case 'L': printf("%s: \n", p->r); break;
            case 'G': printf("\tJMP %s \n", p->r); break;
            case 'F': printf("\tMOV R0, %s \n\tCMP R0, #0 \n\tJE %s \n", p->a, p->r); break;
        }
    }
}

%}

%union { char *s ; }
%token WHILE IF ELSE FOR
%token <s> ID NUM RELOP
%type <s> expr cond
%nonassoc ELSE
%left '+' '-'
%left '*' '/'
%right UM

%%
prog    : stmts ;
stmts   : stmts stmt | stmt ;

asg     : ID '=' expr           { e('C', "", $3, "", $1); } ;

stmt    : asg ';'
        | WHILE                 { st[sp++] = ++l; e('L', "", "", "", ln(l)); }
          '(' cond ')'          { st[sp++] = ++l; e('F', "", $4, "", ln(l)); }
          blk                   { int b = st[--sp], a = st[--sp];
                                  e('G', "", "", "", ln(a)); e('L', "", "", "", ln(b)); }

        | IF '(' cond ')'       { st[sp++] = ++l; e('F', "", $3, "", ln(l)); }
        blk else_part
        | FOR '(' asg ';'       { st[sp++] = ++l; e('L', "", "", "", ln(l)); }   
           cond ';'              { st[sp++] = ++l; e('F', "", $6, "", ln(l)); }
                                { st[sp++] = n ;}
           asg ')'              { int s = st[--sp];
                                  un[ud] = n - s; 
                                  memcpy(ub[ud++], q+s, (n-s) * sizeof(Q));
                                  n = s;
                                }
           blk                  { ud--;
                                  memcpy(q+n,  ub[ud], un[ud] * sizeof(Q)); n += un[ud];
                                  int b = st[--sp], a = st[--sp]; 
                                  e('G', "", "", "", ln(a)); e('F', "", "", "", ln(b));
                                }
        ;

else_part : ELSE                { int a = st[--sp], b = ++l; st[sp++] = b;
                                  e('G', "", "", "", ln(b)); e('L', "", "", "", ln(a)); }
            blk                 { e('L', "", "", "", ln(st[--sp])); }
          ;

blk     : '{' stmts '}' | stmt ;

cond    : expr RELOP expr       { $$ = nt(); e('R', $2, $1, $3, $$); }
        | expr ;

expr    : expr '+' expr         {$$ = nt(); e('B', "+", $1, $3, $$);}
        | expr '-' expr         {$$ = nt(); e('B', "-", $1, $3, $$);}
        | expr '*' expr         {$$ = nt(); e('B', "*", $1, $3, $$);}
        | expr '/' expr         {$$ = nt(); e('B', "/", $1, $3, $$);}
        | '-' expr %prec UM     {$$ = nt(); e('B', "-", "0", $2, $$);}
        | '('expr')'            {$$ = $2;}
        | ID | NUM  ;
%%

int main(int c, char **v) {
    tk = c > 1;
    yyparse();
    pr();
    code_motion();
    gen();
}