; Authors: Aäron Munsters, Corneel Soete ~ date: 22/12/2018
CODESEG
;============================ RANDOM BITS GENERATOR ============================
; BORROWED FROM THE ASSISTANTS AT THE VUB
PROC rand_init
	USES    eax, ecx, edx
	mov     ah, 02ch        ; Get system time
	int     21h
	mov     ax, dx          ; Use time to generate seed in EAX
	shl     eax, 16
	mov     ax, cx
	mov     ah, 02ah        ; Get system date
	int     21h
	shl     ecx, 16         ; Mangle date into the seed in EAX
	mov     cx, dx
	xor     eax, ecx
	mov     [rand_seed], eax
	ret
ENDP rand_init


PROC rand
	USES    ebx, ecx, edx
	mov     eax, [rand_seed]
	mov     ecx, RAND_A
	mul     ecx
	add     eax, RAND_C
	mov	  	ebx, eax
	shr	  	ebx, 16
	mul	  	ecx
	add     eax, RAND_C
	mov     [rand_seed], eax
	mov		ax, bx
	ret
ENDP rand

; Written ourself, to generate random bits (arg: amount of random bits)
PROC randOfSize; stores result in eax
	USES ebx, ecx
	ARG @@size:dword; should be amount of bits to keep
	;eg.: size = 4
	xor ebx, ebx ; ebx = 0000 0000 0000 0000
	not ebx;       ebx = 1111 1111 1111 1111
	mov ecx, [@@size]
	@@loop1:
	shl ebx, 1; ebx = 1111 1111 1111 0000
	loop @@loop1
	not ebx; ebx = 0000 0000 0000 1111
	call rand; eax = 0100 0101 0101 0110 1001 (random)
	and eax, ebx
	ret
ENDP randOfSize
;===============================================================================


;========================== DATA GETTERS AND SETTERS ===========================
; This code is used A LOT, any improvement would be very beneficial!
PROC getDataVal; returns requested info from data into EAX, nothing else!
	USES ecx
	ARG @@data:dword, @@shiftAmount:dword, @@valBitSize:dword
	xor eax, eax
	not eax
	xor ecx, ecx
	mov ecx, [@@valBitSize]
	@@shiftloop1:
	shl eax, 1
	loop @@shiftloop1
	not eax
	mov [@@valBitSize], eax;; 'smart hack'
	mov eax, [@@data]
	mov ecx, [@@shiftAmount]
	cmp ecx, 0; for this case it should not loop
	je @@skipLoop2
	@@shiftLoop2:
	shr eax, 1
	loop @@shiftLoop2
	@@skipLoop2:
	and eax, [@@valBitSize]
	ret
ENDP getDataVal


PROC giveDataNewVal; returns updated data (with newVal) in EAX
	;; the example in comments shows how it would run with a new x-coordinates
	USES ecx
	ARG @@data:dword, @@newVal:dword, @@shiftAmount:dword, @@valBitSize:dword
	; 1) we want to reset @@data's value which will be updated
	xor eax, eax              ; eax = 0000 0000 0000 0000 0000
	not eax                   ; eax = 1111 1111 1111 1111 1111
	xor ecx, ecx
	mov ecx, [@@valBitSize]
	@@shiftLoop1:
	shl eax, 1
	loop @@shiftLoop1         ; eax = 1111 1111 1111 1111 0000
	not eax                   ; eax = 0000 0000 0000 0000 1111
	xor ecx, ecx
	mov ecx, [@@shiftAmount]
	cmp ecx, 0; if shift-amount is 0 this means the desired value is cmpltly right
	je @@skipLoop1
	@@shiftLoop2:
	shl eax, 1
	loop @@shiftLoop2         ; eax = 0000 0000 0000 1111 0000
	@@skipLoop1:
	not eax                   ; eax = 1111 1111 1111 0000 1111
	and [@@data], eax        ; data = ???? ???? ???? 0000 ???? -> has bees reset!
	; 2) we want to insert new value
	mov eax, [@@newVal]       ; eax = 0000 0000 0000 0000 XXXX
	xor ecx, ecx
	mov ecx, [@@shiftAmount]
	cmp ecx, 0; for this case it shouldn't loop either
	je skipLoop3
	@@shiftLoop3:
	shl eax, 1
	loop @@shiftLoop3         ; eax = 0000 0000 0000 XXXX 0000
	skipLoop3:
	or [@@data], eax       ; data = ???? ???? ???? XXXX ????
	mov eax, [@@data]       ; eax = ???? ???? ???? XXXX ????
	ret
ENDP giveDataNewVal
;===============================================================================


;=========================== HIGHER ORDER PROCEDURES ===========================
; these procedures take a memory-adress, length of array and procedure
; map changes memory, forEach not (used for side-effects)
; the procedure can only take one argument and return a value in eax
; the procedure will be applied to dword-size of memory
; inspiration source: The Art Of Assembly Language 2nd Ed. (section 5.18)
; map and forEach have no return-value
PROC mapMem
	USES eax, ebx, ecx, edx
	ARG @@memOffset:dword,  @@arraySize:dword, @@procOffset:dword
	cmp [@@arraySize], 0
	je @@done; if not: applyLoop would continue forever
	mov ebx, [@@memOffset]
	mov ecx, [@@arraySize]
	@@applyLoop:
	mov eax, [dword ptr ebx + 4*ecx - 4]
	mov edx, [@@procOffset]
	call edx, eax
	mov [dword ptr ebx + 4*ecx - 4], eax
	loop @@applyLoop
	@@done:
	ret
ENDP mapMem


PROC forEachMem
	USES eax, ebx, ecx, edx
	ARG @@memOffset:dword,  @@arraySize:dword, @@procOffset:dword
	cmp [@@arraySize], 0
	je @@done; if not: applyLoop would continue forever
	mov ebx, [@@memOffset]
	mov ecx, [@@arraySize]
	@@applyLoop:
	mov eax, [dword ptr ebx + 4*ecx - 4]
	mov edx, [@@procOffset]
	call edx, eax
	loop @@applyLoop
	@@done:
	ret
ENDP forEachMem
;===============================================================================
