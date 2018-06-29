.globl _asm_createTree

.code 32
;# int _asm_createTree(int *probTable, 
;# int tableLength, char *memoryForTree);
;#	
;#	requires probTable with at least 2 entries
;#	memoryForTree: requires (2 * tableLength) - 1 bytes
;#  tableLength: number of entries (2 integers per entry)
;#

;# Registers:
;#	r0: probTable (sorted low to high)
;#	r1: tableLength - cnt of integers (2 integers per entry)
;#	r2: pointer to memory for final tree
_asm_createTree:
		push {r0,r1,r3,r4-r7,r8,r9,r10, fp, lr}
		mov fp, sp
		
		mov r4, #2
		cmp r1, r4
		bpl _start
		mov r0, #-1
		b _end
		
	_start:
		mov r4, #2
		mul r1, r1, r4								;# tableLength <- tableLength *2 to fit algorithm
		
		bl _sortProbTable							;# sort probTable
		
		mov r4, r1									;# #-4 left, #-8 right, #-12 value, #-16 leftIsLeaf, #-20 rightIsLeaf
		mov	r5, #10									;# allocate memory for subtrees - 20 byte per nodes
		sub r4, r4, #2								;# 20 * ((tableLength / 2) - 1) = 10 * (tableLength - 2)
		mul r4, r4, r5
		sub sp, sp, r4
		
		bl _createTmpTree							;#	r4 <- tmpTreeWritePointer used by _createFinalTree
		
		bl _createFinalTree
	
	_end:
		mov sp, fp
		pop {r0,r1,r3,r4-r7,r9,r10, fp, pc}
		bx lr
		
		
;# Registers:
;#  r0: probTable (sorted low to high)
;#  r1: tableLength - cnt of integers (2 integers per entry)
;#  r2: pointer to memory for final tree
;#	r3: tmpTreeWritePointer
;#	r4: tmp
;#	r5: tmp
;#	r6: propTablePointer
;#	r7: isLeftNodeFilled
;#	r8: tmpTreePointer
;#	r9: tmpTreeNodeCount
;#	r10: tmpTreeMergedLeafs
_createTmpTree:
		mov r6, r0									;# r6: propTablePointer <- probTable
		mov r3, fp									;# r3: tmpTreeWritePointer <- fp
		mov r8, fp									;# r8: tmpTreePointer <- fp
		mov r7, #0									;# r7: isLeftNodeFilled
		mov r9, #0									;# r9: tmpTreeNodeCount
		mov r10, #0									;# r10: tmpTreeMergedLeafs
		
	_loopMerge:
		mov r4, #0									;# newNodeValue <- 0
		str r4, [r3, #-12]
		
	_mergeElement:
		mov r4, #2									;# if (tmpTreeMergedLeafs * 2) = tableLength(r1) goto mergeNode
		mul r4, r10, r4
		cmp r4, r1
		beq _cmpNodeMergeNode
		
		ldr r4, [r6, #-8]							;# r4 <- lowestLeafValue
		
		cmp r3, r8									;# if r8: tmpTreePointer = r3: tmpTreeWritePointer goto mergeLeaf
		beq _cmpNodeMergeLeaf
		
		ldr r5, [r8, #-12]							;# r5 <- lowestNodeValue
		
		cmp r5, r4  								;# if lowestLeafValue > lowestNodeValue goto mergeNode
		bmi _cmpNodeMergeNode
		
	_cmpNodeMergeLeaf:
		ldr r5, [r3, #-12]						;# newNodeValue = newNodeValue + lowestLeafValue(r4)
		add r4, r4, r5
		str r4, [r3, #-12]
		add r10, r10, #1						;# r10: tmpTreeMergedLeafs++
		
		cmp r7, #1								;# if r3: isLeftNodeFilled = 1 goto mergeRight
		beq _cmpNodeMergeLeafRight
		
		ldr r4, [r6, #-4]						;# newNodeLeft <- Char of lowest leaf
		str r4, [r3, #-4]
		mov r4, #1								;# set newNodeLeftIsLeaf = 1
		str r4, [r3, #-16]
		mov r7, #1								;# r7: isLeftNodeFilled <- 1
		sub r6, r6, #8 							;# r6: propTablePointer <- r6: propTablePointer - 8
		b _mergeElement
		
		_cmpNodeMergeLeafRight:
		ldr r4, [r6, #-4]						;# newNodeRight <- Char of lowest leaf
		str r4, [r3, #-8]
		mov r4, #1								;# set newNodeRightIsLeaf = 1
		str r4, [r3, #-20]
		mov r7, #0								;# r7: isLeftNodeFilled <- 0
		sub r6, r6, #8 							;# r6: propTablePointer <- r6: propTablePointer - 8
		b _cmpNodeEnd
		
	_cmpNodeMergeNode:
		ldr r5, [r8, #-12]						;# r5 <- lowestNodeValue
		ldr r4, [r3, #-12]						;# newNodeValue = newNodeValue + lowestNodeValue(r5)
		add r4, r4, r5
		str r4, [r3, #-12]
		
		
		cmp r7, #1								;# if r3: isLeftNodeFilled = 1 goto mergeRight
		beq _cmpNodeMergeNodeRight
		
		str r8, [r3, #-4]						;# newNodeLeft <- pointer to merged node
		sub r8, r8, #20							;# r8: tmpTreePointer <- r8: tmpTreePointer - 20
		mov r4, #0								;# set leftIsLeaf = 0
		str r4, [r3, #-16]		
		mov r7, #1								;# r7: isLeftNodeFilled <- 1
		b _mergeElement
		
		_cmpNodeMergeNodeRight:
		str r8, [r3, #-8]						;# newNodeRight <- pointer to merged node
		sub r8, r8, #20							;# r8: tmpTreePointer <- r8: tmpTreePointer - 20
		mov r4, #0								;# set rightIsLeaf = 0
		str r4, [r3, #-20]
		mov r7, #0								;# r7: isLeftNodeFilled <- 0
		b _cmpNodeEnd
		
	_cmpNodeEnd:
		add r9, r9, #1							;# r9: tmpTreeNodeCount++
		
		mov r4, #2								;# if (r9: tmpTreeNodeCount * 2) >= (r1: tableLength - 2) exit loop
		mul r4, r9, r4
		sub r5, r1, #2
		cmp r4, r5
		
		bpl _loopMergeEnd
		
		sub r3, r3, #20							;# tmpTreeWritePointer <- tmpTreeWritePointer - 20
		b _loopMerge
		
	_loopMergeEnd:
		ldr r0, [r3, #-12]
	
		mov r4, r3
		bx lr
		
		
;# Registers:
;#  r0: probTable (sorted low to high)
;#  r1: tableLength - cnt of integers (2 integers per entry)
;#  r2: pointer to memory for final tree
;#	r3: finalTreeWritePointer
;#	r4: currentNode
;#	r5: treeElementCount - elements left to merge
;#	r6: tmp

_createFinalTree:
		;#mov r4, r4								;# r4: currentNode <- tmpTreeWritePointer (root)
		mov r3, r2								;# r3 <- finalTreePointer
		sub r5, r1, #1							;# r5: treeElementCount <- (tableLength - 1)
		
		;#sub r0, r4, sp
		;#b _createTreeEnd
		
	_createTreeNextNode:
		mov r6, #0								;# save 0 in finalTree to represent node
		strb r6, [r3, #-1]
		sub r3, r3, #1							;# finalTreeWritePointer <- (finalTreeWritePointer - 1)
		
		ldrb r6, [r4, #-16]						;# if leftIsLeaf = 1
		cmp r6, #1
		beq _createTreeLeftIsLeaf
		
		push {r4}									;# push current node
		ldr r4, [r4, #-4]						;# currentNode <- currentNodeLeft
		b _createTreeNextNode
		
	_createTreeLeftIsLeaf:
		sub r5, r5, #1							;# treeElementCount--
		ldrb r6, [r4, #-4]						;# r6 <- char of leaf
		strb r6, [r3, #-1]						;# save char in finalTree
		sub r3, r3, #1							;# finalTreeWritePointer <- (finalTreeWritePointer - 1)
		
	_createTreeRightSubtree:	
		sub r5, r5, #1							;# treeElementCount--
		ldr r6, [r4, #-20]						;# if rightIsLeaf = 1
		cmp r6, #1
		beq _createTreeRightIsLeaf
		
		ldr r4, [r4, #-8]						;# currentNode <- currentNodeRight
		b _createTreeNextNode
	
	_createTreeRightIsLeaf:
		sub r5, r5, #1							;# treeElementCount--
		ldr r6, [r4, #-8]						;# r6 <- char of leaf
		strb r6, [r3, #-1]						;# save char in finalTree
		sub r3, r3, #1							;# finalTreeWritePointer <- (finalTreeWritePointer - 1)
		
		cmp r5, #0								;# if treeElementCount = 0
		beq _createTreeEnd
		
		pop {r4}								;# backtrack to last right subtree
		b _createTreeRightSubtree
		
	_createTreeEnd:
		bx lr


;# Registers:
;#   r0: probTable - to be sorted now (low to high)
;#   r1: tableLength - cnt of integers (2 integers per entry)
;#   r2: pointer to memory for final tree (unused here)
;#   r3: sortedInts
;#   r4: tmp
;#   r5: loopMinValue
;#   r6: loopMinPointer
;#   r7: tableLoopPointerNext
;#   r8: tableLoopPos
;#   r9: tablePointerFirstUnsorted

_sortProbTable:
		mov r3, #0								;# sortedInts <- 0
		mov r7, r0								;# tableLoopPointerNext <- probTable
		
	_sortLoopStartIt:								
	;# reset loop variables and load first entry as new min						
		mov r4, #4								;# tablePointerFirstUnsorted <- probTable - (sortedInts * 4)
		mul r4, r3, r4
		sub r9, r0, r4
		mov r7, r9								;# tableLoopPointerNext <- tablePointerFirstUnsorted
		mov r8, r3								;# tableLoopPos <- sortedInts
		ldr r5, [r7, #-8]						;# loopMinValue <- value of first unsorted entry
		mov r6, r9								;# loopMinPointer <- tableLoopPointerNext
	
	_sortLoopDoLoop:
	;# if all entries are done goto swap
		sub r7, r7, #8							;# tableLoopPointerNext <- tableLoopPointerNext - 8
		add r8, r8, #2							;# tableLoopPos <- tableLoopPos + 2
		cmp r8, r1								;# if tableLoopPos = tableLength goto swap
		beq _sortLoopSwap
		
		
		ldr r4, [r7, #-8]						;# compare loopMinValue, currentEntryValue
		cmp r4, r5
		bpl _sortLoopDoLoop
		
		mov r5, r4								;# loopMinValue <- currentEntryValue
		mov r6, r7								;# loopMinPointer <- tmpTablePointerNext
		b _sortLoopDoLoop
		
	_sortLoopSwap:
		cmp r6, r9								;# if tablePointerFirstUnsorted is not loopMinPointer swap
		beq _sortLoopPrepNextIt
		
		ldr r4, [r9, #-8]						;# swap entires of loopMinPointer and tablePointerFirstUnsorted
		str r4, [r6, #-8]
		str r5, [r9, #-8]
		ldr r4, [r6, #-4]
		ldr r5, [r9, #-4]
		str r4, [r9, #-4]
		str r5, [r6, #-4]
		
	_sortLoopPrepNextIt:
		add r3, r3, #2							;# sortedInts <- sortedInts + 2
	
		sub r4, r1, #1
		cmp r3, r4								;# if sortedEntries < (tableLength - 1) continue loop
		bmi _sortLoopStartIt
		
	_sortLoopEnd:
		bx lr