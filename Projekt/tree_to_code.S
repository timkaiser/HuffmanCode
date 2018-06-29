;# AUTHOR: TIM KAISER
;#=== Tree to code ================================================
;# INPUT: Tree
;# OUTPUT: Tabelle with bit codes

;#.extern printf

.globl _asm_tree_to_code
.code 32
_asm_tree_to_code:
	;# r0: error output
	;# r1: pointer for table (output)
	;# r2: counter for bit code
	;# r3: storeage for current node
	;# r4: pointer for tree (input)
	
	push {r1-r4,FP,lr}		;#				-- Methode body
	mov FP,SP		
	
	sub r0,r0,#1
	mov r4, r0			;#				-- Move pointer for tree to r4 to make space for output
	mov r0, #1			;#				-- Initialize r0 as output


	mov r2, #1			;# r2 = 2;			-- Initialize code counter r2 = 0b1 (we need a leading 1 so that we know where the bitcode starts)

dowhile:				;#				-- Start of the loop
;#do
;#if
	ldrb r3, [r4], #-1 		;# if( tree[i] != 0 )		-- look if current position in the tree is a leaf. if it is, store char and code (+ increase r4 by 1)
	TST r3, #0b11111111
	beq else
	

	str r3, [r1], #4   		;#				-- store Letter
	str r2, [r1], #4   		;#				-- store Code

	add r2, r2, #1			;# r2++				-- Increase bit code by 1 
	

;# right shift as long as there is a zero at the end of the binary code
del0:	TST r2, #1			;# while(r2%2 == 0)		-- Test if code ends with a zero
	bne ifEnd
	
	sub r0, r0, #1			;# 				-- count code length
	lsr r2,r2, #1			;# r2 /= 2			-- delete zeros
	b del0


	b ifEnd
else:
	add r0, r0, #1			;# 				-- count code length
	cmp r0, #32
	ble no_error

	push {r0-r10,FP,lr}		;#				-- print Error messege
	ldr r0, = errorOut
	bl printf
	pop {r0-r10,FP,lr}
	
	mov r0, #-1	
	b end

	no_error:
	lsl r2, r2, #1			;# r2 *= 2			-- add 0 to binary code

ifEnd:	
;#while
	cmp r2, #1			;# while(r2 != 1 )		-- Loop
	bne dowhile
	
	mov SP, FP			;#				-- Methode body
	pop {r1-r4,FP,lr}
	BX lr

errorOut:
;#	.asciz "\n ERROR: Codes get to long. Codes may not be longer than 32bit. \n\n"
