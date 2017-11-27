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
	mfc0 $k1 $14	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f	
	bne $a0, 9, imprimir_error # Si la excepcion no se debe a un break se imprime el mensaje correspondiente.
	lw $t5, ($k1)	# Almacenamos en $t5 el codigo de operacion del break.
	andi $t5, 0x03ffffc0 # Revisamos cual es el codigo del break.
	beq $t5, 1024, break_0x10 # Se filtra si el break es 0x10.
	beq $t5, 2048, break_0x20 # Se filtra si el break es 0x20.
	b imprimir_error # Si el break no es de los dos tipos antes mencionados se imprime el mensaje correspondiente.
break_0x20:
	lw $t1, programa_actual # Se almacena en $t1 el numero del programa actual.
	lw $t2, informacion # Se almacena en $t2 la direccion de inicio del arreglo de informacion.
	li $t3, 0
	mul $t3, $t1, 16 
	add $t2, $t2, $t3
	addi $t2, $t2, 12 # Se almacena en $t2 la direccion donde se encuentra la informacion de la cantidad de ands del programa
	lw $t4, ($t2) # Almacenamos en $t4 la cantidad de ands del programa.
	addi $t4, $t4, 1 # Aumentamos el contenido de $t4 en uno.
	sw $t4, ($t2)
	b ret
break_0x10:
	lw $t1, programa_actual # Se almacena en $t1 el numero del programa actual.
	lw $t2, informacion # Se almacena en $t2 la direccion de inicio del arreglo de informacion.
	li $t3, 0
	mul $t3, $t1, 16
	add $t2, $t2, $t3
	addi $t2, $t2, 8 # Se almacena en $t2 la direccion donde se encuentra la informacion si finalizo o no el programa.
	li $t4, 1
	sw $t4, ($t2) # Se asigna 1 como contenido de $t2, que hace referencia a que el programa ya finalizo.
	b ret
	
	# Print information about exception.
	#
imprimir_error:
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
informacion: .space 4
programa_actual: .word 0
instruccion_actual: .word 0
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
	li $t1,0 # Almacenamos en $t1 el indice del programa actual
	lw $t0, NUM_PROGS # Almacenamos en $t0 el numero de programas.
inicializar_informacion:
	lw $a0, NUM_PROGS # Almacenamos en $t0 el numero de programas.
	mul $a0, $a0, 16 # Por cada programa reservo 12 bytes para informacion. 4 para la direccion actua, 4 para el ambiente,
			 # 4 para saber si el programa ya finalizo y 4 para saber la cantidad actual de adds en el programa.
	li $v0, 9
	syscall
	sw $v0, informacion # Almacenamos la direccion de inicio del arreglo de informacion en la etiqueta "informacion".
	
inicializar_ambiente:
	beq $t1, $t0,fin  # Reviso si inicialice la informacion de todos los programas
	lw $t2, informacion # Almacenamos en $t2 la direccion de inicio del arreglo de informacion
	li $a0, 120 # Almacenamos en $a0 la cantidad de bytes que queremos reservar para la informacion del ambiente de cada
		    # programa
	li $v0, 9
	syscall # Hacemos el syscall de reserva de espacio
	li $t3, 0 # Almacenaremos en $t3 el desplazamiento en el arreglo de informacion donde guardaremos al informacion del 
		  # programa actual
	mul $t3, $t1, 16 # Nos desplazamos de 16 en 16 en el arreglo de informacion del programa
	add $t2, $t3, $t2 # Aumentamos el numero contenido en $t2 para movernos por el arreglo de informacion.
	mul $t6, $t1, 4 # Almacenamos en $t6 el desplazamiento en PROGS del programa actual.
	lw $t4, PROGS($t6) # Almacenamos en $t4 la direccion de inicio del programa.
	sw $t4, ($t2) # Guardamos en los primeros 4 bytes de la posicion actual del arreglo la direccion actual del 
				 # programa al que hace referencia.
	addi $t2, $t2, 4 # Nos movemos a los segundos 4 bytes.
	sw $v0, ($t2) # Almacenamos en los segundos 4 bytes de la posicion actual del arreglo la direccion del inicio
		      # del espacio de memoria reservado.
	addi $t2, $t2, 4 # Nos movemos a los terceros 4 bytes.
	li $t5, 0 
	sw $t5, ($t2) # Almacenamos en los terceros 4 bytes de la posicion actual del arreglo si el programa asociado
				 # ya finalizo (0 si no ha finalizad, 1 en caso contrario).
	addi $t2, $t2, 4  # Nos movemos a los cuartos 4 bytes.
	sw $t5, ($t2) # Almacenamos en los cuartos 4 bytes la cantidad actual de adds ejecutados en el programa.		 
	addi $t1, $t1, 1
	b inicializar_ambiente
	
fin:
	li $v0 10
	syscall			# syscall 10 (exit)

	.include "myprogs.s"