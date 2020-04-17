%{
#include<stdio.h>
#include<stdlib.h>
#include "y.tab.h"
#include<string.h>

extern int line;
//char *temp;
%}

%%
\/\/.*\n              ;
"/*"[^*/]*"*/"     ;

";"         {printf("tk_sc\n"); return tk_sc;}
"for" 	    {printf("tk_for\n"); return tk_for;}
"do" 		{printf("tk_do\n"); return tk_do;}
"while" 	{printf("tk_while\n"); return tk_while;}
"var" 	    {printf("tk_var\n"); return tk_var;}
"true"      {printf("tk_true\n");return tk_true;}
"false"     {printf("tk_false\n");return tk_false;}
"null"      {printf("tk_null\n");return tk_null;}

"{"     {printf("tk_obrace\n"); return tk_obrace;}
"}"     {printf("tk_cbrace\n"); return tk_cbrace;}
"("     {printf("tk_opar\n"); return tk_opar;}
")"     {printf("tk_cpar\n"); return tk_cpar;}

"+"     {printf("tk_add\n"); return tk_add;}
"-"     {printf("tk_sub\n"); return tk_sub;}
"*"     {printf("tk_mul\n"); return tk_mul;}
"/"     {printf("tk_div\n"); return tk_div;}
"%"     {printf("tk_mod\n"); return tk_mod;}

"<"     {printf("tk_l\n"); strcpy(yylval.sval,"<");return tk_l;}
">"     {printf("tk_g\n"); strcpy(yylval.sval,">");return tk_g;}
"<="	{printf("tk_le\n"); strcpy(yylval.sval,"<=");return tk_le;}
">="    {printf("tk_ge\n"); strcpy(yylval.sval,">=");return tk_ge;}

"!"     {printf("tk_not\n"); return tk_not;}
"="     {printf("tk_eq\n"); return tk_eq;}
"=="    {printf("tk_deq\n"); strcpy(yylval.sval,"==");return tk_deq;}
"!="    {printf("tk_neq\n"); strcpy(yylval.sval,"!=");return tk_neq;}
"==="   {printf("tk_teq\n"); strcpy(yylval.sval,"===");return tk_teq;}

"?"     {printf("tk_tern\n"); return tk_tern;}
":"     {printf("tk_choice\n"); return tk_choice;}
"&"     {printf("tk_and\n"); return tk_and;}
"|"     {printf("tk_or\n"); return tk_or;}
"&&"	{printf("tk_dand\n"); return tk_dand;}
"||"	{printf("tk_dor\n"); return tk_dor;}



[a-zA-Z_$][a-zA-Z0-9_$]*    {printf("tk_identifier\n"); strcpy(yylval.sval,yytext); return tk_identifier;}
([0-9]+)                    {printf("tk_inumber\n");strcpy(yylval.sval,yytext); return tk_inumber;}
([0-9]+)(".")([0-9]+)      {printf("tk_fnumber\n");strcpy(yylval.sval,yytext); return tk_fnumber;}


(\"|\').*(\"|\')    {printf("tk_str\n");strcpy(yylval.sval,yytext); return tk_str;}

\n      {line+=1;};
\t      ;
" "     ;
%%

int yywrap()
{
    return 1;
}