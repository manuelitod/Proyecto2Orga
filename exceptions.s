# Instrumentador de instrucciones.

.data

.text

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
	bne $t5, 11, instrumentador_beq
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
	li $t7, 1 # $t7 ahora es un contador.
	li $t9, 0 # Contador de adds.
instrumentador_contaraddbeq:
	lw $t5, 0($t1) # $t5 contiene el codigo de operacion de la instrucion $t1.
	beq $t7, $t6, instrumentador_modificarbeq
	and $t8, $t5, 0x0000003F
	addi $t1, $t1, 4
	addi $t7, $t7, 1
	bne $t9, 32, instrumentador_contaraddbeq
	addi $t9, $t9, 1
	b instrumentador_contaraddbeq
instrumentador_modificarbeq:
	# Verificar que no haya desborde en el salto del branch (16 bits)
	sub $t5, $t5, $t9
	sw $t5, ($t1)
	addi $t1, $t1, 4
	b instrumentador_beq

instrumentador_break:
 
 .include "myprogs.s".
		
		
		
	
	
	


	
