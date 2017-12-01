#Programa:	 myprogs.s
#Autor:	 profs del taller de organizaciòn del computador
#Fecha:	11 Nov 2017

# Obs: Esto es un ejemplo de como podría ser un programa principal a
#	usarse en el proyecto.
# Para la corrida de los proyectos el grupo profesoral generara
# varios archivos con características similares
# Asegùrese de crear varios casos de prueba para verificar sus
# implementaciones
		
	.data
	.globl PROGS
	.globl NUM_PROGS

NUM_PROGS:	.word 3
PROGS:	.word p1, p2, p3
	
m1:	.asciiz "p1\n"
m2:	.asciiz "p2\n"
m3:	.asciiz "p3\n"
	
	.text

p1:
	add $v0, $v0, $t1
	add $v0, $v0, $t1	
	li $v0 4
	la $a0 m1
	syscall
	add $v0, $v0, $t1
	syscall
	beq $v0, $t1, p1
	li $t9, 0
	
	add $v0, $v0, $t1

	li $v0, 10
        syscall
        nop
        nop
        nop
        nop

p2:	

	add $v0, $v0, $t1
	li $v0 4
	la $a0 m2
	syscall
	li $t6, 2
p2x:
	li $t8, 2
	add $t7, $t7, $t8
	add $v0, $v0, $t1
	add $v0, $v0, $t1
	li $v0 4
	add $v0, $v0, $t1
	beq $t7, $t6, p2x
	
        add $t1, $t1, $t1
        li $t0 3
        li $t1 0
	
	li $v0, 10
	syscall
	nop
	nop
	nop
	nop
	nop
	

p3:	
	li $t0 3
        li $t1 0
p3_aux:
	add $v0, $v0, $t6
	addi $t1, $t1, 1
	add $v1, $v0, $v1
	li $v0 4
	la $a0 m3
	syscall
	bne $t0, $t1, p3_aux

	add $v0, $v0, $t6
	add $v1, $v0, $v1
	add $v0, $v0, $t6
	add $v1, $v0, $v1
	li $v0, 10
	syscall
	nop
	nop
	nop
	nop
	nop
	nop
	
