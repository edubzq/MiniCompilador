/*Analizador Sintáctico Bison*/
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdbool.h>
    #include <assert.h>
    #include <string.h>
    
    #include "listaSimbolos.h"

    extern int yylex();
    extern int yylineno;
    extern int errLex;
    void yyerror(const char* s);

    int nCad = -2; /*Contador cadena*/
    int nEtq = 1;  /*Contador etiqueta*/
    int errSin = 0; /* Número de errores sintácticos. */
    int errSem = 0; /* Número de errores semánticos. */
    char registros[10] = {0}; /*Array para registros ($)*/

    Lista tS;
    Tipo tipo;


/*Funciones auxiliares*/

    void addEntrada(char * lexema, Tipo tipo);
    void liberaReg(char* reg);

    char* concatena();
    char* concatena2();

    int isConstante(char* c);
    int perteneceTablaS(char * lexema);
    int noErr();

    char* getReg();
    char* getEtiqueta();

    void printTablaS();
    void printCod();

%}

%define parse.error verbose 
%define parse.trace
%union{
    char *lexema;
    ListaC codigo;
}

%code requires{
    #include "listaCodigo.h"
}

/* Definición del tipo de no terminales. */
%type <codigo> expression identifier_list identifier statement statement_list print_item print_list read_list declarations

/* Declaración de tokens. */
%token VAR CONST IF ELSE WHILE DO PRINT READ SEMICOLON COMMA ASSIGN PLUS MINUS MULT DIV RPAREN LPAREN LLAVEIZ LLAVEDE
%token <lexema> CADENA INTLITERAL ID

/* Asociatividad y precedencia de operadores. */
%left PLUS MINUS
%left MULT DIV
%left UMINUS

/* Aceptación de conflictos. */
%expect 1

%%
program             :   {
                            tS = creaLS();
                        } 
                            ID LPAREN RPAREN LLAVEIZ declarations statement_list LLAVEDE
                        {
                            if(noErr())
                            {           
                                printTablaS();
                                concatenaLC($6,$7);
                                printCod($6);
                            }
                            else 
                                printf("Total de errores {lexicos: %d, sintacticos: %d, semanticos: %d}\n", errLex, errSin, errSem);
                                liberaLS(tS);
                                liberaLC($6);
                        }                                                                                           
                    ;

declarations    :   declarations VAR 
                        {
                            tipo = VARIABLE;
                        }
                    identifier_list SEMICOLON
                        {
                            $$ = $1;
                            concatenaLC($$, $4);
                            liberaLC($4);
                        }

                |   declarations CONST 
                        {
                            tipo = CONSTANTE;
                        }
                    
                    identifier_list SEMICOLON
                        {
                            $$ = $1;
                            concatenaLC($$,$4);
                            liberaLC($4);
                        }
                |       {
                            $$ = creaLC();
                        }

identifier_list     :   identifier 
                            {
                                $$ = $1;
                            }
                    |   identifier_list COMMA identifier 
                            {
                                $$ = $1;
                                concatenaLC($$,$3);
                                liberaLC($3);
                            }

identifier          : ID 
                        {
                            if (!(perteneceTablaS($1))) addEntrada($1,tipo);
                            else{ 
                                errSem++;
                                printf("Variable %s ya declarada.\n", $1);
                            }
                            $$ = creaLC();
                        }

                    | ID ASSIGN expression

                        {   if (!(perteneceTablaS($1))) addEntrada($1,tipo);
                            else {
                                errSem++; 
                                printf("Variable %s declarada previamente.\n", $1);
                            }
                                $$=$3;
                                Operacion op;
                                op.op = "sw";
                                op.res = recuperaResLC($3);
                                op.arg1 = concatena("_", $1);
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                liberaReg(op.res);
                        };

statement_list      :  statement_list statement
                            {
                                $$ = $1;
                                concatenaLC($$,$2);
                            }
                    |       {
                                $$ = creaLC();
                            };
               
statement           : ID ASSIGN expression SEMICOLON
                            {
                                if (!(perteneceTablaS($1))){ 
                                    errSem++;
                                    printf("Variable %s no declarada.\n", $1);
                                } else if ((isConstante($1))){ 
                                    errSem++; 
                                    printf("Asignacion a constante\n");
                                }
                                $$=$3;
				    			Operacion op;
				    			op.op = "sw";
								op.res = recuperaResLC($3);
				    			op.arg1 = concatena("_",$1);
				    			op.arg2 = NULL;
				    			insertaLC($$,finalLC($$),op);
    							liberaReg(op.res);
                            }

                    | LLAVEIZ statement_list LLAVEDE 
                            {
                                $$ = $2;
                            }

                    | IF LPAREN expression RPAREN statement ELSE statement
                            {
                                $$=$3;
					            char *etiq = getEtiqueta();
                                char *etiq1 = getEtiqueta();
                                Operacion op;
                                op.op = "beqz";
                                op.res = recuperaResLC($3);
                                op.arg1 = etiq;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                concatenaLC($$,$5);
                                liberaLC($5);

                                op.op ="b";
                                op.res = etiq1;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);

                                op.op = "etiq";
                                op.res = etiq;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                concatenaLC($$,$7);
                                liberaLC($7);

                                op.op = "etiq";
                                op.res = etiq1;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                liberaReg(recuperaResLC($3));
                                            
                            }

                    | IF LPAREN expression RPAREN statement
                            {
                                $$=$3;
                                char *etiq = getEtiqueta();
                                Operacion op;
                                op.op = "beqz";
                                op.res = recuperaResLC($3);
                                op.arg1 = etiq;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                concatenaLC($$,$5);
                                liberaLC($5);

                                op.op = "etiq";
                                op.res = etiq;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                liberaReg(recuperaResLC($3));
                            }

                    | WHILE LPAREN expression RPAREN statement
                            {
                                $$ = creaLC();
                                char *etiq = getEtiqueta();
                                char *etiq1 = getEtiqueta();
                                Operacion op;
                                op.op = "etiq";
                                op.res = etiq;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                concatenaLC($$, $3);

                                op.op = "beqz";
                                op.res = recuperaResLC($3);
                                op.arg1 = etiq1;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                concatenaLC($$,$5);

                                op.op = "b";
                                op.res = etiq;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);

                                op.op = "etiq";
                                op.res = etiq1;
                                op.arg1 = NULL;
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                liberaReg(recuperaResLC($3));
                                                
                            }

                    | PRINT LPAREN print_list RPAREN SEMICOLON           
                            {
                                $$=$3;
                            }
                    | READ LPAREN read_list RPAREN SEMICOLON             
                            {
                                $$=$3;
                            } 
                    | DO statement WHILE LPAREN expression RPAREN SEMICOLON
                            { 
                                $$=creaLC();
                                char *etiq = getEtiqueta();
                                Operacion op1;
                                op1.op = "etiq";
                                op1.res = etiq;
                                op1.arg1 = NULL;
                                op1.arg2 = NULL;
                                insertaLC($$,finalLC($$),op1);
                                concatenaLC($$,$2);
                                liberaLC($2);
                                concatenaLC($$,$5);
                                char* comp = getReg();
                                Operacion op3;
                                op3.op = "addi";
                                op3.res = comp;
                                op3.arg1 = comp;
                                op3.arg2 = "1";
                                insertaLC($$,finalLC($$),op3);
                                Operacion op2;
                                op2.op = "blt";
                                op2.res = comp;
                                op2.arg1 = recuperaResLC($5);
                                op2.arg2 = etiq;
                                insertaLC($$,finalLC($$),op2);
                                liberaLC($5);
                                liberaReg(op2.res);
                            }; 

print_list          : print_item                          
                        {
                            $$=$1;
                        }

                    | print_list COMMA print_item         
                        {
                            $$=$1;
                            concatenaLC($$,$3);
                            liberaLC($3);
                        };

print_item          : expression                          
                        {
                            $$=$1;
                            Operacion op;
                            op.op = "move";
                            op.res = "$a0";
                            op.arg1 = recuperaResLC($1);
                            op.arg2 = NULL;

                            insertaLC($$,finalLC($$),op);
                            liberaReg(op.arg1);
                            Operacion op1;
                            op1.op = "li";
                            op1.res = "$v0";
                            op1.arg1 = "1";
                            op1.arg2 = NULL;

                            insertaLC($$,finalLC($$),op1);
                            Operacion op2;
                            op2.op = "syscall";
                            op2.res = NULL;
                            op2.arg1 = NULL;
                            op2.arg2 = NULL;

                            insertaLC($$,finalLC($$),op2);                    
                        }

                    | CADENA                              
                        {
                            addEntrada($1,TIPOCADENA); 
                            $$ = creaLC();                                              
                            Operacion op;
                            op.op = "la";
                            op.res = "$a0";
                            op.arg1 = concatena2("$str",nCad-1);
                            op.arg2 = NULL;

                            insertaLC($$,finalLC($$),op);

                            op.op = "li";
                            op.res = "$v0";
                            op.arg1 = "4";
                            op.arg2 = NULL;

                            insertaLC($$,finalLC($$),op);

                            op.op = "syscall";
                            op.res = NULL;
                            op.arg1 = NULL;
                            op.arg2 = NULL;

                            insertaLC($$,finalLC($$),op);
                        };

read_list           : ID 
                        {
                            if (!(perteneceTablaS($1)))
                            {
                                errSem++;
                                printf("Variable %s no declarada.\n", $1);
                            } else if ((isConstante($1))){
                                errSem++;
                                printf("Asignacion a constante\n");
                            }
                                $$=creaLC();
                                Operacion op;
                                op.op = "li";
                                op.res = "$v0";
                                op.arg1 = "5";
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);

                                op.op = "syscall";
                                op.res = NULL;
                                op.arg1 = NULL;
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);

                                op.op = "sw";
                                op.res = "$v0";
                                op.arg1 = concatena("_",$1);
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);
                                            
                        }

                    | read_list COMMA ID 
                        {
                            if (!(perteneceTablaS($3))){
                                errSem++;
                                printf("Variable %s no declarada.\n", $3);

                            } else if ((isConstante($3))){ 
                                errSem++;
                                printf("Asignacion a constante\n");
                            }
                                $$=$1;
                                Operacion op;
                                op.op = "li";
                                op.res = "$v0";
                                op.arg1 = "5";
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);

                                op.op = "syscall";
                                op.res = NULL;
                                op.arg1 = NULL;
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);

                                op.op = "sw";
                                op.res = "$v0";
                                op.arg1 = concatena("_",$3);
                                op.arg2 = NULL;

                                insertaLC($$,finalLC($$),op);
                                            
                        };

expression          : expression PLUS expression    
                        {
                            $$=$1;
                            concatenaLC($$,$3);
                            Operacion op;
                            op.op = "add";
                            op.res = getReg();
                            op.arg1 = recuperaResLC($1);
                            op.arg2 = recuperaResLC($3);
                            insertaLC($$,finalLC($$),op);
                            liberaLC($3);
                            guardaResLC($$,op.res);
                            liberaReg(op.arg1);
                            liberaReg(op.arg2);
                        }

                    | expression MINUS expression   
                        {
                            $$=$1;
                            concatenaLC($$,$3);
                            Operacion op;
                            op.op = "sub";
                            op.res = getReg();
                            op.arg1 = recuperaResLC($1);
                            op.arg2 = recuperaResLC($3);
                            insertaLC($$,finalLC($$),op);
                            liberaLC($3);
                            guardaResLC($$,op.res);
                            liberaReg(op.arg1);
                            liberaReg(op.arg2);
                        }

                    | expression MULT expression    
                        {
                            $$=$1;
                            concatenaLC($$,$3);
                            Operacion op;
                            op.op = "mul";
                            op.res = getReg();
                            op.arg1 = recuperaResLC($1);
                            op.arg2 = recuperaResLC($3);
                            insertaLC($$,finalLC($$),op);
                            liberaLC($3);
                            guardaResLC($$,op.res);
                            liberaReg(op.arg1);
                            liberaReg(op.arg2);
                        }

                    | expression DIV expression     
                        {
                            $$=$1;
                            concatenaLC($$,$3);
                            Operacion op;
                            op.op = "div";
                            op.res = getReg();
                            op.arg1 = recuperaResLC($1);
                            op.arg2 = recuperaResLC($3);
                            insertaLC($$,finalLC($$),op);
                            liberaLC($3);
                            guardaResLC($$,op.res);
                            liberaReg(op.arg1);
                            liberaReg(op.arg2);
                        }

                    | MINUS expression %prec UMINUS 
                        {
                            $$=$2;
                            Operacion op;
                            op.op = "neg";
                            op.res = getReg();
                            op.arg1 = recuperaResLC($2);
                            op.arg2 = NULL;
                            insertaLC($$,finalLC($$),op);
                            liberaReg(op.arg1);
                            guardaResLC($$,op.res);
                        }

                    | LPAREN expression RPAREN
                        {
                            $$=$2;
                        }

                    | ID 
                        {
                            if (!(perteneceTablaS($1))){ 
                                errSem++; printf("Variable %s no declarada.\n", $1);
                            }
                                $$ = creaLC();
                                Operacion op;
                                op.op = "lw";
                                op.res = getReg();
                                op.arg1 = concatena("_",$1);
                                op.arg2 = NULL;
                                insertaLC($$,finalLC($$),op);
                                guardaResLC($$,op.res);
                        }

                    | INTLITERAL                          
                        {
                            $$ = creaLC();
                            Operacion op;
                            op.op = "li";
                            op.res = getReg();
                            op.arg1 = $1;
                            op.arg2 = NULL;
                            insertaLC($$,finalLC($$),op);
                            guardaResLC($$,op.res);
                        };
%%

/*Funciones auxiliares*/

void yyerror(const char* s){
    errSin++;
    fprintf(stderr, "Error sintáctico (línea %d): error: /%s/ \n", yylineno, s);
}


int perteneceTablaS(char * lexema){
    if(buscaLS(tS, lexema) != finalLS(tS))
        return 1;
    return 0;
}
void addEntrada(char * lexema, Tipo tip){
    Simbolo simbolo;
    simbolo.nombre = lexema;
    simbolo.tipo = tipo;
    if (tipo = TIPOCADENA) {
        simbolo.valor = nCad;
        nCad++;
    }
    insertaLS(tS, finalLS(tS),simbolo);
}

int isConstante(char* c ){
    Simbolo simbolo;
    simbolo = recuperaLS(tS, buscaLS(tS, c));
    if(simbolo.tipo == CONSTANTE)
        return 1;
    return 0;
}
void printTablaS(){
    PosicionLista aux = inicioLS(tS);
    printf("##################\n# Seccion de datos\n\t.data\n\n");

    while(aux != finalLS(tS)){
        Simbolo s = recuperaLS(tS, aux);

        if (s.tipo == TIPOCADENA)
            printf("$str%d:\n\t.asciiz %s \n", s.valor, s.nombre);

        aux = siguienteLS(tS, aux);
    }
    aux =  inicioLS(tS);


    while(aux != finalLS(tS)){
        Simbolo s = recuperaLS(tS, aux);

        if (s.tipo == VARIABLE)
            printf("_%s:\n\t.word 0\n", s.nombre);
        if (s.tipo == CONSTANTE)
            printf("_%s:\n\t.word 0\n", s.nombre);

        aux = siguienteLS(tS, aux);
    }

}
int noErr(){
    return !(errLex + errSin + errSem);
}

void liberaReg(char * reg){
    if(reg[0] == '$' && reg[1] == 't'){
        int aux = reg[2] - '0';
        assert(aux >= 0);
        assert(aux < 9);
        registros[aux] = 0;
    }
}
char* getReg(){
    for (int i = 0; i < 10; i++) {
		if (registros[i] == 0) {
			registros[i] = 1;
			char aux[16];
			sprintf(aux,"$t%d",i);
			return strdup(aux);
		}
	}
	printf("No hay registros disponibles\n");
	exit(1);
}
char* concatena(char* a, char* b){
    char* aux = (char*)malloc(strlen(a) + strlen(b) + 1);
    sprintf(aux, "%s%s", a, b);
    return aux;
}
char* concatena2(char* a, int b){
    char* aux = (char*)malloc(strlen(a) + 11);
    sprintf(aux, "%s%d", a, b);
    return aux;
}
char* getEtiqueta(){
    char aux[32];
    sprintf(aux, "$l%d", nEtq++);
    return strdup(aux);
}
void printCod(ListaC codigo) {
  printf("###################\n");
	printf("# Seccion de codigo\n");
	printf("\t.text\n");
	printf("\t.globl main\n");
	printf("main:\n");
	PosicionListaC p = inicioLC(codigo);
	while (p != finalLC(codigo)) {
		Operacion oper;
		oper = recuperaLC(codigo,p);
		if (!strcmp(oper.op,"etiq")) printf("%s:",oper.res);
		else {  printf("\t%s",oper.op);
			if (oper.res) printf(" %s",oper.res);
			if (oper.arg1) printf(",%s",oper.arg1);
			if (oper.arg2) printf(",%s",oper.arg2);
			}
		printf("\n");
		p = siguienteLC(codigo,p);
	}
	printf("##############\n");
	printf("# Fin\n");
	printf("\tli $v0, 10\n");
	printf("\tsyscall\n");
}