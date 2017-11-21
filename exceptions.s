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
		beq $t3, $t0, insturmentador_break
		li $t4, 0 # $t4 lleva registro de cuantos adds habra antes de un branch,
		la $t5, 0($t1) # $t5 contiene la direccion del programa actual ($t3).+1.
		lw $t6, 
		
		
	
	
	


	