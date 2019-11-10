IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "sprites.inc"
INCLUDE "graphics.inc"
INCLUDE "grapmcr.asm"


UDATASEG
	screenBuffer DB  SCRWIDTH*SCRHEIGHT DUP(?)
CODESEG

PROC real_coord ;procedure puts the real x-value in eax
	ARG @@abs_x: dword
	uses edx
	mov edx, CELLSIZE ;width/height of a Cell
	mov eax, [@@abs_x]
	mul edx

	ret
ENDP real_coord

PROC real_inventory_x
	ARG @@abs_x: dword
	uses edx
	mov edx, ITEMSIZE+1 ;width/height of a Cell
	mov eax, [@@abs_x]
	mul edx
	add eax, INVENTORY_X

	ret
ENDP real_inventory_x

PROC real_inventory_y
	ARG @@abs_y: dword
	uses edx
	mov edx, ITEMSIZE+1 ;width/height of a Cell
	mov eax, [@@abs_y]
	mul edx
	add eax, INVENTORY_Y

	ret
ENDP real_inventory_y

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                               BACKGROUND                                 ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC fillBackground
	USES eax, ecx, edi

	; Initialize video memory address.
	mov	edi, offset screenBuffer

	; copy color value across all bytes of eax
	mov al, 12H
	mov ah, al				; ??BB
	mov cx, ax
	shl eax, 16				; BB00
	mov ax, cx				; BBBB

	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCRWIDTH*SCRHEIGHT/4
	rep	stosd

	ret
ENDP fillBackground

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                 TERRAIN                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;a procedure wich takes the cell and coordinates and will draw the right texture
PROC display_terrain
	ARG @@terrain: dword, @@X: dword, @@Y: dword
 	USES eax, edx
 	call real_coord, [@@Y]
 	mov edx, eax
 	call real_coord, [@@X]
	call draw, eax, edx, [@@terrain], offset TERRAINS, 1
 	ret
ENDP display_terrain


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                  ITEMS                                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC display_item
	ARG @@item: dword, @@X: dword, @@Y: dword
	USES eax, edx
	call real_coord, [@@Y]
	mov edx, eax
	call real_coord, [@@X]

	cmp [@@item], 0
	je @@noItem
	dec [@@item]
	call draw, eax, edx, [@@item], offset ITEMS, 1
	@@noItem:
   ret
ENDP display_item

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                 PROPS                                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC display_dovah
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, DOVAH, [@@X], [@@Y], [@@direction]

	ret
ENDP display_dovah

PROC display_skeleton
	ARG @@X:dword, @@Y:dword, @@direction:dword, @@lives:dword
	call display_prop, SKELETON, [@@X], [@@Y], [@@direction]
	call draw_health, [@@X], [@@Y], [@@lives]

	ret
ENDP display_skeleton

PROC display_draughr
	ARG @@X:dword, @@Y:dword, @@direction:dword, @@lives:dword
	call display_prop, DRAUGR, [@@X], [@@Y], [@@direction]
	call draw_health, [@@X], [@@Y], [@@lives]

	ret
ENDP display_draughr

PROC draw_health
	ARG @@X:dword, @@Y:dword, @@lives:dword
	LOCAL @@width:dword
	USES eax, edx
	mov eax, CELLSIZE/MAXHEALTH
	mul [@@lives]
	mov [@@width], eax

	call real_coord, [@@Y]
	mov edx, eax
	call real_coord, [@@X]

	call drawRectangle, eax, edx, [@@width], 1, 28H

	ret
ENDP draw_health

PROC display_helmet
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, HELMET, [@@X], [@@Y], [@@direction]

	ret
ENDP display_helmet

PROC display_armor
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, ARMOR, [@@X], [@@Y], [@@direction]

	ret
ENDP display_armor

PROC display_shield
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, SHIELD, [@@X], [@@Y], [@@direction]

	ret
ENDP display_shield

PROC display_sword
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, DAGGER, [@@X], [@@Y], [@@direction]

	ret
ENDP display_sword

PROC display_staff
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, STAFF, [@@X], [@@Y], [@@direction]

	ret
ENDP display_staff

PROC display_bow
	ARG @@X:dword, @@Y:dword, @@direction:dword
	call display_prop, BOW, [@@X], [@@Y], [@@direction]

	ret
ENDP display_bow

PROC display_prop
	ARG @@prop: dword, @@X: dword, @@Y: dword, @@direction:dword
	LOCAL @@dovahIDX
	USES eax, edx

	mov eax, [@@prop]
	mov [@@dovahIDX], eax
	mov edx, [@@direction]
	mov eax, AMOUNTOFPROPS
	mul edx
	add [@@dovahIDX], eax

	call real_coord, [@@Y]
	mov edx, eax
	call real_coord, [@@X]
   call draw, eax, edx, [@@dovahIDX], offset PROPS, 1

   ret
ENDP display_prop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                DRAW                                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC draw
	ARG 	@@x0:word, @@y0:word, @@idx: dword, @@list:dword, @@infield?:dword
	USES edx, eax, ecx, edi, ebx, esi

	;----- set ebx to the starting point of the sprite in the sprites array -----
	mov ebx, [@@idx]
	mov esi, [@@list]
	mov al, [esi]
	mov dl, [esi + 1]
	mul dl
	mul ebx
	mov ebx, eax
	add ebx, 2

	; ----- Compute the index of the sprite's top left corner -----
	cmp [@@infield?], 1
	je @@infield
	mov cl, 0
	jmp @@endofoffset
	; for us to do this we first take half of the complete cellsize and subtract half of the item/prop size
	; this makes the item/prop be displayed in the middle of a cell instead of in the leftmost corners
	@@infield:
	mov al, [esi]
	mov cl, CELLSIZE
	sub cl, al
	sar cl, 1
	@@endofoffset:

	;now that we have found the offset all we do is find the the real starting point
	;by adding the offset and multiplying it with the screenwidth for the y-value and than addng the x-value with its offset
	movzx eax, [@@y0]
	add eax, ecx
	mov edx, SCRWIDTH
	mul edx
	add ax, [@@x0]
	add eax, ecx

	;----- Compute top left corner video address -----
	mov edi, offset screenBuffer
	add edi, eax

	;empty the registers edx and ecx so we can use them as counters
	xor edx, edx
	xor ecx, ecx
	xor eax, eax

	;----- loop through the sprite to draw it ------
	@@outerloop:
		@@innerloop:
			mov al, [esi + ebx]
			cmp al, 0FFH
			je @@nodraw
			mov [edi + ecx], al
			@@nodraw:
			inc cl
			inc ebx
			cmp cl, [esi]
			jne @@innerloop

		add edi, SCRWIDTH
		xor ecx, ecx
		inc dl
		cmp dl, [esi + 1]
		jne @@outerloop

	ret
ENDP draw

PROC drawRectangle
	ARG 	@@x0:word, @@y0:word, @@w:word, @@h:word, @@col: byte, @@borders?:byte
	USES 	eax, ecx, edx, edi, ebx

	; Compute the index of the rectangle's top left corner
	movzx eax, [@@y0]
	mov edx, SCRWIDTH
	mul edx
	add	ax, [@@x0]

	; Compute top left corner address
	mov edi, offset screenBuffer
	add edi, eax

	;test if its asked to draw only the borders of the square
	cmp [@@borders?], 1
	je @@borders

  	;draw the square
	movzx edx, [@@w]	; store width in edx for later reuse
	mov	al,[@@col]
	mov bx, [@@h]
	@@drawloop:
		mov	ecx, edx
		rep stosb
		sub edi, edx		; reset edi to left-top corner
		add edi, SCRWIDTH
		dec bx
		cmp bx, 0
		jne @@drawloop
	ret

	;when only the borders have to be drawn
	;borowed from the assistents
	@@borders:
	; Plot the top horizontal edge.
	movzx edx, [@@w]	; store width in edx for later reuse
	mov	ecx, edx
	mov	al,[@@col]
	rep stosb
	sub edi, edx		; reset edi to left-top corner

	; plot both vertical edges
	movzx ecx,[@@h]
	@@vertLoop:
		mov	[edi],al		; left edge
		mov	[edi+edx-1],al	; right edge
		add	edi, SCRWIDTH
		loop @@vertLoop
	; edi should point at the bottom-left corner now
	sub edi, SCRWIDTH

	; Plot the bottom horizontal edge.
	mov	ecx, edx
	rep stosb
	ret
ENDP drawRectangle

PROC display_logo
	call draw, LOGO_X, LOGO_Y, 0, offset LOGO, 0
	ret
ENDP display_logo

PROC display_dragon
	ARG @@X, @@Y
	USES eax, edx
	call real_coord, [@@Y]
	mov edx, eax
	call real_coord, [@@X]

	call draw, eax, edx, 0, offset DRAGON, 0
	ret
ENDP display_dragon
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                               UI BAR                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC display_UI
	call draw, START_X, START_Y, START_BUTTON, offset BUTTONS, 0
	call draw, STOP_X, STOP_Y, STOP_BUTTON, offset BUTTONS, 0
	call display_lives, MAXHEALTH, 1
	call draw_equipables
	call draw_inventory
	ret
ENDP display_UI

PROC draw_equipables
	;equipables background
	call draw, EQUIPABLES_X, EQUIPABLES_Y, 0, offset UEQUIP, 0
	;draw the corners afterwards so they go on top
	call draw, EQUIPABLES_X, EQUIPABLES_Y, 1, offset UEQUIP, 0

	ret
ENDP draw_equipables

PROC draw_inventory
	USES ecx, eax, edx, ebx
	ARG @@xloop, @@yloop
	;display witch starts one pixel up and left,      size: amount of cells + borders inbetween, color black
	call drawRectangle, INVENTORY_X-1, INVENTORY_Y-1, INVENTORY_WIDTH*9+1, INVENTORY_HEIGHT*9+1, 00H
  	xor eax, eax
  	xor ebx, ebx
	mov ecx, INVENTORY_Y
	mov edx, INVENTORY_X
	@@vertloop:
       @@horizloop:
          call drawRectangle, edx, ecx, 8, 8, 17H
			 add edx, 9
			 inc eax
          cmp eax, INVENTORY_WIDTH
          jne @@horizloop

		mov eax, 0
	  	mov edx, INVENTORY_X
	  	add ecx, 9
      inc ebx
      cmp ebx, INVENTORY_HEIGHT
      jne @@vertloop

	ret
ENDP draw_inventory

PROC display_inventory_item
	ARG @@item, @@X, @@Y
	USES eax, edx
 	call real_inventory_y, [@@Y]
 	mov edx, eax
 	call real_inventory_x, [@@X]

	cmp [@@item], 0
	je @@noItem
	dec [@@item]
	call draw, eax, edx, [@@item], offset ITEMS, 0
	@@noItem:

	ret
ENDP display_inventory_item

PROC display_equipable_item
	ARG @@item, @@place
	cmp [@@item], 0
	je @@end
	dec [@@item]


	cmp [@@place], 0
	je @@drawhelmet
	cmp [@@place], 1
	je @@drawA
	cmp [@@place], 2
	je @@drawB
	cmp [@@place], 3
	je @@drawarmor

	@@drawhelmet:
	call draw, HELMET_X, HELMET_Y, [@@item], offset ITEMS, 0
	jmp @@end
	@@drawA:
	call draw, ITEM_A_X, ITEM_A_Y, [@@item], offset ITEMS, 0
	jmp @@end
	@@drawB:
	call draw, ITEM_B_X, ITEM_B_Y, [@@item], offset ITEMS, 0
	jmp @@end
	@@drawarmor:
	call draw, PANTS_x, PANTS_Y, [@@item], offset ITEMS, 0

	@@end:
	;draw the corners of the ui and the letters A and B on top of the item
	call draw, EQUIPABLES_X, EQUIPABLES_Y, 1, offset UEQUIP, 0
	ret
ENDP display_equipable_item

PROC display_map
	USES eax, edx, ecx, esi, ebx
	ARG @@map:dword, @@selectedField:dword
	LOCAL @@worldx, @@worldy, @@vmadres, @@currfield
	mov esi, [@@map]

	call drawRectangle, WORLD_X-1, WORLD_Y-1, WORLDSIZE*FIELDWIDTH+5, WORLDSIZE*FIELDHEIGHT+5, 00H

	; ----- Compute the index of the maps's top left corner -----
	mov eax, WORLD_Y
	mov edx, SCRWIDTH
	mul edx
	add ax, WORLD_X

	;----- Compute top left corner video address -----
	mov [@@vmadres], offset screenBuffer
	add [@@vmadres], eax

	xor edx, edx
	xor ebx, ebx
	xor eax, eax
	mov [@@worldy], 0
	mov [@@currfield], 0

	@@vertWorldLoop:
	mov [@@worldx], 0
	@@horizWorldLoop:
	mov edi, [@@vmadres]
	mov eax, SCRWIDTH
	mul [@@worldy]
	add edi, eax

	;;calculate if the cell hase to be highlighted
	mov eax, [@@currfield]
	cmp eax, [@@selectedField]
	jne @@notselected
	;;if the cell is the selected one it hase to be highlighted
	mov ecx, [@@worldx]
	add ecx, WORLD_X-1
	mov edx, [@@worldy]
	add edx, WORLD_Y-1
	call drawRectangle, ecx, edx, FIELDWIDTH+2, FIELDHEIGHT+2, 0FH
	@@notselected:
	xor edx, edx

	@@vertFieldLoop:
		mov ecx, [@@worldx]
		@@horizFieldLoop:
			xor eax, eax
			mov al, [esi + ebx]
			mov al, [TERRAIN_COLORS + eax]
			mov [edi + ecx], al
			inc ecx
			inc ebx
			mov eax, [@@worldx]
			add eax, FIELDWIDTH
			cmp ecx, eax
			jne @@horizFieldLoop

		add edi, SCRWIDTH
		inc dl
		cmp dl, FIELDHEIGHT
		jne @@vertFieldLoop

	add [@@worldx], FIELDWIDTH+1
	inc [@@currfield]
	mov eax, (FIELDWIDTH+1)*4
	cmp [@@worldx], eax
	jne @@horizWorldLoop

	add [@@worldy], (FIELDHEIGHT+1)
	mov eax, (FIELDHEIGHT+1)*4
	cmp [@@worldy], eax
	jne @@vertWorldLoop

	ret
ENDP display_map

PROC display_lives
	ARG @@amountoflives, @@dead?
	LOCAL @@X
	USES ecx ,edx, ebx

	xor edx, edx

	cmp [@@dead?], 1
	je @@notalive
	mov ebx, LIVES_ALIVE
	jmp @@start
	@@notalive:
	mov ebx, LIVES_DEAD

	@@start:
	cmp [@@amountoflives], 0
	je @@donothing
	mov ecx, [@@amountoflives]
	mov edx, LIVES_X
	@@myloop:
		call draw, edx, LIVES_Y, ebx, offset UITEMS, 0
		add edx, ITEMSIZE+1
	loop @@myloop

	@@donothing:
	ret
ENDP display_lives

PROC display_item_selected
	ARG @@X, @@Y
	USES eax, edx

	call real_inventory_y, [@@Y]
	mov ecx, eax
	dec ecx
	call real_inventory_x, [@@X]
	dec eax

	call drawRectangle, eax, ecx, ITEMSIZE+2, ITEMSIZE+2, 28H, 1
	ret
ENDP display_item_selected

PROC display_BUTTON_selected
	ARG @@selection

	cmp [@@selection], START_BUTTON
	jne @@stop
	call draw, START_X, START_Y, SELECTED_BUTTON, offset BUTTONS, 0
	@@stop:
	cmp [@@selection], STOP_BUTTON
	jne @@dontdraw
	call draw, STOP_X, STOP_Y, SELECTED_BUTTON, offset BUTTONS, 0
	@@dontdraw:
	ret
ENDP display_BUTTON_selected

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                             VIDEO MODE                                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROC copyVMADR
	CLD                          ; ESI and EDI increase
	MOV ESI, OFFSET screenBuffer ; temporary buffer address
	MOV EDI, VMADR            ; video memory address
	MOV ECX, 64000 / 4           ; copying double words
	REP MOVSD
	ret
ENDP copyVMADR

; Set the video mode
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode


; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

END
