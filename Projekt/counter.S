
.globl _asm_huffman_codierung_counter

.code 32
;#------------------------------------------------------------------------------
_asm_huffman_codierung_counter:
	push {r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,lr}
	mov FP,SP
	;#Param: r0 is the adress to the array with the characters
	;#Param: r1 is the pointer to the amount of rows our table has
	
	push {r0,r1,r2,r3,r4,r5,r6,r7,r8,fp,lr}
	mov r9,sp			;#in the function "save" we use r7 as the starting point of our table. But the function itself creates a stackframe which alters the stackpointer
	sub r9,r9,#4			;#so we have to adjust the sp so it fits.
	mov r10,r9			;#r1 stores the last row of our table
	pop {r0,r1,r2,r3,r4,r5,r6,r7,r8,fp,lr}

	mov r2,r9
	mov r3,r10
	
	mov r4,r0			;#store the pointer in r6, so that r0 can be used 
					;#as a parameter for a different function

	

	;#loop starting point. It loops until it reads NULL (ascii code 00000000)
start:	

	mov r5,#0b0000000011111111
	mov r6,#0b1111111100000000

	ldr r7,[r4]	

	and r8,r7,r5			;#use the bitmask

	and r9,r7,r6			;#use the second bitmask
	lsr r9,#8			;#shift right by a byte

	add r4,r4,#2			;#go to the next adress in the array
	

	cmp r8,#0			;#check if first char is nonexistent
	beq end				;#if it is=>end
	
	push {r0,r1,r2}
	mov r0,r8
	mov r1,r2
	mov r2,r10
	bl save				;#save the character
	mov r10,r0
	pop {r0,r1,r2}
	

	cmp r9,#0			;#check if second char is nonexistent
	beq end	
	
	push {r0,r1,r2}				;#if yes, end
	mov r0,r9
	mov r1,r2				;#move the second character to r0 as parameter
	mov r2,r10
	bl save				;#save the character

	mov r10,r0
	pop {r0,r1,r2}

	b start				;#if none of the chars is nonexistent jump start

	;#end of loop

end:
	mov r0,r10
	sub r10,r2,r10			
	mov r1,r10
					;#we divide last row by the firstrow and we get 
					;#the amount of rows
  	;# Stack wiederherstellen
	
	mov SP,FP
	pop {r2,r3,r4,r5,r6,r7,r8,r9,r10,FP,pc}
  	BX lr


;#---------------------------------------------------------------------------
save:
	;#create stackframe
	push {r3,r4,r5,r6,r7,r8,fp,lr}
	mov fp,sp
	;#r0 alrady contains the code which needs to get saved
	;#r1 already contains the starting adress
	;#r2 contains the adress of the last row in the table 
	mov r3,r1			;#set the current adress to the start adress
	mov r4,r2			;#set r4 to the adress of the last row
;#if there are no elements in the table
	cmp r1,r2			;#compare start and end
	beq save_add_new_element	;#if the table is empty we have to add a new 
					;#element


	;#if there are elements in the table
save_loop_start:
	ldr r5,[r3]			;#load the char of the current row
	cmp r0,r5			;#compare the char with the char which needs to be saved
	beq save_add_to_existing_element	;#jump to save_add_to_existing element if they are equal
	;#if those two characters are not the same,check if we reached the end
	cmp r3,r2			;#compare both adresses
	beq save_add_new_element	;#if they are equal, the element to be saved does 
					;#not exist yet
	sub r3,r3,#8
	b save_loop_start		;#if they are not equal jump back to loop start
	

save_add_to_existing_element:
	ldr r6,[r3,#-4]			;#get the amount of the current char
	add r6,r6,#1			;#raise the amount by 1
	str r6,[r3,#-4]			;#store the new amount
	b save_end			

save_add_new_element:

	str r0,[r2]			;#save the new character at the last row
	mov r7,#1
	sub r2,r2,#4			
	str r7,[r2]			;#save the amount for the new character
	sub r2,r2,#4			;#add one row to the last row
	b save_end			


save_end:
	mov r0,r2			;#save the adress of the last point in r1

	mov sp,fp
	pop {r3,r4,r5,r6,r7,r8,fp,pc}
	
;#---------------------------------------------------------------------------------
