# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (C) 1990-2004 James Larus, larus@cs.wisc.edu.
# ALL RIGHTS RESERVED.
#
# SPIM is distributed under the following conditions:
#
# You may make copies of SPIM for your own use and modify those copies.
#
# All copies of SPIM must retain my name and copyright notice.
#
# You may not sell SPIM or distributed SPIM in conjunction with a commerical
# product or service without the expressed written consent of James Larus.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE.
#

# $Header: $


# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080
# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which MIPS is compiled.

	move $k1 $at		# Save $at
	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.


ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14


# Restore registers and reset processor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	move $at $k1		# Restore $at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret

# Return sequence for MIPS-I (R2000):
#	rfe			# Return from exception handler
				# Should be in jr's delay slot
#	jr $k0
#	 nop



# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
	.text
	.globl __start
#	.globl main
__start:
	lw $a0 0($sp)		# argc
	addiu $a1 $sp 4		# argv
	addiu $a2 $a1 4		# envp
	sll $v0 $a0 2
	addu $a2 $a2 $v0
	jal main
	nop

	li $v0 10
	syscall			# syscall 10 (exit)

	.globl __eoth
__eoth:


	################################################################
	##
	## El siguiente bloque debe ser usado para la inicialización
	## de las estructuras de datos que Ud. considere necesarias
	## 
	## Las etiquetas PROGS, NUM_PROGS no deben bajo ABSOLUTAMENTE
	## NINGUNA RAZON ser definidas en este archivo
	##
	################################################################
	
	.data

	################################################################
	##
	## El siguiente bloque debe ser usado para la inicialización
	## del planificador que Ud. considere necesarias, 
    	## instrumentación de los programas
    	## activación de interrupciones
	## inicialización de las estructuras
	## el mecanismo que comience la ejecución del primero programa
	################################################################

	.text
	.globl main
main:






# Comienzo del instrumentador.
instrumentador:
	lw $t0, NUM_PROGS # En $t0 se almacena la cantidad de programas a instrumentar.
	lw $t1, PROGS # En $t1 se almacena la direccion del arreglo de direcciones de programas a instrumentar.
	li $t3, 0 # $t3 es el contador de iteraciones.

# Se realizaran dos corridas de instrumentador. La primera actualiza los saltos de branch.
# La segunda, agrega los breaks.
instrumentador_beq:
	beq $t3, $t0, instrumentador_break
	li $t4, 0 # $t4 lleva registro de cuantos adds habra antes de un branch,
	lw $t5, 0($t1) # $t5 contiene el codigo de operacion de la instrucion $t1.
	sra $t6, $t5, 26 # $t6 contiene el codigo de la instruccion.
	beq $t6, 4, instrumentador_beqevaluarcaso # Verificamos si es un beq.
	addi $t1, $t1, 4
	bne $t5, 0x2402000a, instrumentador_beq
	addi $t3, $t3, 1
	b instrumentador_beq
		
instrumentador_beqevaluarcaso:
	
	and $t6, $t5, 0x0000FFFF #$t6 ahora contiene el numero de instrucciones para desplazarse.
	addi $t1, $t1, 4
	blt $t6, 32768, instrumentador_beq # Verifico si es el caso 4. Revisando si $t6 es positivo.
	# El numero es negativo, complementamos para ver de cuanto es el salto.
	li $t7, 65535 # Valor del numero negativo mas grande representable en 16 bits.
	sub $t6 $t7, $t6 # $t6 ahora es la magnitud del salto.
	mul $t6, $t6, 4 # $t6 ahora contiene el offset para ver el inicio del branch.
	addi $t1, $t1, -4
	sub $t1, $t1, $t6
	div $t6, $t6, 4 # Devuelvo el cambio para contar cuantos add's hay.
	li $t7, 0 # $t7 ahora es un contador.
	li $t9, 0 # $t9 Contador de adds.
instrumentador_contaraddbeq:
	lw $t5, 0($t1) # $t5 contiene el codigo de operacion de la instrucion $t1.
	beq $t7, $t6, instrumentador_modificarbeq
	and $t8, $t5, 0x0000003F
	addi $t1, $t1, 4
	addi $t7, $t7, 1
	bne $t8, 32, instrumentador_contaraddbeq
	addi $t9, $t9, 1
	b instrumentador_contaraddbeq
instrumentador_modificarbeq:
	# Verificar que no haya desborde en el salto del branch (16 bits)
	sub $t5, $t5, $t9
	sw $t5, ($t1)
	addi $t1, $t1, 4
	b instrumentador_beq

instrumentador_break:
	#0x0000080d Codigo del break 20.
	#0x0000040d Codigo del break 10.
	# Nueva inicializacion del insturmentador.	
	lw $t0, NUM_PROGS # En $t0 se almacena la cantidad de programas a instrumentar.
	lw $t1, PROGS # En $t1 se almacena la direccion del arreglo de direcciones de programas a instrumentar.
	li $t3, 0 # $t3 es el contador de iteraciones.
	li $t2, 0 # $t2 es la direccion de finalizacion de un programa.
	move $t2, $t1 # Para poder instrumentar el primer programa. 
	# Se cuentan el total de add's que hay en el programa.
instrumentador_adds:
	li $t4, 0 # $t4 es un contador de add's.
	move $t1, $t2
instrumentador_adds2:
	beq $t3, $t0, instrumentador_salida
	lw $t5, 0($t1) # $t5 contiene el codigo de operacion de la instrucion $t1.
	addi $t1, $t1, 4 # me muevo a la siguiente instruccion
	and $t6, $t5, 0x0000003F # $t6 contiene cod de funct. Mascara para saber si la instruccion es un add.
	beq $t5, 0x2402000a, instrumentador_addsendprogram #verifico si la instruccion es un li $v0, 10.
	bne $t6, 32, instrumentador_adds2 # verifico si la instruccion actual es un add.
	addi $t4, $t4, 1 # si lo es sumo uno al contador.
	b instrumentador_adds2
instrumentador_addsendprogram:
	addi $t1, $t1, -4 # me paro en li $v0, 10
	addi $t3, $t3, 1
	li $t8, 0x0000040d # $t8 contiene una instruccion.
	sw $t8, ($t1) # Se sustituye el li $v0, 10 por un break 0x10.
	addi $t1, $t1, 4 # Actualmente estamos en el syscall.
	
	# Se procede a agregar los breaks ya que se llego a la ultima linea del programa.
instrumentador_moverinstrucciones:
	
	mul $t7, $t4, 4 #$t7 ahora contiene la cantidad de saltos de las instrucciones.
	addi $t1, $t1, 4 # Actualmente estamos en el siguiente programa.
	add $t2, $t1, $t7 # $t2 contiene direccion del siguiente programa contando los NOP.
	addi $t1, $t1, -4 # Actualmente estamos en el final de p $t3.	
	bnez $t7, instrumentador_moverinstrucciones2
	b instrumentador_adds
	
instrumentador_moverinstrucciones2:

	move $t9, $t1 # $t9 se utilizara como la nueva direccion de instruccion.
	lw $t8, ($t1) # $t8 contiene una instruccion.
	and $t6, $t8, 0x0000003F # $t6 contiene cod de funct. Mascara para saber si la instruccion es un add.
	beq $t6, 32, instrumentador_agregarbreak # verifico si la instruccion actual es un add.
	add $t9, $t9, $t7
	sw $t8, ($t9)
	addi $t1,$t1, -4
	b instrumentador_moverinstrucciones2
	
instrumentador_agregarbreak:

	add $t7, $t7, -4 # Se disminuye el salto pues se encontro un add.
	add $t9, $t9, $t7
	sw $t8, ($t9)
	addi $t9, $t9, 4 # Me muevo a la siguiente instrucion del add.
	li $t8, 0x0000080d # Cargo break 0x20
	sw $t8, ($t9) # Almaceno el break en la direccion deseada.
	addi $t1,$t1, -4
	beqz $t7, instrumentador_adds # Termine de agregar breaks, me muevo al siguiente programa.
	b instrumentador_moverinstrucciones2

instrumentador_salida:
	li $v0, 0
	
fin:
	li $v0 10
	syscall			# syscall 10 (exit)
	
.include "myprogs.s"
