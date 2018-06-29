
.globl _asm_huffman_decode

.code 32
.extern printf

;# int _asm_huffman_decode(unsigned long *input, char *output, int estimatedLength)
_asm_huffman_decode:
	;# r0 = output (= result length; =-1 if error) 
	;# r1 = estimated result length
	;# r2 = pointer output
	;# r3 = Pointer Dictionary end
	;# r4 = Pointer Dictionary
	;# r5 = coded text length in bit	
	;# r6 = pointer coded text
	;# r7 = current read code
	;# r8 = bitmask for reading code
	;# r9 = tmp

	push {r1-r10,FP,lr}		;# Methode body
	mov FP, SP

	mov r9, r1			;#I have to switch r1 and r2 because I messed up the order of the parameters
	mov r1, r2
	mov r2, r9
	mov r9, #0

	ldr r3, [r0], #4			;# load Dictionary length into r3
	;#lsl r3, r3, #3

	ldr r5, [r0], #4			;# load coded text length in bit into r5
	mov r4, r0				;# store pointer to Dictionary in r4	
						
	add r0, r0, r3				;# skip Dictionary
	mov r6, r0				;# Store pointer to coded text intp r6	
	
	mov r8, #0b10000000000000000000000000000000	;# Setup bitmask

	mov r0, #0
	
	mov r7, #1				;# load leading 1 into r7
		
loop:	
	;# read
	cmp r5, #0				;# loop throught all bits
	ble end				;# for(int i=numberOfBits; i>0; i--)
	sub r5, r5, #1
	
	lsl r7, r7, #1				;# shift code by #1 = add zero to code

	ldr r9, [r6]				;# load current bit package
	and r9, r9, r8				;# pick current bit
	cmp r9, r8				;# if current bit=1
	bne if_end				
	add r7, r7, #1				;# increase code by 1
	 
if_end:

	;# find					;# find code in Dictionary
	push {r0-r3,FP,lr}			
	mov r1,	r4				;# load parameter
	mov r2, r3
	mov r3, r7
	bl _find				;# call methode find
	mov r9, r0				;# store result
	pop {r0-r3,FP,lr}

	cmp r9, #0				;# test if code was found
	beq not_found
	
	add r0, r0, #1				;# catch error if more space than estimated is needed
	cmp r0, r1		
	ble no_error	
	push {r0-r10,FP,lr}
	ldr r0, =errorNotEnoughSpace		;# print error messege
	bl printf
	pop {r0-r10,FP,lr}

	mov r0, #-1				;# error state
	b end

	no_error:
	str r9, [r2],#1				;# Store letter in output array	

	mov r7, #1				;# reset code
	
not_found:
	cmp r8, #1				;# if(bitmask=1) -> move to next bit package (=register) of coded text
	bne dont_inrcrease_r6

	add r6, r6, #4				;# go to next register

	dont_inrcrease_r6:			
	ror r8, r8, #1				;# shift bitmask by 1
	b loop

end:	
	push {r0-r10,FP,lr}
	mov r1,r0
	ldr r0, =output	
	bl printf
	pop {r0-r10,FP,lr}

	mov SP,FP				;# Methode body
	pop {r1-r10,FP,lr}
	BX lr


;#== Find Letter corresponding to Binary Code in Dictionary =========================================================================
;# Input: r1: Dictionary, r2: Dictionary length, r3: The code we need to search
;# Output: r0: Corresponding Letter, =0 if not found

_find:
	;# r0 = output
	;# r1 = input: pointer dictionary
	;# r2 = input: dictionary length -> later: pointer to end of dictionary
	;# r3 = input: code
	;# r4 = tmp
		
	push {r4-r10,FP,lr}			;# Methode body	
	mov FP, SP		
	
	mov r0, #0				;# Set output to 0 = Error State
	
	add r1, r1, #4				;# Move Dictionary pointer to the first Binarycode in table
	add r2, r2, r1				;# Store Pointer to end in r2
		
find_loop:
	cmp r1,r2				;# while(r1!=r2)
	bge find_end				;# Loop throught whole dictionary
	
	ldr r4, [r1], #8 			;# load code into r4

	cmp r4, r3				;# if code is the one we are looking for
	bne find_loop				
	ldr r0, [r1, #-12]			;# return Letter corresponding to code
	b find_end
	
	;#loop end

find_end:
	mov SP,FP				;# Methode body
	pop {r4,r5,r6,r7,r8,r9,r10,FP,lr}
	BX lr

output:
	.asciz "%lu \n"
compOut:
	.asciz "%lu %lu \n"
charOut:
	.asciz "%c"
errorNotEnoughSpace:
	.asciz "\n ERROR: Decoded Text is longer than available space.\n\n"




