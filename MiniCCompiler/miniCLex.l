/* Analizador Lexico Flex */
%{
    #include <stdio.h>
    #include "miniCSin.tab.h"
    #include <math.h>
    /*Funciones auxiliares*/
    void error_lexico();
    /* Variables para el análisis */
    int errLex = 0;
    int startCom = 0;
%}

/*Macros expresiones regulares*/
digito              [0-9]
letra               [a-zA-Z_]
entero              {digito}+

/*Opciones de Flex*/
%option yylineno
%option debug

/*Condición de contexto para comentarios multilínea*/
%x comentario

%%
[ \n\t]+                            ;
"//"(.*)[\n]                        ;
"--"(.*)[\n]                        ;
"/*"                                {startCom = yylineno; BEGIN(comentario); }
<comentario>[*]+"/"                 {BEGIN(INITIAL); }
<comentario>([^*]|[*]+[^*/])*       ;
<comentario><<EOF>>                 {printf("Error léxico (línea %d): comentario sin cerrar\n", startCom);
					      				  errLex++;
										  return 0; 
                                    }
read                                return READ;
if                                  return IF;
else                                return ELSE;
while                               return WHILE;
const                               return CONST;
var                                 return VAR;
do								  	return DO;
	
print 							 	return PRINT;
"("                                 return LPAREN;		
")"                                 return RPAREN;
";"                                 return SEMICOLON;
","                                 return COMMA;
"="                                 return ASSIGN;
"+"                                 return PLUS;
"-"                                 return MINUS;
"*"                                 return MULT;
"/"                                 return DIV;
"{"                                 return LLAVEIZ;    
"}"                                 return LLAVEDE;
[^a-zA-Z0-9/();,=+*\-{}_"\n\r\t ]+   {error_lexico(yytext);}

({letra})({letra}|{digito})*        {
                                        if(yyleng>32) {
											printf("Error léxico (línea %d): identificador demasiado largo \"%s\"\n", yylineno, yytext);
											errLex++;
										}
										yylval.lexema=strdup(yytext);
										return ID;
                                    }
{entero}                            {
                                        if(atoll(yytext)> pow(2,31)){
                                            errLex++; printf("Error léxico (línea %d): entero demasiado grande\n", yylineno);
                                        } else 
										    yylval.lexema = strdup(yytext);
										    return INTLITERAL;
                                    }
\"([^"\n]|\\.)*\"					{
                                        yylval.lexema = strdup(yytext);
										return CADENA;}
\"([^"\n]|\\\")*			    	{
                                        printf("Error: cadena sin cerrar %d\n", yylineno);
										errLex++;
                                    }


%%

/*Funciones auxiliares*/
void error_lexico(const char* yytext){
    errLex++;
    printf("Error lexico en la linea %d, token %s", yylineno, yytext);
}
