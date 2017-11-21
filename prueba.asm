.text

	lw $t0, NUM_PROGS # En $t0 se almacena la cantidad de programas a instrumentar.
	la $t1, PROGS # En $t1 se almacena la direccion del arreglo de direcciones de programas a instrumentar.
	li $t3, 0 # $t3 es el contador de iteraciones
	lw $t5, 0($t1)  # $t5 contiene la direccion del programa actual ($t3).+1.
	li $v0, 10
	syscall
	
 .include "myprogs.s".