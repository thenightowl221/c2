%{

#include <stdio.h>
#include <string.h>
#include "y.tab.h"

extern int tk;
#define T(x) if (tk) printf("Token: %-6s Lexeme: %s \n", x, yytext)

%}

%option noyywrap

%%
while               {T("WHILE"); return WHILE;}
if                  { T("IF");    return IF; }
else                { T("ELSE");  return ELSE; }
for                 { T("FOR");   return FOR; }
[0-9]+              {T("NUM"); yylval.s=strdup(yytext); return NUM;}
[a-z][a-z0-9]*      {T("ID"); yylval.s=strdup(yytext); return ID;}
">"|"<"|"<="|"=="   {T("RELOP"); yylval.s=strdup(yytext); return RELOP;}
[-=+*/;(){}]        {T("SYM"); return *yytext;}
[ \t\r\n]+          ;
.                   ;
%%
