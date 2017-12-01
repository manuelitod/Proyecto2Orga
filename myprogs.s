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
	li $t0, 0
	li $t1, 0
	li $v0 4
	la $a0 m1
	syscall
	beq $t0, $t1, p1
	li $v0, 10
	syscall
	nop
	

p2:
	li $t0, 0
	li $t1, 0
	li $v0 4
	la $a0 m2
	syscall
	beq $t0, $t1, p2
	li $v0, 10
	syscall
	nop

p3:
	li $t0, 0
	li $t1, 0
	li $v0 4
	la $a0 m3
	syscall
	beq $t0, $t1, p3
	li $v0, 10
	syscall
	nop
