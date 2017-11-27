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
	#move $a1, $a0
	# srl $a1, $a1, 6
	andi $a0 $a0 0x1f
	# andi $a1, $a1, 0xff
	# beqz $a1, interrupcion_teclado
	beqz $a0, interrupcion_teclado	
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
	lw $t5, NUM_PROGS
	lw $t2, informacion # Se almacena en $t2 la direccion de inicio del arreglo de informacion.
	li $t3, 0
	mul $t3, $t1, 16
	add $t2, $t2, $t3
	addi $t2, $t2, 8 # Se almacena en $t2 la direccion donde se encuentra la informacion si finalizo o no el programa.
	li $t4, 1
	sw $t4, ($t2) # Se asigna 1 como contenido de $t2, que hace referencia a que el programa ya finalizo.
	addi $t5, $t5, -1
	addi $t1, $t1, 1
	lw $t7, 0
	
break_0x10_revisanofinalizado:
	sw $t1, programa_actual
	bgt $t1, $t5, break_0x10_vuelta
	lw $t2, informacion
	move $t6, $t1
	mul $t6, $t6, 16
	add $t6, $t6, 8
	lw $t6, ($t6)
	addi $t1, $t1, 1
	addi $t7, $t7, 1
	beq $t7, $t5, fin
	beq $t6, 1, break_0x10_revisanofinalizado
	b cargar_ambiente
	
break_0x10_vuelta:
	li $t1, 0 # Si el antiguo programa actual era el ultimo colocamos como programa actual el primero
	b break_0x10_revisanofinalizado
	
	# Print information about exception.
	#
interrupcion_teclado: 
	li $v0, 1
	li $a0, 3
	syscall
	li $t1, 3
	sw $t1, 0xffff0000
	b ret
guardar_ambiente:

	b cargar_ambiente
	
cargar_ambiente:
	lw $t1, programa_actual
	mul $t1, $t1, 16
	add $t1, $t2, $t1
	move $k0, $t1
	addi $t1, $t1, 4
	lw $t1, ($t1)
	lw $at, 0($t1)
	lw $v0, 4($t1)
	lw $v1, 8($t1)
	lw $a0, 12($t1)
	lw $a1, 16($t1)
	lw $a2, 20($t1)
	lw $a3, 24($t1)
	lw $t0, 28($t1)
	lw $t2, 36($t1)	
	lw $t3, 40($t1)
	lw $t4, 44($t1)
	lw $t5, 48($t1)
	lw $t6, 52($t1)
	lw $t7, 56($t1)
	lw $s0, 60($t1)
	lw $s1, 64($t1)
	lw $s2, 68($t1)
	lw $s3, 72($t1)
	lw $s4, 76($t1)
	lw $s5, 80($t1)
	lw $s6, 84($t1)
	lw $s7, 88($t1)
	lw $t8, 92($t1)
	lw $t9, 96($t1)
	lw $gp, 100($t1)
	lw $sp, 104($t1)
	lw $fp, 108($t1)
	lw $ra, 112($t1)
	lw $t1, -80($t1)
	jr $k0
	
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
	li $t1, 3
	sw $t1, 0xffff0000
	# Instrumentador de instrucciones.

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
 
	# Inicializacion de las estructuras a utilizar.

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
	beq $t1, $t0,correr_programa  # Reviso si inicialice la informacion de todos los programas
	lw $t2, informacion # Almacenamos en $t2 la direccion de inicio del arreglo de informacion
	li $a0, 116 # Almacenamos en $a0 la cantidad de bytes que queremos reservar para la informacion del ambiente de cada
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
	
correr_programa:
	lw $t1, PROGS
	jr $t1	
	
fin:
	li $v0 10
	syscall			# syscall 10 (exit)

	.include "myprogs.s"
