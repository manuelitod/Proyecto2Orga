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
 
 .include "myprogs.s".
		
		
		
	
	
	


	
