.globl _asm_huffman_encode

.code 32

.extern _asm_huffman_codierung_counter	;#this function creates the table "character : how often it appears in the text"
.extern _asm_createTree			;#this function creates the tree
.extern _asm_tree_to_code		;#this function creates the table "character : bitcode"
.extern _asm_huffman_codierung_coder	;#this function creates the encoded text
.extern printTree			;#this function print the tree

;#------------------------------------------------------------------------------
_asm_huffman_encode:
	push {r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
	mov FP,SP
	;#r0 is the pointer to the text
	;#r1 is the pointer to the result array
	;#r2 is the result arrays size
	
	;#because we will need the first few registers as parameters we will move the parameters of this function to different registers
	mov r5,r0		;#saving our first parameter in r4
	mov r6,r1		;#saving our seconds parameter in 
	mov r7,r2		;#saving our third parameter in r6


	;#first we call the function "_asm_hoffman_codierung_counter"
	;#this function takes the text as r0, so we don't have to change anything yet
	bl _asm_huffman_codierung_counter
	add r0,r0,#4	;#adjust the pointer, because it is off by 4bytes
	;#now r0 has the pointer to the table
	;#now r1 has the size of the table
	;#because the table is stored on the stack we have to adjust our stack pointer so that we do not override our table
	;#so we take the pointer to the table and we add the size of the table*8 (because 2 rows and four bytes per row) and adjust the sp accordingly
	sub sp,r0,r1		
	sub sp,sp,#4	
	lsr r1,#3
	mov r10,r1

	add r0,r0,r1,lsl #3	;#adjust the pointer, so that it shows to the other side of the array


;#_______________________________________________________________	
	;#next we call the create tree function "_asm_createTree"
	;#this function takes the previously created table as r0
	;#this function takes the length of the previously created table as r1
	;#this function takes the array for storing the tree in r2, NOTE: this function needs the pointer to the array from the bottom
	;#we need to calculate the size of the array: 2n-1 where n is the amount of rows in our table
	mov r8,r1		;#storing our table size in r8
	lsl r8,#1		;#take it times 2
	sub r8,r8,#1		;#subtract 1
	mov r9,sp		;#store the sp as pointer to the array
	sub sp,sp,r8		;#create array
	
	mov r2,r9

	
	bl _asm_createTree

	
	
	
;#________________________________________________________________________
	;#next we call the create bitcode function "_asm_tree_to_code", but before that we print the tree 
	sub r0,r0,r1,lsl #3		;#adjust the pointer to the table again
	mov r1,r0				;#save it in r1
	mov r0,r2				;#save the tree in r0
	

	push {r0-r10,FP,lr}
	bl printTree
	pop {r0-r10,FP,lr}

	push {r1}				;#tree to code changes the size of r1, so we need to save it
	bl _asm_tree_to_code
	;#the table is stored in r0
	;#the size of the table is stored in r1
	pop {r1}


;#____________________________________________________________________________


	;#next we actualy encode the text with the function "_asm_huffman_codierung_coder"
	;#this function takes the text as r0
	;#this function takes the pointer to the target as r1
	;#this function takes the size of the target as r2
	;#this function takes the pointer to the dictionary as r3
	;#this function takes the size of the dictionary as r4
	lsl r10,#3			;#adjust the size, so that it gives us the size in bytes
	mov r4,r10			;#move all the parameters to the right registry
	mov r3,r1
	mov r2,r7
	mov r1,r6
	mov r0,r5	

	bl _asm_huffman_codierung_coder
	


	mov SP,FP
	pop {r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
  	BX lr

;#---------------------------------------------------------------------------


