# Jeff Bulick
# ECE 201
# MIPS Program 4
# Stage 2
# 4.30.17

# This program is a simple simulator for a subset of MIPS instructions.
# This simulator is written in MIPS assembly to further gain knowledge 
# on the stored-program concept.  This simulator handles R, I, and J type
# instructions.  The example instructions loaded into memory represent
# a childish division program that divides 14 by 7 through repeated subtraction.


.data
	pc: .asciiz "pc="
	ir: .asciiz " ir="
	aval: .asciiz " a="
	bval: .asciiz " b="
	alu: .asciiz " aluout="
	v0: .asciiz "     v0="
	a0: .asciiz " a0="
	a1: .asciiz " a1="
	t1: .asciiz " t1="
	t2: .asciiz " t2="
	t4: .asciiz " t4="
	s1: .asciiz "     s1="
	s2: .asciiz " s2="
	s3: .asciiz " s3="
	s4: .asciiz " s4="
	s5: .asciiz " s5="
	br: .asciiz "\n"  
	done: .asciiz "done"
	memBounds: .asciiz "memory out of bounds "
	unimp: .asciiz "unimplemented instruction "
	 m: .word 0x8c040030,	#load example program into memory
		.word 0x8c050034,
		.word 0x8c0b0038,
		.word 0x00044820,
		.word 0x00005020,
		.word 0x0125602a,
		.word 0x118b0003,
		.word 0x01254822,
		.word 0x014b5020,
		.word 0x08000005,
		.word 0x01401020,
		.word 0x08000010,
		.word 0x0000000e,
		.word 0x00000007,
		.word 0x00000001,
		.word 0x00000000,
		.word 0xac0a003c,
		.word 0x8c11003c,
		.word 0x1000ffff
	#initialize 32 registers in memory to 0
	r: .word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000,
		.word 0x00000000, 
		.word 0x00000000
.text
.globl main
main:
	
#main variable locations
	#opcode t9
	#pc		a0
	#ir		a1
	#a		a2
	#b		a3
	#aluout	s0
	#sentinel s1
	#m(addr) s2
	
	li $t9,0		#opcode = 0
	li $a0,0		#pc = 0
	li $a1,0		#ir = 0
	li $a2,0		#a = 0
	li $a3,0		#b = 0
	li $s0,0		#aluout = 0
	
	#load sentinel equivalent into a register 0x1000ffff
	lui $s1, 4096
	ori $s1, $s1, 65535
	#retrieve data array address
	la $s2, m
	
	li $t4,0  #initialize counter
Loop: 
	sll $t5, $t4, 2  #mult by 4
	add $a0, $s2, $t5   #pc = m + (counter*4)
	#address_check(pc);
	jal Addrcheck
	lw $a1, 0($a0)	#ir = address of elment in m
	beq $a1, $s1, Exit
	###########
	addi $sp,$sp,-24
	sw $s0,20($sp)	#store aluout
	sw $a3,16($sp)	#store b
	sw $a2,12($sp)	#store a
	sw $t4,8($sp)	#store counter
	sw $a0,4($sp)	#store pc
	sw $a1,0($sp)	#store ir
	#a = r[extract(ir,25,21)];
	move $a0,$a1	#move ir to Extract x argument
	li $a1,25		#set left argument
	li $a2,21		#set right argument
	jal Extract		#v0 = rs register number
	sll $t0,$v0,2	#mult register number by 4
	la $t1,r		#address of r
	add $t0,$t0,$t1	# = r + (reg*4)
	lw $a2, 0($t0)	#a = value in rs = bits 25-21
	sw $a2,12($sp)	#hold a value on stack
	#b = r[extract(ir,20,16)];
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,20		#set left argument
	li $a2,16		#set right argument
	jal Extract		#v0 = rt register number
	sll $t0,$v0,2	#mult register number by 4
	la $t1,r		#address of r
	add $t0,$t0,$t1	# = r + (reg*4)
	lw $a3, 0($t0)	#b = value in rt = bits 20-16
	sw $a3,16($sp)	#hold b value on stack
	
	#aluout = pc + (signext(extract(ir,15,0))<<2);
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,15		#set left argument
	li $a2,0		#set right argument
	jal Extract
	move $a0,$v0
	jal Signext
	sll $t0,$v0,2			
	lw $a0,4($sp)	#load pc
	add $s0,$a0,$t0
	sw $s0,20($sp)	#store aluout on stack
	
	#opcode = extract(ir,31,26);
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,31		#set left argument
	li $a2,26		#set right argument
	jal Extract
	move $t9,$v0	#opcode = $t9
	
	
Main0:		#R-type
	#if(opcode == 0)
	bne $t9,$zero,Main1
	#extract(ir,10,0)
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,10		#set left argument
	li $a2,0		#set right argument
	jal Extract
	#aluout = alufunc(a,b,extract(ir,10,0));
	move $a0,$v0	#set Alufunc func argument
	lw $a1,12($sp)	#load a -> set Alufunc a argument
	lw $a2,16($sp)	#load b -> set Alufunc b argument
	jal Alufunc
	move $s0,$v0	#aluout = $s0
	sw $s0,20($sp)	#store aluout on stack
	#extract(ir,15,11)
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,15		#set left argument
	li $a2,11		#set right argument
	jal Extract		#$v0 = extract(ir,15,11)
	#if (extract(ir,15,11) != 0)
	beq $v0,$zero,Endloop
	#r[extract(ir,15,11)] = aluout;
	sll $t0,$v0,2	#mult register number by 4
	la $t1,r		#address of r
	add $t0,$t0,$t1	# = r + (reg*4)
	sw $s0, 0($t0)	#rd = aluout	
	j Endloop
	
Main1:		#jump
	#else if (opcode==2)
	li $t0,2
	bne $t9,$t0,Main2
	
	#extract(ir,25,0)
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,25		#set left argument
	li $a2,0		#set right argument
	jal Extract		

	#handle pc based on counter change in loop implementation
	#pc = (extract(pc,31,28)<<28) | (extract(ir,25,0)<<2);
	add $t4,$zero,$v0
	addi $t4,$t4,-1	#adjust for counter increment in loop	##################
	sw $t4,8($sp)	#store counter
	
	j Endloop
	
Main2: 		#beq
	#else if (opcode==4)
	li $t0,4
	bne $t9,$t0,Main3
	
	#handle pc based on counter change in loop implementation
	#pc = ((a==b)? aluout : pc); -> if(a==b){pc = aluout} else{pc = pc}
	lw $a2,12($sp)	#load a 
	lw $a3,16($sp)	#load b
	lw $s0,20($sp)	#load aluout
	bne $a2,$a3,Endloop
	la $s2, m			#retrieve data array address
	sub $a0,$s0,$s2		#aluout minus pc(start address)
	srl $t4,$a0,2		#divide by 4
	sw $t4,8($sp)	#store counter
	
	j Endloop
	
Main3:		#lw,sw
	#else if ((extract(ir,31,30)==2)&&(extract(ir,28,26)==3)) 
	# //lw,sw: 35 or 43, in binary: 10x011
	
	#if(extract(ir,31,30) == 2)
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,31		#set left argument
	li $a2,30		#set right argument
	jal Extract
	move $t0,$v0	
	li $t1,2
	bne $t0,$t1,Main4	#go to upper scope else
	#if(extract(ir,28,26) == 3)
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,28		#set left argument
	li $a2,26		#set right argument
	jal Extract
	move $t0,$v0	
	li $t1,3
	bne $t0,$t1,Main4	#go to upper scope else
	#########################
	
	#aluout = a + signext(extract(ir,15,0));
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,15		#set left argument
	li $a2,0		#set right argument
	jal Extract
	move $a0,$v0
	jal Signext
	lw $a2,12($sp)	#load a 
	add $s0,$v0,$a2	#set aluout in $s0
	sw $s0,20($sp)	#store aluout on stack
	
	#address_check(aluout);
	move $a0,$s0
	jal Addrcheck
	
	#if (extract(ir,29,29)) -> SW instr
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,29		#set left argument
	li $a2,29		#set right argument
	jal Extract
	move $a0,$v0
	li $t0,1
	bne $a0,$t0,LWinstr
	#SW instr
	move $a0,$s0	#move aluout into $a0
	la $s2, m	#retrieve data memory address
	add $a0,$a0,$s2		# aluout >> 2
	lw $a3,16($sp)	#load b
	sw $a3,0($a0)	# m[aluout>>2] = b;
	
	j Endloop
	
LWinstr:
	move $a0,$s0
	la $s2, m	#retrieve data memory address
	add $a0,$a0,$s2		# aluout >> 2
	lw $a0,0($a0)		# mdr = m[aluout>>2];
	move $s7,$a0		#move mdr into $s7
	#r[extract(ir,20,16)] = mdr;
	lw $a0,0($sp)	#load ir to Extract x argument
	li $a1,20		#set left argument
	li $a2,16		#set right argument
	jal Extract		#v0 = rt register number
	#if (extract(ir,20,16) != 0) 
	beq $zero,$v0,Endloop	#hardware protection
	sll $t0,$v0,2	#mult register number by 4
	la $t1,r		#address of r
	add $t0,$t0,$t1	# = r + (reg*4)
	sw $s7, 0($t0)	#value in rt = mdr
	
	j Endloop
	
Main4:		#instr not implemented in simulator
	lw $a1,0($sp)	#load ir 
	jal Unimplemented

Endloop:	
	lw $a1,0($sp)	#load ir 
	lw $a0,4($sp)	#load pc
	lw $t4,8($sp)	#load counter
	lw $a2,12($sp)	#load a
	lw $a3,16($sp)	#load b
	lw $s0,20($sp)	#load aluout
	addi $sp,$sp,24
	###########
	jal Traceout	#print data to console
	addi $t4, $t4, 1  	#increment counter
	j Loop

Exit:
	la $a0, done # Set a0 to string for input
	li $v0, 4 # Set system code call for print_st
	syscall # Print string

	li $v0, 10 # Set system call to exit
	syscall # Perform exit from program
	
	
#void unimplemented()
Unimplemented:
	la $a0, unimp # Set a0 to string for input
	li $v0, 4 # Set system code call for print_st
	syscall 
	move $a0,$a1
	jal Printhex
	la $a0, br # Set a0 to string for input
	li $v0, 4 # Set system code call for print_st
	syscall 
	j Exit		#terminate program
	
#void address_check(unsigned long addr)
Addrcheck:
	addi $sp,$sp,-8
	sw $ra,4($sp)
	sw $a0,0($sp)
	la $t0, m
	addi $t0,$t0,72 	#address Max = mAddress + (19instr * 4)
	sltu $t1,$t0,$a0	#if(addr > address Max)
	beq $t1,$zero,Addrcheck1
	la $a0, memBounds # Set a0 to string for input
	li $v0, 4 # Set system code call for print_st
	syscall 
	lw $a0,0($sp)
	jal Printhex
	la $a0, br # Set a0 to string for input
	li $v0, 4 # Set system code call for print_st
	syscall 
	j Exit		#terminate program
Addrcheck1:
	lw $a0,0($sp)
	lw $ra,4($sp)
	addi $sp,$sp,8
	jr $ra
	
	
#long signext(short x)
Signext: 
	srl $t1,$a0,15		#look at 16th bit
	bne $t1,$zero,Signext1
	#(x == 0xxx xxxx xxxx xxxx)
	lui $t0,0x0000
	or $v0,$t0,$a0
	j Signext2
Signext1:
	#(x == 1xxx xxxx xxxx xxxx)
	lui $t0,0xffff
	or $v0,$t0,$a0
Signext2:
	jr $ra	
	
#long alufunc(long a, long b, int func)
Alufunc:	#add
	li $t0,32
	bne $a0,$t0,Alufunc2
	add $v0,$a1,$a2
	j AlufuncX
Alufunc2:	#sub
	li $t0,34
	bne $a0,$t0,Alufunc3
	sub $v0,$a1,$a2
	j AlufuncX
Alufunc3:	#and
	li $t0,36
	bne $a0,$t0,Alufunc4
	and $v0,$a1,$a2
	j AlufuncX
Alufunc4:	#or
	li $t0,37
	bne $a0,$t0,Alufunc5
	or $v0,$a1,$a2
	j AlufuncX
Alufunc5:	#nor
	li $t0,39
	bne $a0,$t0,Alufunc6
	nor $v0,$a1,$a2
	j AlufuncX
Alufunc6:	#slt
	li $t0,42
	bne $a0,$t0,Alufunc7
	slt $v0,$a1,$a2
	j AlufuncX
Alufunc7:	#else
	li $v0,0
AlufuncX:
	jr $ra
	
#long extract(long x, int left, int right)
Extract:
	li $t0,1
	li $t1,31
	bne $a1,$t1,Extract2	#if(left==31)
	lui $t0,65535
	ori $t0,$t0,65535		#mask = 0xffffffff
	j Extract3 	
Extract2:
	addi $t1,$a1,1
	sll $t1,$t0,$t1
	addi $t0,$t1,-1			#mask = (mask << (left+1)) - 1;
Extract3:	
	and $v0,$a0,$t0			#result = x & mask;
	beq $a2,$zero,Extract4	#if (right!=0)
	srl $v0,$v0,$a2			#result = result >> right;
Extract4:
	jr	$ra					#return (result);
	
	
#void hexdig(long dig)
Hexdig:
	slti $t0,$a0,10		#if (dig < 10)
	beq $t0,$zero,Hexdig2
	#printf
	li $t0,'0'
	add $a0,$a0,$t0
	li $v0, 11 # Set system code call for print_char
	syscall # Print char
	j Hexdig3
Hexdig2:
	#printf
	li $t0,'A'
	addi $t0,$t0,-10
	add $a0,$a0,$t0
	li $v0, 11 # Set system code call for print_char
	syscall # Print char
Hexdig3:
	jr $ra
	
#void printhex(long x)
Printhex:
	#add $ra to the stack
	addi $sp,$sp,-8
	sw $ra,4($sp)
	sw $a0,0($sp)
	li $a1,31
	li $a2,28
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,27
	li $a2,24
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,23
	li $a2,20
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,19
	li $a2,16
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,15
	li $a2,12
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,11
	li $a2,8
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,7
	li $a2,4
	jal Extract
	move $a0,$v0
	jal Hexdig
	lw $a0,0($sp)
	li $a1,3
	li $a2,0
	jal Extract
	move $a0,$v0
	jal Hexdig
	#load $ra from stack
	lw $a0,0($sp)
	lw $ra,4($sp)
	addi $sp,$sp,8
	jr $ra
	
#void traceout()
Traceout:
	addi $sp,$sp,-24
	sw $ra,20($sp)
	sw $s0,16($sp)
	sw $a3,12($sp)
	sw $a2,8($sp)
	sw $a1,4($sp)
	sw $a0,0($sp)
	#"pc= "
	la $a0,pc
	li $v0,4 
	syscall 
	lw $a0,0($sp)
	jal Printhex
	#" ir="
	la $a0,ir
	li $v0,4 
	syscall 
	lw $a0,4($sp)
	jal Printhex
	#" a= "
	la $a0,aval
	li $v0,4 
	syscall 
	lw $a0,8($sp)
	jal Printhex
	#" b="
	la $a0,bval
	li $v0,4 
	syscall 
	lw $a0,12($sp)
	jal Printhex
	#" aluout="
	la $a0,alu
	li $v0,4 
	syscall 
	lw $a0,16($sp)
	jal Printhex
	#line break
	la $a0,br
	li $v0,4 
	syscall
	#"     v0="
	la $a0,v0
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,8($a0)
	jal Printhex
	#" a0="
	la $a0,a0
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,16($a0)
	jal Printhex
	#" a1="
	la $a0,a1
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,20($a0)
	jal Printhex
	#" t1="
	la $a0,t1
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,36($a0)
	jal Printhex
	#" t2="
	la $a0,t2
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,40($a0)
	jal Printhex
	#" t4="
	la $a0,t4
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,48($a0)
	jal Printhex
	#line break
	la $a0,br
	li $v0,4 
	syscall
	#"    s1="
	la $a0,s1
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,68($a0)
	jal Printhex
	#" s2="
	la $a0,s2
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,72($a0)
	jal Printhex
	#" s3="
	la $a0,s3
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,76($a0)
	jal Printhex
	#" s4="
	la $a0,s4
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,80($a0)
	jal Printhex
	#" s5="
	la $a0,s5
	li $v0,4 
	syscall
	la $a0, r
	lw $a0,84($a0)
	jal Printhex
	#line break
	la $a0,br
	li $v0,4 
	syscall
	lw $a0,0($sp)
	lw $a1,4($sp)
	lw $a2,8($sp)
	lw $a3,12($sp)
	lw $s0,16($sp)
	lw $ra,20($sp)
	addi $sp,$sp,24
	jr $ra	
	
	