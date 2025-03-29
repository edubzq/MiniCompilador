##################
# Seccion de datos
	.data

$str-1:
	.asciiz b 
$str2:
	.asciiz "Inicio del programa\n" 
$str3:
	.asciiz "a" 
$str4:
	.asciiz "\n" 
$str5:
	.asciiz "No a y b\n" 
$str6:
	.asciiz "c = " 
$str7:
	.asciiz "\n" 
$str8:
	.asciiz "Final del programa\n" 
_a:
	.word 0
_d:
	.word 0
_c:
	.word 0
###################
# Seccion de codigo
	.text
	.globl main
main:
	li $t0,0
	sw $t0,_a
	li $t0,0
	sw $t0,_b
	li $t0,10
	sw $t0,_d
	li $t0,5
	li $t1,2
	add $t2,$t0,$t1
	li $t0,2
	sub $t1,$t2,$t0
	sw $t1,_c
	la $a0,$str2
	li $v0,4
	syscall
	lw $t0,_a
	beqz $t0,$l5
	la $a0,$str3
	li $v0,4
	syscall
	la $a0,$str4
	li $v0,4
	syscall
	b $l6
$l5:
	lw $t1,_b
	beqz $t1,$l3
	la $a0,$str5
	li $v0,4
	syscall
	b $l4
$l3:
$l1:
	lw $t2,_c
	beqz $t2,$l2
	la $a0,$str6
	li $v0,4
	syscall
	lw $t3,_c
	move $a0,$t3
	li $v0,1
	syscall
	la $a0,$str7
	li $v0,4
	syscall
	lw $t3,_c
	li $t4,1
	sub $t5,$t3,$t4
	sw $t5,_c
	b $l1
$l2:
$l4:
$l6:
$l7:
	la $a0,$str8
	li $v0,4
	syscall
	lw $t0,_d
	addi $t1,$t1,1
	blt $t1,$t0,$l7
##############
# Fin
	li $v0, 10
	syscall
