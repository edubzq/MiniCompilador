miniC: miniCSin.tab.c lex.yy.c listaSimbolos.c listaCodigo.c  main.c
	gcc -g lex.yy.c miniCSin.tab.c listaSimbolos.c listaCodigo.c main.c -lfl -o miniC

lex.yy.c: miniCLex.l
	flex  miniCLex.l

miniCSin.tab.c miniCSin.tab.h: miniCSin.y
	bison -d -v miniCSin.y

limpia:
	rm -f lex.yy.c miniC.tab.c miniC.tab.h miniC

run:
	./miniC prueba.mc > salida.s
