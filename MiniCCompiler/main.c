#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
extern FILE * yyin;
extern FILE * yyout;
extern int yyparse();

extern int errSin;
extern int errSem;
extern int errLex;
extern int yy_flex_debug;
extern char* yytext;
extern int noErr();
FILE * fich;
typedef struct {
    int token;
    char* lexeme;
} Token;
void printToken(int token, char* lexeme) {
    printf("Token: %d, Lexeme: %s\n", token, lexeme);
}

int main(int argc, char * argv[]) {
    int i;
    if (argc != 2) {
	printf("Uso: %s fichero.mc\n", argv[0]);
	exit(1);
    }
    
    if ((fich = fopen(argv[1], "r")) == NULL) {
        printf("Error al abrir el fichero.\n");
	perror("Error al leer el fichero.");
        exit(1);		
    }

    yyin = fich;
    yyout = stdout;
    /**Token token;
    do {
        token.token = yylex();
        token.lexeme = yytext;
        printToken(token.token, token.lexeme);
    } while (token.token != 0);  // 0 indicates end of input

    if (errLex > 0) {
        printf("Lexical errors found.\n");
    } else {
        printf("No lexical errors found.\n");
    }

    **/
    yy_flex_debug = 0;
    yyparse();
    fclose(fich);

    return 0;
}
