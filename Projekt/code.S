
.globl _asm_huffman_codierung_coder

.code 32
.extern printf

;#------------------------------------------------------------------------------
_asm_huffman_codierung_coder:
	push {r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
	mov r10,#0
	mov FP,SP
		
	mov r5,r4
	mov r4,r3
	mov r3,r2
	mov r2,r1

		
	;#r0 is pointer to text
	;#r2 is the pointer to the target array
	;#r3 is the size of the target array
	;#r4 is the pointer to the dictionary
	;#r5 is the amount of letters in the dictionary

	mov r1,#3		;#save the offset for saving in r1	
	mov r6,#0		;#save the bitcounter in r6, so that we can push it
	push {r6}
	str r5,[r2]		;#store the amount of letters in the dictionary in the result array
	add r2,r2,#8	;#adjust the pointer of the result array. We are going to store 2 integer numbers in this array in the beginning 
	push {r2}		
	push {r3}
	sub r3,r3,#8	;#reduce the size of r3 by the two integers


	mov r6,r0	;#put the pointer to the text in r6

	;#here we are storing the dictionary int he result array
	push {r1-r3,fp,lr}	
	mov r0,r4
	mov r1,r5
	bl _store_dic
	pop {r1-r3,fp,lr}

	
	add r2,r2,r5		;#adjust the result array
	sub r3,r3,r5		;#adjust the size of the result array
	

	cmp r0,#-1			;#if it didnt fit, end the function with an error
	beq endError

	mov r9,#0b10000000	;#save our bitmask for saving
main_loop_start:	
	;#loop start
	ldrb r0,[r6]	;#load current character to r0

	cmp r0,#0	;#check if we are done
	beq end
	push {r1-r4,fp,lr}
	mov r1,r4
	mov r2,r5
	mov r3,r0
	bl _find	;#get the bitcode of that character
	pop {r1-r4,fp,lr}


	;#create bitmask with only one 1, at the first position after the first 1
	mov  r7,#0b10000000000000000000000000000000	;#create bitmask which starts at the 32th position from right

;#--------------------------------------------------------------------------------------------------------------------
bitmask_loop_start:
	and r8,r0,r7			;#check if the current position of the bitmask has a corresponging 1 in the bitcode of the character
	cmp r8,#0			;#if we found the position of the first 1 in the bitcode jump to the end
	bne bitmask_loop_end
				
	lsr r7,#1			;#shift the bitmask to the right one time
	
	b bitmask_loop_start		
	
	;#end of bitmask_loop
bitmask_loop_end:
	lsr r7,#1			;# r7 stores the first position AFTER the 1, so we have to shift it to the right one time
;#--------------------------------------------------------------------------------------------------------------------------------------------

;#gotta save dem bits
save_loop_start:
	and r8,r0,r7			;#check if the current position of the bitcode has a 1 or a 0
	cmp r8,#0		
	beq save_loop_bit_is_zero	
	add r10,r10,r9			;# if there is a 1 store it in the result
							;# if there is a 0 we dont need to store anything, we can just shift

save_loop_bit_is_zero:
	lsr r9,#1			;#shift the result bitmask aswell as the check bitmask to the right by one
	lsr r7,#1

	push {r1}
	ldr r1,[sp,#12]		;#every time we shift the result array, we store a bit. Here we count how many bits we stored.
	add r1,r1,#1
	str r1,[sp,#12]	
	pop {r1}

	cmp r9,#0			;#check if we reached the end of result bitmask
	beq save_loop_end_of_result_space	;#if yes, then we need to jump to the end
save_loop_bit_is_zero_continued:
	cmp r7,#0	
	beq save_loop_end_of_current_letter
	b save_loop_start 		;#else we start again
	
save_loop_end_of_result_space:
	

	strb r10,[r2,r1]			;# we need to store the result in the result array
	sub r1,r1,#1				;#adjust the offset
	cmp r1,#-1					;#if the offset is -1, replace it with 3 and add 4 to the result array pointer
	bne save_loop_offset_is_not_zero
	mov r1,#3
	add r2,r2,#4
save_loop_offset_is_not_zero:	
	
	mov r10,#0			;# reset the result register
	sub r3,r3,#1			;#the result array now has one less byte left
	cmp r3,#0			;#check if the array is full
	beq endError			;#if yes end with error
	mov r9,#0b10000000		;#reset the result bitmask
	b save_loop_bit_is_zero_continued
	
save_loop_end_of_current_letter:

	add r6,r6,#1			;#we need the next character
	b main_loop_start

;#if the result array had enough space
end:	pop {r5}	;# pop the original amount of space int he result array
	sub r0,r5,r3	;# store how many bytes we used in r0
	pop {r3}
	pop {r4}

	str r4,[r3,#-4]	;#store the amount of bits we stored in the result array in the beginning of the result array

	strb r10,[r2,r1];#store the last few bits left in the array
	
	mov SP,FP
	pop {r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
  	BX lr
;# if the result array did not have enough space
endError:
	pop {r1}		;# we need to pop this value so we can get to the other values
	pop {r3}
	pop {r4}
	str r4,[r3,#-4] ;# store the amount of bits we used 
	mov r0,#-1		;# return -1
	mov SP,FP
	pop {r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
  	BX lr

;#---------------------------------------------------------------------------
;#========================================================================================================
;# Input: r1: Dictionary, r2: Dictionary length, r3: The code we need to search
;# Output: r0: Corresponding Letter, =0 if not found

_find:
    ;# r0 = output
    ;# r1 = input: pointer dictionary
    ;# r2 = input: dictionary length -> later: pointer to end of dictionary
    ;# r3 = input: code
    ;# r4 = tmp
        
    push {r4-r10,FP,lr}            ;# Methode body    
    mov FP, SP        
    
    mov r0, #0                ;# Set output to 0 = Error State
    
    ;#add r1, r1, #4            ;# Move Dictionary pointer to the first Binarycode in table
    add r2, r2, r1                ;# Store Pointer to end in r2
        
find_loop:
    cmp r1,r2                ;# while(r1!=r2)
    bge find_end                ;# Loop throught whole dictionary
    
    ldr r4, [r1], #8             ;# load code into r4

    cmp r4, r3                ;# if code is the one we are looking for
    bne find_loop                
    ldr r0, [r1, #-4]            ;# return Letter corresponding to code
    b find_end
    
    ;#loop end

find_end:
    mov SP,FP                ;# Methode body
    pop {r4,r5,r6,r7,r8,r9,r10,FP,lr}
    BX lr	




;#-------------------------------------------------------------------------
_store_dic:

	push {r1-r10,fp,lr}
	mov fp,sp
	;#r0 has the dictionary
	;#r1 has the dictionary size
	;#r2 has the result array
	;#r3 has the result array size

store_loop_start:
	ldr r4,[r0]		;#
	str r4,[r2]		;#
					;#this part just moves the content of one array to the other array
	ldr r4,[r0,#2]	;#
	str r4,[r2,#2]	;#
	
	sub r1,r1,#4	;#adjust the pointers and sizes
	sub r3,r3,#1
	add r0,r0,#4
	add r2,r2,#4

	cmp r1,#0		;#check if we are done
	beq store_end
	cmp r3,#0
	beq store_end_error
	b store_loop_start

store_end:
	mov r0,#0		;#return 0 if everything worked fine
	mov sp,fp
	pop {r1-r10,fp,lr}
	bx lr

store_end_error:
	mov r0,#-1		;#return -1 if we ran out of space
	mov sp,fp
	pop {r1-r10,fp,lr}
	bx lr
