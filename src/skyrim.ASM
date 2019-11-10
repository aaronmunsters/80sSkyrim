; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Aäron Munsters, Corneel Soete
; date:		22/12/2018 ~ program:	80's Skyrim
; -------------------------------------------------------------------

; note: tasm returns warnings like 'Instruction can be compacted with override'
; online reseach suggests writing 'short' in front of the jump on which tasm gives a warning.
; However, this results in some procedures behaving odd. Thus we will not use this advise.
; suggestion: delphigroups.info/2/8a/7715.html

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "graphics.inc"
INCLUDE "sprites.inc"
INCLUDE "skrmMcrs.asm"; this will contain some macros
INCLUDE "logicf.asm"; logic functions which are the foundation of the program (these could certainly be used for a different project!)

; -------------------------------------------------------------------
UDATASEG
rand_seed DD ?; used by rand-call

currFieldMobs DD ?; will be ptr to worldMobs (should be initialised)

MINIMAP DB 800h DUP(?)

; -------------------------------------------------------------------
DATASEG

inventory DD INVENTORY_SIZE DUP(EMPTY); fills array with empty items reserving inventory

HEAD_item  DD EMPTY;
CHEST_item DD EMPTY;
A_item     DD EMPTY;
B_item     DD EMPTY;--> player starts out with no items

gameTick DB 0; increments once every GAME_TICK_INTERVAL times CYCLES has incremented

mobs_suspicion_tick DB MOBS_NON_SUSPICIOUS_GAME_TICK

CYCLES DD 0; increments every VBI

;W(eapon), A(rmour), H(elmet), L(ives), D(irection), X(-co), Y(-co), A(ctive)
;        TTWWSAHLLDDXXXXYYYA
DOVAH DD 0000000111000000001b; main character
; No Weapon/Armour/Helmet, all lives, facing south, standing (8, 4), Visible

;T(ype of mob), I(nteligence moment), M(ode of AI), W(eapon), A(rmour), H(elmet), L(ives), D(irection), X(-co), Y(-co), A(ctive)
;																														  IIMTTWWSAHLLDDXXXXYYYA
worldMobs DD FIELDS_IN_WORLD*MAX_AMOUNT_OF_MOBS_PER_FIELD DUP(0000100011110010001001b); all mobs start out blank

WORLD DB  0,  1,  2,  3
	 		DB  4,  5,  6,  7
	 		DB  8,  9, 10, 11
	 		DB 12, 13, 14, 15

FIELD DD 12

ProgramLoop DB IN_GAME

MenuButtons DB TRUE; buttons or inventory
MenuInvX DD 0
MenuInvY DD 0
MenuBttn DD START

;            XXYY --> in WORLD-matrix
FIELD_POS DD 0011b
;------------------------------------------------------------------------------
CODESEG
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Some abstraction to make to code easier to read
PROC walkable?; assigns TRUE or FALSE to EAX; nothing else!
  ARG @@Cell:dword
	call getDataVal, [@@Cell], SHIFT_WALKABILITY, BITS_WALKABILITY
  ret
ENDP walkable?


PROC active?
	ARG @@entity:dword
	call getDataVal, [@@entity], SHIFT_ACTIVE, BITS_ACTIVE
	ret
ENDP active?


PROC alive?
	ARG @@entity:dword
	call getDataVal, [@@entity], SHIFT_LIFE, BITS_LIFE
	cmp eax, DEAD
	je @@dead
	mov eax, TRUE
	ret
	@@dead:
	mov eax, FALSE;; entity is NOT alive
	ret
ENDP alive?


PROC getDirection; puts direction in EAX; nothing else!
  ARG @@entity:dword
	call getDataVal, [@@entity], SHIFT_DIRECTION, BITS_DIRECTION
  ret
ENDP getDirection


PROC giveEntityNewDirection; This will put updated entity in EAX; nothing else!
  ARG @@entity: dword, @@direction:dword
	call giveDataNewVal, [@@entity], [@@direction], SHIFT_DIRECTION, BITS_DIRECTION
	ret
ENDP giveEntityNewDirection

PROC giveEntiyNewXcoor; This will put updated entity in EAX; nothing else!
  ARG @@entity: dword, @@xcoor:dword
	call giveDataNewVal, [@@entity], [@@xcoor], SHIFT_X_POS, BITS_X_POS
	ret
ENDP giveEntiyNewXcoor


PROC giveEntiyNewYcoor; This will put updated entity in EAX; nothing else!
  ARG @@entity: dword, @@ycoor:dword
	call giveDataNewVal, [@@entity], [@@ycoor], SHIFT_Y_POS, BITS_Y_POS
	ret
ENDP giveEntiyNewYcoor


PROC giveEntiyNewLifeVal; This will put updated entity in EAX; nothing else!
  ARG @@entity: dword, @@liveVal:dword
	call giveDataNewVal, [@@entity], [@@liveVal], SHIFT_LIFE, BITS_LIFE
	ret
ENDP giveEntiyNewLifeVal
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Game-logic related functions
PROC getRelPosition; puts in eax the x-coordinate, in ebx the y-coordinate
	USES ecx
	ARG @@xCoord:dword, @@yCoord:dword, @@direction:dword, @@distance:dword
	mov eax, [@@xCoord]
	mov ebx, [@@yCoord]
	mov ecx, [@@distance]

	; checking direction
	cmp [@@direction], UP
	je @@moveUp
	cmp [@@direction], RIGHT
	je @@moveRight
	cmp [@@direction], DOWN
	je @@moveDown
	; adjusting X- or Y-value
	;@@moveLeft
	sub [@@xCoord], ecx
	jmp @@restore
	@@moveUp:
	sub [@@yCoord], ecx
	jmp @@restore
	@@moveRight:
	add [@@xCoord], ecx
	jmp @@restore
	@@moveDown:
	add [@@yCoord], ecx
 ;jmp @@restore:
	@@restore:; storing new position
	mov eax, [@@xCoord]
	mov ebx, [@@yCoord]
	ret
ENDP getRelPosition


PROC getRelCellPosition
	USES ebx
	ARG @@distance:dword, @@direction:dword, @@cellCoordinates:dword; distance [0,15]
	LOCAL @@xCoord:dword, @@yCoord:dword

	call getDataVal, [@@cellCoordinates], SHIFT_X_POS, BITS_X_POS
	mov [@@xCoord], eax
	call getDataVal, [@@cellCoordinates], SHIFT_Y_POS, BITS_Y_POS
	mov [@@yCoord], eax
	call getRelPosition, [@@xCoord], [@@yCoord], [@@direction], 1
	;; x -> eax, y -> ebx
	call giveDataNewVal, [@@cellCoordinates], eax, SHIFT_X_POS, BITS_X_POS
	mov [@@cellCoordinates], eax
	call giveDataNewVal, [@@cellCoordinates], ebx, SHIFT_Y_POS, BITS_Y_POS
	; return-value stored in eax
	ret
ENDP getRelCellPosition


PROC moveCurrFieldMobs
	USES eax, ecx
	ARG @@fieldIdx:dword; we need currFieldMobs = offset worldMobs + fieldIdx * MAX_AMOUNT_OF_MOBS_PER_FIELD
	mov eax, offset worldMobs
	mov ecx, [@@fieldIdx]
	inc ecx
	@@shiftWorldMobs:
	add eax, MAX_AMOUNT_OF_MOBS_PER_FIELD*4; This 4 reflects to the size in bytes, being a double word!
	loop @@shiftWorldMobs
	sub eax, MAX_AMOUNT_OF_MOBS_PER_FIELD*4
	mov [currFieldMobs], eax
	ret
ENDP moveCurrFieldMobs


PROC moveWindow;; This procedure stores in EAX if the window effectively moved
	USES ebx
	ARG @@direction:dword
	LOCAL @@currX:dword, @@currY:dword
	; store current X- and Y-values
	call getDataVal, [FIELD_POS], SHIFT_WORLD_X, BITS_WORLD_X
	mov [@@currX], eax
	call getDataVal, [FIELD_POS], SHIFT_WORLD_Y, BITS_WORLD_Y
	mov [@@currY], eax
	; boundarie-check
	cmp [@@direction], UP
	je @@upCheck
	cmp [@@direction], RIGHT
	je @@rightCheck
	cmp [@@direction], DOWN
	je @@downCheck
	;@@leftCheck
	cmp [@@currX], LEFTMOST_WORLD_X_VAL
	je @@DontMoveWindow
	jmp @@moveWindow
	@@upCheck:
	cmp [@@currY], HIGHEST_WORLD_Y_VAL
	je  @@DontMoveWindow
	jmp @@moveWindow
	@@rightCheck:
	cmp [@@currX], RIGHTMOST_WORLD_X_VAL
	je @@DontMoveWindow
	jmp @@moveWindow
	@@downCheck:
	cmp [@@currY], LOWEST_WORLD_Y_VAL
	je @@DontMoveWindow
	@@moveWindow:
	; calculate new cell-value
	call getRelPosition, [@@currX], [@@currY], [@@direction], 1
	; x -> eax, y -> ebx
	mov [@@currX], eax
	mov [@@currY], ebx
	call giveDataNewVal, [FIELD_POS], [@@currX], SHIFT_WORLD_X, BITS_WORLD_X
	call giveDataNewVal,         eax, [@@currY], SHIFT_WORLD_Y, BITS_WORLD_Y
	mov [FIELD_POS], eax; save new x and y
	call set_field, [@@currX], [@@currY]; in eax now is field-index
	call moveCurrFieldMobs, [FIELD]
	mov [mobs_suspicion_tick], MOBS_NON_SUSPICIOUS_GAME_TICK; restore calm mobs
	mov eax, TRUE
	ret
	@@DontMoveWindow:
	mov eax, FALSE
	ret
ENDP moveWindow


PROC moveEntity; puts in eax the entity moved in it's direction,
	; This proc also takes care of the event of shifting the world-view:
	; entities which are not followed by the camera can not move off screen!
  USES ebx
	ARG @@entity:dword, @@followEntity:dword; boolean to determine to follow entity (in world) --> WARNING: NO 2 ENTITIES SHOULD LEAVE THE FIELD AND BE FOLLOWED!
  LOCAL @@currentX:dword, @@currentY:dword, @@newX:dword, @@newY:dword, @@active?:dword
	mov eax, [@@entity]
	; store current location (newX/Y won't always be overwritten but will be used)
	call getDataVal, [@@entity], SHIFT_X_POS, BITS_X_POS
	mov [@@currentX], eax
	mov [@@newX], eax
	call getDataVal, [@@entity], SHIFT_Y_POS, BITS_Y_POS
	mov [@@currentY], eax
	mov [@@newY], eax

	; check where entity will be heading
  call getDirection, [@@entity]
  cmp eax, UP
  je @@getUpCell
  cmp eax, RIGHT
  je @@getRightCell
  cmp eax, DOWN
  je @@getDownCell
 ;@@getLeftCell
		cmp [@@currentX], LEFTMOST_X_VAL
		jne @@continueLeft
	 ;check if entity should be followed:
	 	cmp [@@followEntity], TRUE
		jne @@storeNewEntity
	 ;move to bottom and move window
		call moveWindow, LEFT
		cmp eax, TRUE
		jne @@storeNewEntity
		mov [@@newX], RIGHTMOST_X_VAL
		jmp @@storeNewEntity
	@@continueLeft:
  	call getRelCellPosition, 1, LEFT, [@@entity]
  	jmp @@walkable
  @@getUpCell:
		cmp [@@currentY], HIGHEST_Y_VAL
		jne @@continueUp
 	 	cmp [@@followEntity], TRUE
 		jne @@storeNewEntity
		call moveWindow, UP
		cmp eax, TRUE
		jne @@storeNewEntity
		mov [@@newY], LOWEST_Y_VAL
		jmp @@storeNewEntity
	@@continueUp:
    call getRelCellPosition, 1, UP, [@@entity]
    jmp  @@walkable
  @@getRightCell:
		cmp [@@currentX], RIGHTMOST_X_VAL
		jne @@continueRight
 	 	cmp [@@followEntity], TRUE
 		jne @@storeNewEntity
		call moveWindow, RIGHT
		cmp eax, TRUE
		jne @@storeNewEntity
		mov [@@newX], LEFTMOST_X_VAL
		jmp @@storeNewEntity
	@@continueRight:
    call getRelCellPosition, 1, RIGHT, [@@entity]
    jmp @@walkable
  @@getDownCell:
		cmp [@@currentY], LOWEST_Y_VAL
		jne @@continueDown
 	 	cmp [@@followEntity], TRUE
 		jne @@storeNewEntity
		call moveWindow, DOWN
		cmp eax, TRUE
		jne @@storeNewEntity
		mov [@@newY], HIGHEST_Y_VAL
		jmp @@storeNewEntity
	@@continueDown:
    call getRelCellPosition, 1, DOWN, [@@entity]
  @@walkable:
	  ; in eax currently is the position XXXXYYY0
		mov ebx, eax; to have copy
		call getDataVal, ebx, SHIFT_X_POS, BITS_X_POS
		mov [@@newX], eax
		call getDataVal, ebx, SHIFT_Y_POS, BITS_Y_POS
		mov [@@newY], eax
		call calc_cell_in_field, [@@newX], [@@newY]; puts in EAX cell
	  call walkable?, eax; puts result in EAX
	  cmp eax, TRUE
		mov eax, [@@entity]
	  jne @@done
	@@storeNewEntity:
		call giveEntiyNewXcoor, [@@entity], [@@newX]
		call giveEntiyNewYcoor, eax, [@@newY]
  @@done:
  	ret
ENDP moveEntity


PROC damageDefence; expects in ebx the entity, ecx damage left to do, returns in ebx the updated entity and ecx dmg left to do
	ARG @@defenceShift:dword, @@defenceBits, @@affectsDovahInv:dword, @@slotOffset:dword, @@invItm:dword
	USES eax
	call getDataVal, ebx, [@@defenceShift], [@@defenceBits]
	cmp eax, WEARING
	jne @@done; else is wearing and should take off!
	call giveDataNewVal, ebx, NOT_WEARING, [@@defenceShift], [@@defenceBits]
	mov ebx, eax
	cmp [@@affectsDovahInv], TRUE
	jne short @@doneDamage
	mov eax, [@@slotOffset]; to point to right offset
	mov [eax], EMPTY; to clear the players slot
	call removeItem, [@@invItm]
	@@doneDamage:
	dec ecx
	@@done:
	ret
ENDP damageDefence

PROC doDamage; returns updated enemy in eax
	ARG @@entity:dword, @@damage:dword, @@affectsDovahInv:dword; this should be true if it is DOVAH who's taking damage
	USES ebx, ecx, edx
	;; enemy first loses shield (1 hit) helmet (1 hit), then armour (1 hit) and finally lives
	;; eg: enemy wears helmet & armour & has 3 lives, takes 3 dmg -> 2 lives left
	cmp [@@damage], 0
	je @@done
	mov ecx, [@@damage]; this will be the counter
	mov ebx, [@@entity]; this will be constantly updated
	call damageDefence, SHIFT_SHIELD, BITS_SHIELD, [@@affectsDovahInv], offset B_item, SHIELD
	cmp ecx, 0
	je @@done
	call damageDefence, SHIFT_HELMET, BITS_HELMET, [@@affectsDovahInv], offset HEAD_item, HELMET
	cmp ecx, 0
	je @@done
	call damageDefence, SHIFT_ARMOUR, BITS_ARMOUR, [@@affectsDovahInv], offset CHEST_item, CHEST
	cmp ecx, 0
	je @@done
	call getDataVal, ebx, SHIFT_LIFE, BITS_LIFE
	@@removeLivesLoop:
	cmp eax, 1;; if life is 1, entity will be dead anyway!
	je @@deadEntity
	dec eax
	loop @@removeLivesLoop; after this loop all damage is done
	call giveEntiyNewLifeVal, [@@entity], eax
	mov ebx, eax
	@@done:
	mov eax, ebx; adjusted enemy
	ret
	@@deadEntity:
	call giveEntiyNewLifeVal, ebx, DEAD
	mov ebx, eax
	jmp @@done
ENDP doDamage


PROC meleeDagame; when an entity is doing damage; this procedure will be called if the damage-type is meleeDagame
	; what it does: calc relative position to damaging-entity and map 'takeDamage' on those who are standing where damage is done
	USES eax, ebx, ecx, edx
	ARG @@damagingEntity:dword, @@damage:dword; we assume it's a dagger do damage to mob who [@@damagingEntity] is facing
	LOCAL @@dmgnEntX:dword, @@dmgnEntY:dword, @@dmgnEntDir:dword, @@dmgTkngEtt:dword, @@takingX:dword, @@takingY:dword
	;     damagingEntity-X, damagingEntity-X, damagingEntity-dir, damageTakingEntity, dmgTakngEntityX, dmgTakngEntityY
	mov ecx, MAX_AMOUNT_OF_MOBS_PER_FIELD
	cmp ecx, 0
	je @@done
	;; store right information:
	call getDataVal, [@@damagingEntity], SHIFT_X_POS, BITS_X_POS
	mov [@@dmgnEntX], eax
	call getDataVal, [@@damagingEntity], SHIFT_Y_POS, BITS_Y_POS
	mov [@@dmgnEntY], eax
	call getDirection, [@@damagingEntity]
	mov [@@dmgnEntDir], eax

	;; get position where damage takes place:
	call getRelPosition, [@@dmgnEntX], [@@dmgnEntY], eax, 1
	mov [@@takingX], eax
	mov [@@takingY], ebx

	;; loop over all enemies and check if they're on same pos -> if so do damage
	mov ebx, [currFieldMobs]; dereference!
	@@forEveryMob:

	mov eax, [dword ptr ebx + 4*ecx - 4]
	mov [@@dmgTkngEtt], eax
	call getDataVal, [@@dmgTkngEtt], SHIFT_X_POS, BITS_X_POS
	cmp eax, [@@takingX]
	jne @@skipEntity
	call getDataVal, [@@dmgTkngEtt], SHIFT_Y_POS, BITS_Y_POS
	cmp eax, [@@takingY]
	jne @@skipEntity
	;; in this case the mob should take damage:
	call doDamage, [@@dmgTkngEtt], DAGGER_DAMAGE, FALSE
	mov [dword ptr ebx + 4*ecx - 4], eax
	@@skipEntity:
	loop @@forEveryMob
	@@done:
	ret
ENDP meleeDagame


PROC useItem
	ARG @@entity:dword, @@item:dword
	cmp [@@item], EMPTY
	je @@done
	cmp [@@item], DAGGER
	jne @@notDagger
	call meleeDagame, [DOVAH], DAGGER
	@@notDagger:
	;; items
	@@done:
	ret
ENDP useItem


PROC checkKeyPresses
	USES eax
	mov ah, [__keyb_rawScanCode]; get latest scancode
  ;http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
  cmp ah, KEY_UP
  je @@UPpressed
  cmp ah, KEY_DOWN
  je @@DOWNpressed
  cmp ah, KEY_LEFT
  je @@LEFTpressed
  cmp ah, KEY_RIGHT
  je @@RIGHTpressed
  cmp ah, KEY_ESC
  je @@ESCpressed
	cmp ah, KEY_A
	je @@Apressed
	cmp ah, KEY_B
	je @@Bpressed
	ret

  @@UPpressed:
  call giveEntityNewDirection, [DOVAH], UP
  jmp @@ArrowKeyPressed
  @@DOWNpressed:
  call giveEntityNewDirection, [DOVAH], DOWN
  jmp @@ArrowKeyPressed
  @@RIGHTpressed:
  call giveEntityNewDirection, [DOVAH], RIGHT
  jmp @@ArrowKeyPressed
  @@LEFTpressed:
  call giveEntityNewDirection, [DOVAH], LEFT
  jmp @@ArrowKeyPressed
  @@ESCpressed:
	not [ProgramLoop]
	jmp @@NoKeyPressed
	@@Apressed:
	call useItem, [DOVAH], [A_item]
	jmp @@NoKeyPressed
	@@Bpressed:
	call useItem, [DOVAH], [B_item]
	jmp @@NoKeyPressed
  @@ArrowKeyPressed:
  mov [DOVAH], eax; updates DOVAH with new direction
	call active?, [DOVAH]
	cmp eax, TRUE
	jne @@NoKeyPressed
  call moveEntity, [DOVAH], TRUE
	mov [DOVAH], eax
  @@NoKeyPressed:
	mov [__keyb_rawScanCode], 0; clear last pressed state
  ret
ENDP checkKeyPresses


PROC updateField
	USES eax
	;; vvvv---all the time---vvvv
	call aliveCheck, [currFieldMobs], MAX_AMOUNT_OF_MOBS_PER_FIELD
	;; ^^^^---all the time---^^^^

	; update gameTick
	inc [gameTick]
	mov al, [mobs_suspicion_tick]
	cmp [gameTick], al
	jne @@noFullGameTick
	;; vvvv---every GAME_TICK_INTERVAL---vvvv
	call updateEntities, [currFieldMobs], MAX_AMOUNT_OF_MOBS_PER_FIELD
	;; ^^^^---every GAME_TICK_INTERVAL---^^^^
	mov [gameTick], 0
	@@noFullGameTick:
	add [CYCLES], 1
	ret
ENDP updateField


PROC insertInInventory; returns TRUE in eax if item is inserted
	ARG @@item:dword
	USES ecx
	cmp [@@item], EMPTY
	je @@didntAdd
	;; fills up inventory from left to right, top to bottom
	;; below could've been cleaner if vvv was a valid expression
	;cmp [dword ptr inventory + 4*(INVENTORY_SIZE - ecx)], EMPTY
	mov ecx, 0
	@@searchForEmptySpot:
	cmp [dword ptr inventory + 4*ecx], EMPTY; looking for empty spot
	je @@insert
	inc ecx
	cmp ecx, INVENTORY_SIZE
	je @@didntAdd; couldn't add any more; inventory is full
	jmp @@searchForEmptySpot
	@@insert:
	mov eax, [@@item]
	mov [dword ptr inventory + 4*ecx], eax; insert item in inventory
	mov eax, TRUE
	ret
	@@didntAdd:
	mov eax, FALSE
	ret
ENDP insertInInventory


PROC checkPlayerStatus
	USES eax
	LOCAL @@playerX:dword, @@playerY:dword, @@cell:dword
	;; check if player is still alive
	call alive?, [DOVAH]
	cmp eax, FALSE
	je  @@setInactive
	;; other 'player-check-code'
	;; checking if player stands on item:
	call getDataVal, [DOVAH], SHIFT_Y_POS, BITS_Y_POS
	mov [@@playerY], eax
	call getDataVal, [DOVAH], SHIFT_X_POS, BITS_X_POS
	mov [@@playerX], eax
	call calc_cell_in_field, [@@playerX], [@@playerY]
	mov [@@cell], eax
	call getDataVal, [@@cell], SHIFT_ITEM, BITS_ITEM; store in eax the item
	call insertInInventory, eax;; tries to put item in player-inventory
	cmp eax, FALSE; if no item was picked up
	je @@doNotPickUp
	call giveDataNewVal, [@@cell], EMPTY, SHIFT_ITEM, BITS_ITEM
	call change_cell_in_field, [@@playerX], [@@playerY], eax; remove item on floor
	@@doNotPickUp:
	;; any further player-checks should be written here!
	@@done:
  ret
	@@setInactive:
	call giveDataNewVal, [DOVAH], INACTIVE, SHIFT_ACTIVE, BITS_ACTIVE
	mov [DOVAH], eax
	ret
ENDP checkPlayerStatus


PROC change_cell_in_field; Heavily based on 'calc_cell_in_field'
	ARG @@X:dword, @@Y:dword, @@Cell:dword
	USES eax, ebx, edx
	xor eax, eax

	;sets offset to correct position in field
	mov ebx, [FIELD]
		 mov al, [FIELDS]
		 mov dl, [FIELDS + 1]
		 mul dl
		 mul ebx
		 mov ebx, eax
		 add ebx, 2

	;calculate in which index of the field the cell is stored
	mov eax, [@@Y]
	mov edx, FIELDWIDTH
	mul edx
	mov edx, [@@X]
	add eax, edx
	add eax, ebx
	;loop through the FIELD to give back the right cell
	mov ebx, [@@Cell]
	mov [FIELDS + eax], bl
	ret
ENDP change_cell_in_field


PROC calc_cell_in_field; assigns the right cell to eax
	ARG @@X: dword, @@Y: dword
	USES ebx, edx
	xor eax, eax

	;sets offset to correct position in field
	mov ebx, [FIELD]
     mov al, [FIELDS]
     mov dl, [FIELDS + 1]
     mul dl
     mul ebx
     mov ebx, eax
     add ebx, 2

	;calculate in which index of the field the cell is stored
 	mov eax, [@@Y]
	mov edx, FIELDWIDTH
	mul edx
	mov edx, [@@X]
	add eax, edx
  	add eax, ebx
	;loop through the FIELD to give back the right cell
	mov al, [FIELDS + eax]
   ret
ENDP calc_cell_in_field


PROC set_field;gets an x and y coord in the world and sets the field to this
	ARG @@X: dword, @@Y: dword
	USES eax, edx
	;calculate in which index of the field the cell is stored
	mov eax, [@@Y]
	mov edx, WORLDWIDTH
	mul edx
	mov edx, [@@X]
	add eax, edx
	;loop through the FIELD to give back the right cell
	movzx eax, [WORLD + eax]
	mov [FIELD], eax
	ret
ENDP set_field


PROC drawcell
   ARG @@X: dword, @@Y: dword
	 LOCAL @@field:dword
	 USES eax, ebx, ecx, edx
   call calc_cell_in_field, [@@X], [@@Y]
   mov [@@field], eax
   call getDataVal, [@@field], SHIFT_TERRAIN, BITS_TERRAIN
   call display_terrain, eax, [@@X], [@@Y]
   call getDataVal, [@@field], SHIFT_ITEM, BITS_ITEM
   call display_item, eax, [@@X], [@@Y]
   ret
ENDP drawcell


PROC drawDovah
  LOCAL @@xCoor:dword, @@yCoor:dword, @@direction:dword
	call drawEntity, [DOVAH]
  ret
ENDP drawDovah


PROC actNonAgressive
	USES ebx, ecx, edx
	ARG @@entity:dword
	LOCAL @@dovahX:dword, @@dovahY:dword, @@entityX:dword, @@entityY:dword, @@entityDir:dword, @@relX:dword, @@relY:dword
	;; store dovah position
	call getDataVal, [DOVAH], SHIFT_X_POS, BITS_X_POS
	mov [@@dovahX], eax
	call getDataVal, [DOVAH], SHIFT_Y_POS, BITS_Y_POS
	mov [@@dovahY], eax
	call getDataVal, [@@entity], SHIFT_X_POS, BITS_X_POS
	mov [@@entityX], eax
	call getDataVal, [@@entity], SHIFT_Y_POS, BITS_Y_POS
	mov [@@entityY], eax
	call getDirection, [@@entity]
	mov [@@entityDir], eax
	;; compare line of sight width dovah's position
	mov ecx, MOBS_SIGHT
	@@lookForward:
	; count up to rel distance ; if not you could see through walls/bushes/...
	mov edx, MOBS_SIGHT
	inc edx
	sub edx, ecx
	call getRelPosition, [@@entityX], [@@entityY], [@@entityDir], edx; = MOBS_SIGHT - ecx + 1
	mov [@@relX], eax
	mov [@@relY], ebx
	; check if cell-position is walkable (if not stop looking because mobs can't  see through walls)
	call calc_cell_in_field, eax, ebx
	call walkable?, eax
	cmp eax, TRUE
	jne @@notSeen
	mov eax, [@@relX]; restore relX
	mov ebx, [@@relY]; restore relY
	cmp eax, [@@dovahX]
	je @@maybeSeen
	loop @@lookForward
	jmp @@notSeen
	@@maybeSeen:
	cmp ebx, [@@dovahY]
	je @@seen
	loop @@lookForward
	jmp @@notSeen
	@@seen:
	mov [mobs_suspicion_tick] , MOBS_SUSPICIOUS_GAME_TICK;; every mob now gets suspicious
	cmp edx, 1; This is the effective counter! this checks if Dovah in front of enemy
	je @@getAggressive
	jmp @@start_walking
	@@getAggressive:; directly in front of:
	call giveDataNewVal, [@@entity], ATTACKING, SHIFT_AI_STATE, BITS_AI_STATE
	call giveDataNewVal, [@@entity], AGGRESSIVE, SHIFT_AI_MODE, BITS_AI_MODE
	ret
	@@notSeen:
	call getDataVal, [@@entity], SHIFT_AI_STATE, BITS_AI_STATE
	;; either walking or looking (rotating)
	cmp eax, STARTING; start of AI, certainly look around!
	je @@starting
	cmp eax, ROTATING; has been looking around, might want to start walking
	je @@rotating
	cmp eax, START_WALKING; start of walking!
	je  @@start_walking
	;@@walking; has been walking, might want to start over again
	call randOfSize, 1
	cmp eax, 0;; chance 1/2
	je @@moveForward
	;; else start out again
	call giveDataNewVal, [@@entity], STARTING, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@starting:
	call randOfSize, BITS_DIRECTION
	call giveEntityNewDirection, [@@entity], eax
	call giveDataNewVal, eax, ROTATING, SHIFT_AI_STATE, BITS_AI_STATE; next state
	ret
	@@rotating:; has been rotating and might want to start walking
	call randOfSize, 1
	cmp eax, 0
	je @@keepGoing
	call giveDataNewVal, [@@entity], START_WALKING, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@start_walking:
	call giveDataNewVal, [@@entity], WALKING, SHIFT_AI_STATE, BITS_AI_STATE
	mov [@@entity], eax
	jmp @@moveForward
	@@walking:
	call randOfSize, 1
	cmp eax, 0
	je @@moveForward
	call giveDataNewVal, [@@entity], STARTING, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@moveForward:
	call moveEntity, [@@entity], FALSE
	ret
	@@keepGoing:
	mov eax, [@@entity]
	ret
ENDP actNonAgressive


PROC actAgressive
	USES ebx, ecx, edx
	ARG @@entity:dword
	LOCAL @@dovahX:dword, @@dovahY:dword, @@entityX:dword, @@entityY:dword, @@entityDir:dword
	;; get current aggressive state and decide what to do
	call getDataVal, [@@entity], SHIFT_AI_STATE, BITS_AI_STATE
	cmp eax, IN_FRONT_OF
	je @@in_front_of
	cmp eax, ATTACKING
	je @@attack
	cmp eax, BACKED_UP
	je @@backed_up
	@@waiting_for_att:;; just to take 1 gametick
	call moveEntity, [@@entity], FALSE
	call giveDataNewVal, [@@entity], IN_FRONT_OF, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@in_front_of:;; just to take 1 gametick
	call giveDataNewVal, [@@entity], ATTACKING, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@attack:
	;; store dovah's position
	call getDataVal, [DOVAH], SHIFT_X_POS, BITS_X_POS
	mov [@@dovahX], eax
	call getDataVal, [DOVAH], SHIFT_Y_POS, BITS_Y_POS
	mov [@@dovahY], eax
	call getDataVal, [@@entity], SHIFT_X_POS, BITS_X_POS
	mov [@@entityX], eax
	call getDataVal, [@@entity], SHIFT_Y_POS, BITS_Y_POS
	mov [@@entityY], eax
	call getDirection, [@@entity]
	mov [@@entityDir], eax
	;; check if dovah is still in front of entity
	call getRelPosition, [@@entityX], [@@entityY], [@@entityDir], 1; 1 = next to
	cmp eax, [@@dovahX]
	je @@maybeSeen
	jmp  @@notSeen
	@@maybeSeen:
	cmp ebx, [@@dovahY]
	je @@seen
	jmp @@notSeen
	@@seen:;-> attack dovah
	call doDamage, [DOVAH], DAGGER_DAMAGE, TRUE;; mobs only do dagger-damage
	mov [DOVAH], eax; dovah has taken damage, now 'back up'!
	call getDirection, [@@entity]
	add eax, 2; this will turn enemy 180 degrees
	call giveEntityNewDirection, [@@entity], eax; this will discard the extra bit (eg.: LEFT + 2 == 11b + 10b == 101b)
	call moveEntity, eax, FALSE
	mov [@@entity], eax
	call getDirection, eax
	add eax, 2;; turn around again
	call giveEntityNewDirection, [@@entity], eax
	call giveDataNewVal, eax, BACKED_UP, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@notSeen:; dovah is lost, stop attacking
	call giveDataNewVal, [@@entity], NONAGGRESSIVE, SHIFT_AI_MODE, BITS_AI_MODE
	call giveDataNewVal, eax, STARTING, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@backed_up:
	call randOfSize, 1
	cmp eax, 0;; chance of 1/2
	je @@dontUpdate
	call giveDataNewVal, [@@entity], WAITING_FOR_ATT, SHIFT_AI_STATE, BITS_AI_STATE
	ret
	@@dontUpdate:
	mov eax, [@@entity]
	ret
ENDP actAgressive


PROC updateEntity; returns updated entity in eax
	ARG @@entity:dword
	USES ebx, ecx, edx
	call active?, [@@entity]
	cmp eax, TRUE
	jne @@dontUpdate
	;; else do update:
	call getDataVal, [@@entity], SHIFT_AI_MODE, BITS_AI_MODE
	cmp eax, AGGRESSIVE
	je @@actAgressive
	call actNonAgressive, [@@entity]
	ret
	@@actAgressive:
	call actAgressive, [@@entity]
	ret
	@@dontUpdate:
	mov eax, [@@entity]
	ret
ENDP updateEntity


PROC returnInactiveIfDead; returns enemy (active if not dead & vice versa)
	ARG @@entity:dword
	call alive?, [@@entity]
	cmp eax, TRUE
	jne @@setInactive
	@@return:
	mov eax,[@@entity]
	ret
	@@setInactive:
	call giveDataNewVal, [@@entity], INACTIVE, SHIFT_ACTIVE, BITS_ACTIVE
	ret
ENDP returnInactiveIfDead


PROC updateEntities
	ARG @@pointerToEntities:dword, @@amountOfEntites:dword
	call mapMem, [@@pointerToEntities], [@@amountOfEntites], offset updateEntity
	ret
ENDP updateEntities


PROC aliveCheck
	ARG @@pointerToEntities:dword, @@amountOfEntites:dword
	call mapMem, [@@pointerToEntities], [@@amountOfEntites], offset returnInactiveIfDead
	ret
ENDP aliveCheck


PROC drawEntities
	ARG @@pointerToEntities:dword, @@amountOfEntites:dword
	call forEachMem, [@@pointerToEntities], [@@amountOfEntites], offset drawEntity
	ret
ENDP drawEntities


PROC drawEntity
	USES eax
	ARG @@entity:dword
	;; all which will need to be drawn
	LOCAL @@entityX:dword,    @@entityY:dword,			 @@entityDirection:dword
	LOCAL @@entityWeap:dword, @@entityHelmet:dword,  @@entityArmour:dword, @@entityShield:dword
	LOCAL @@entityType:dword,	@@entityLife:dword

	call active?, [@@entity]
	cmp eax, TRUE
	jne @@done
	call getDirection, [@@entity]
	mov [@@entityDirection], eax
	call getDataVal, [@@entity], SHIFT_X_POS, BITS_X_POS
	mov [@@entityX], eax
	call getDataVal, [@@entity], SHIFT_Y_POS, BITS_Y_POS
	mov [@@entityY], eax
	call getDataVal, [@@entity], SHIFT_LIFE, BITS_LIFE
	mov [@@entityLife], eax
	call getDirection, [@@entity]
	mov [@@entityDirection], eax
	call getDataVal, [@@entity], SHIFT_WEAPON, BITS_WEAPON
	mov [@@entityWeap], eax
	call getDataVal, [@@entity], SHIFT_HELMET, BITS_HELMET
	mov [@@entityHelmet], eax
	call getDataVal, [@@entity], SHIFT_SHIELD, BITS_SHIELD
	mov [@@entityShield], eax
	call getDataVal, [@@entity], SHIFT_ARMOUR, BITS_ARMOUR
	mov [@@entityArmour], eax
	call getDataVal, [@@entity], SHIFT_ENT_TYPE, BITS_ENT_TYPE
	mov [@@entityType], eax
	cmp eax, TYPE_HUMAN
	je @@display_human
	cmp eax, TYPE_SKELETON
	je @@display_skeleton
	;; other possible mob type compares
	;; last possible:
	call display_draughr, [@@entityX], [@@entityY], [@@entityDirection], [@@entityLife]
	jmp @@drawEquipment
	@@display_human:
	call display_dovah, [@@entityX], [@@entityY], [@@entityDirection], 0; no lives (this is drawn by ui)
	jmp @@drawEquipment
	@@display_skeleton:
	call display_skeleton, [@@entityX], [@@entityY], [@@entityDirection], [@@entityLife]
	jmp @@drawEquipment
	@@done:
	ret
	@@drawEquipment:
	cmp [@@entityHelmet], WEARING_HELMET
	jne @@skipHelmet
	call display_helmet, [@@entityX], [@@entityY], [@@entityDirection]
	@@skipHelmet:
	cmp [@@entityArmour], WEARING_ARMOUR
	jne @@skipArmour
	call display_armor, [@@entityX], [@@entityY], [@@entityDirection]
	@@skipArmour:
	cmp [@@entityShield], WEARING_SHIELD
	jne @@skipShield
	call display_shield, [@@entityX], [@@entityY], [@@entityDirection]
	@@skipShield:
	cmp [@@entityWeap], NO_WEAP
	je @@done
	cmp [@@entityWeap], MELEE
	jne @@noSword
	call display_sword, [@@entityX], [@@entityY], [@@entityDirection]
	ret
	@@noSword:
	cmp [@@entityWeap], RANGE
	jne @@noRange
	call display_bow, [@@entityX], [@@entityY], [@@entityDirection]
	ret
	@@noRange:
	call display_staff, [@@entityX], [@@entityY], [@@entityDirection]
	ret
ENDP drawEntity


PROC drawField;procedure that loops through field and prints every cell
  USES eax, ecx, edx
  mov edx, 0
  mov ecx, 0
  @@horizloop:
    @@vertloop:
	  call drawcell, edx, ecx
	  inc ecx
	  cmp ecx, FIELDHEIGHT
	  jne @@vertloop
    mov ecx, 0
    inc edx
    cmp edx, FIELDWIDTH
    jne @@horizloop
  ret
ENDP drawField


PROC draw_inventory_item
	USES eax, ebx
	ARG @@item:dword, @@index:dword
	; need to dec by 1 (offset counts from 0, not 1)
	; then divide by inventory-width
	; remainder is x-coord, quotient is y-coord
	dec [@@index]
	mov eax, [@@index]
	movzx ax, al
	mov bh, INVENTORY_WIDTH
	div bh
	; x -> ah ; y -> al
	movzx ebx, al
	movzx eax, ah
	call display_inventory_item, [@@item], eax, ebx
	ret
ENDP draw_inventory_item


PROC draw_inventory
	USES eax, ebx, ecx
	mov ecx, INVENTORY_SIZE
	cmp ecx, 0
	je @@done
	mov ebx, offset inventory; contains memory-adress
	@@forEveryItem:
	mov eax, [dword ptr ebx + 4*ecx - 4]; take item
	call draw_inventory_item, eax, ecx
	loop @@forEveryItem
	@@done:
	ret
ENDP draw_inventory


PROC draw_lives
	USES eax
	call getDataVal, [DOVAH], SHIFT_LIFE, BITS_LIFE
	call display_lives, eax
	ret
ENDP draw_lives


PROC draw_equipables
	call display_equipable_item, [HEAD_item], 0
	call display_equipable_item, [B_item], 2;; right!
	call display_equipable_item, [CHEST_item], 3
	call display_equipable_item, [A_item], 1;; right!
	ret
ENDP draw_equipables


PROC drawEverything
	call fillBackground
	call drawField
	call display_UI
	call draw_equipables
	call display_map, offset MINIMAP, [FIELD]
	call draw_inventory
	call drawEntities, [currFieldMobs], MAX_AMOUNT_OF_MOBS_PER_FIELD
	call drawDovah
	call draw_lives
	call copyVMADR
	ret
ENDP drawEverything


PROC makeMap
	USES eax, ecx

	@@maploop:
	movzx eax, [FIELDS + ecx + 2]
	call getDataVal, eax, SHIFT_TERRAIN, BITS_TERRAIN
	mov [MINIMAP + ecx], al
	inc ecx
	cmp ecx, 800H
	jne @@maploop

	ret
ENDP makeMap


PROC awaitVBIStart; Procedure to wait for a v-blank event (synchronizes game loop to 60Hz in mode 13h)
    USES eax, edx
    mov dx, 03dah
    @@waitVBlank_wait1:
    in al, dx
    and al, 8
    jnz @@waitVBlank_wait1
    @@waitVBlank_wait2:
    in al, dx
    and al, 8
    jz @@waitVBlank_wait2
    ret
ENDP awaitVBIStart


PROC movSelectionCursor
	USES eax, ebx, ecx, edx
	ARG @@direction:dword
	xor edx, edx
	cmp [MenuButtons], TRUE;; determine to loop between buttons or loop in selection
	je @@checkBttns;; else navigate in items
	cmp [@@direction], UP
	je @@tryUp
	cmp [@@direction], RIGHT
	je @@tryRight
	cmp [@@direction], DOWN
	je @@tryDown;; else direction is left, so try left:
	cmp [MenuInvX], INVENTORY_LEFTMOST_X_VAL
	jne @@justMoveCursor;; else turn back to buttons
	mov [MenuButtons], TRUE
	ret
	@@tryUp:
	cmp [MenuInvY], INVENTORY_HIGHEST_Y_VAL
	jne @@justMoveCursor
	ret;; do nothing
	@@tryRight:
	cmp [MenuInvX], INVENTORY_RIGHTMOST_X_VAL
	jne @@justMoveCursor
	ret;; do nothing
	@@tryDown:
	cmp [MenuInvY], INVENTORY_LOWEST_Y_VAL
	jne @@justMoveCursor
	ret
	@@justMoveCursor:
	call getRelPosition, [MenuInvX], [MenuInvY], [@@direction], 1; eax = x, ebx = y
	mov [MenuInvX], eax
	mov [MenuInvY], ebx
	ret
	@@checkBttns:
	cmp [@@direction], UP
	je @@loopBttns
	cmp [@@direction], DOWN
	je @@loopBttns
	mov [MenuButtons], FALSE
	ret
	@@loopBttns:
	cmp [MenuBttn], START
	jne @@setStart
	mov [MenuBttn], EXIT
	ret
	@@setStart:
	mov [MenuBttn], START
	ret
ENDP movSelectionCursor


PROC getItem
	ARG @@x:dword, @@y:dword
	USES ebx, ecx; item = itemOffset + y*width + x
	mov eax, INVENTORY_WIDTH
	mov ebx, [@@y]
	mul ebx
	add eax, [@@x]; eax now contains right offset
	mov ebx, offset inventory
	mov ecx, eax
	mov eax, [dword ptr ebx + 4*ecx]
	ret
ENDP getItem


PROC removeItem; returns if item could be removed (found)
	ARG @@item:dword
	USES eax, ecx, edx
	mov ecx, 0
	mov edx, [@@item]
	@@searchForItem:
	cmp [dword ptr inventory + 4*ecx], edx; look if items match
	je @@remove
	inc ecx
	cmp ecx, INVENTORY_SIZE
	je @@didntRemove; couldn't find item
	jmp @@searchForItem
	@@remove:
	mov [dword ptr inventory + 4*ecx], EMPTY; insert item in inventory
	mov eax, TRUE
	ret
	@@didntRemove:
	mov eax, FALSE
	ret
ENDP removeItem


PROC clickInventory
	USES eax, ebx
	ARG @@button:dword; the player hovers over an item in the inventory and presses a button
	LOCAL @@selectedItem:dword
	call getItem, [MenuInvX], [MenuInvY]
	; if player clicks on a helmet/amour-piece this will be automatically worn in the correct slot
	cmp eax, CHEST
	je @@handleChest
	cmp eax, HELMET
	je @@handleHelmet
	; if player clicks a sword/staff/bow/shield, this too will be worn in the correct slot (and adjust dovah-properties)
	cmp eax, DAGGER
	je @@insertDagger
	cmp eax, BOW
	je @@insertBow
	cmp eax, STAFF
	je @@insertStaff
	cmp eax, SHIELD
	je @@insertShield
	; else put item in right slot
	cmp [@@button], A
	jne @@moveItemInB; else put item in A
	mov [A_item], eax
	call giveDataNewVal, [DOVAH], NO_WEAP, SHIFT_WEAPON, BITS_WEAPON
	mov [DOVAH], eax
	ret
	@@moveItemInB:
	mov [B_item], eax
	call giveDataNewVal, [DOVAH], NO_SHIELD, SHIFT_SHIELD, BITS_SHIELD
	mov [DOVAH], eax
	ret
	@@handleChest:
	cmp [CHEST_item], CHEST; player is wearing chest
	je @@takeOffChest;; else put on chest:
	mov [CHEST_item], CHEST
	call giveDataNewVal, [DOVAH], WEARING_ARMOUR, SHIFT_ARMOUR, BITS_ARMOUR
	mov [DOVAH], eax
	ret
	@@takeOffChest:
	mov [CHEST_item], EMPTY
	call giveDataNewVal, [DOVAH], NO_ARMOUR, SHIFT_ARMOUR, BITS_ARMOUR
	mov [DOVAH], eax
	ret
	@@handleHelmet:
	cmp [HEAD_item], HELMET; player is wearing helmet
	je @@takeOffHelmet;; else put on helmet:
	mov [HEAD_item], HELMET
	call giveDataNewVal, [DOVAH], WEARING_HELMET, SHIFT_HELMET, BITS_HELMET
	mov [DOVAH], eax
	ret
	@@takeOffHelmet:
	mov [HEAD_item], EMPTY
	call giveDataNewVal, [DOVAH], NO_HELMET, SHIFT_HELMET, BITS_HELMET
	mov [DOVAH], eax
	ret
	@@insertDagger:
	mov ebx, MELEE
	jmp @@insertHandItem
	@@insertBow:
	mov ebx, RANGE
	jmp @@insertHandItem
	@@insertStaff:
	mov ebx, MAGE
	@@insertHandItem:
	mov [A_item], eax
	call giveDataNewVal, [DOVAH], ebx, SHIFT_WEAPON, BITS_WEAPON
	mov [DOVAH], eax
	ret
	@@insertShield:
	mov [B_item], eax
	call giveDataNewVal, [DOVAH], ebx, SHIFT_SHIELD, BITS_SHIELD
	mov [DOVAH], eax
	ret
	@@done:
	ret
ENDP clickInventory


PROC clickButton
	ARG @@button:dword
	cmp [MenuButtons], TRUE
	jne @@selectItem;; else execute selection on menu-buttons:
	cmp [@@button], A
	je @@processSelection
	ret;; B does nothing (for the buttons)
	@@processSelection:
	cmp [MenuBttn], START
	jne @@exitGame
	not [ProgramLoop]; turn back to game
	ret
	@@exitGame:
	call terminateProcess
	ret
	@@selectItem:
	call clickInventory, [@@button]
	ret
ENDP clickButton


PROC checkMenuKeyPresses
	USES eax
	LOCAL @@direction:dword
	mov ah, [__keyb_rawScanCode]; get latest scancode
	;http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
	cmp ah, KEY_UP
	je @@UPpressed
	cmp ah, KEY_DOWN
	je @@DOWNpressed
	cmp ah, KEY_LEFT
	je @@LEFTpressed
	cmp ah, KEY_RIGHT
	je @@RIGHTpressed
	cmp ah, KEY_ESC
	je @@ESCpressed
	cmp ah, KEY_A
	je @@Apressed
	cmp ah, KEY_B
	je @@Bpressed
	ret

	@@UPpressed:
	mov [@@direction], UP
	jmp @@ArrowKeyPressed
	@@DOWNpressed:
	mov [@@direction], DOWN
	jmp @@ArrowKeyPressed
	@@RIGHTpressed:
	mov [@@direction], RIGHT
	jmp @@ArrowKeyPressed
	@@LEFTpressed:
	mov [@@direction], LEFT
	jmp @@ArrowKeyPressed
	@@ESCpressed:
	not [ProgramLoop]
	jmp @@NoKeyPressed
	@@Apressed:
	call clickButton, A
	jmp @@NoKeyPressed
	@@Bpressed:
	call clickButton, B
	jmp @@NoKeyPressed
	@@ArrowKeyPressed:
	call movSelectionCursor, [@@direction]
	@@NoKeyPressed:
	mov [__keyb_rawScanCode], 0; clear last pressed state
	ret
ENDP checkMenuKeyPresses


PROC drawEverythingMenu
	;; to draw menu we want to draw menu-drawing, which will be a field
	push [FIELD]
	mov [FIELD], MENU_FIELD
	call drawField
	pop [FIELD]
	;; restore original field
	call display_logo
	call display_UI
	call draw_equipables
	call display_map, offset MINIMAP, -1
	call draw_inventory
	call draw_lives
	cmp [MenuButtons], TRUE
	jne @@InvSelected
	call display_BUTTON_selected, [MenuBttn]
	jmp @@copyVMADR
	@@InvSelected:
	call display_item_selected, [MenuInvX], [MenuInvY]
	@@copyVMADR:
	call copyVMADR
	ret
ENDP drawEverythingMenu


PROC programLoop
  @@programLoop:
	;@@inGame
	cmp [ProgramLoop], IN_GAME
	jne @@inMenu
	call checkKeyPresses   ;-> process user key-press
	call updateField       ;-> update environment
	call checkPlayerStatus ;-> check if player is still alive
	;; graphically
	call awaitVBIStart     ;-> waits for VBI
	call drawEverything    ;-> refreshes
	;; repeat
	jmp @@programLoop
	@@inMenu:
	call checkMenuKeyPresses   ;-> process user key-press
	;; graphically
	call awaitVBIStart     ;-> waits for VBI
	call drawEverythingMenu    ;-> refreshes
	;; repeat
	jmp @@programLoop

	ret
ENDP programLoop


DATASEG
TurnedOneIntoDraugr DD FALSE
CODESEG
PROC turnHalfMobsIntoDraugr; Uses global variable 'TurnedOneIntoDraugr' to turn half the mobs in the world to a draughr
	ARG @@mob:dword
	cmp [TurnedOneIntoDraugr], TRUE
	je @@dontTurnThisOne
	mov [TurnedOneIntoDraugr], TRUE
	call giveDataNewVal, [@@mob], TYPE_DRAUGHR, SHIFT_ENT_TYPE, BITS_ENT_TYPE
	ret
	@@dontTurnThisOne:
	mov [TurnedOneIntoDraugr], FALSE
	mov eax, [@@mob]
	ret
ENDP turnHalfMobsIntoDraugr


PROC startGame
	;; initialisation
	call moveCurrFieldMobs, [FIELD]
	call mapMem, offset worldMobs, FIELDS_IN_WORLD*MAX_AMOUNT_OF_MOBS_PER_FIELD, offset turnHalfMobsIntoDraugr
	;call giveDrovahPosition, DOVAH_START_X, DOVAH_START_Y
	;call set_world, START_WORLD_POSITION
	;call giveDovahHealth, 3
	;...

	; start programLoop
	call makeMap
	call programLoop
	ret
ENDP startGame


PROC main
	sti
	cld

	push ds
	pop	es


	;set-up video-mode, keyboard-handler, random number generator, ...
	call rand_init
	call	setVideoMode,13h
	call __keyb_installKeyboardHandler

	; start game
  call startGame

	call __keyb_uninstallKeyboardHandler
	ret
ENDP main


;### THE FOLLOWING CODE IS BORROWED FROM THE ASSISTANTS AT THE VUB
; Installs the custom keyboard handler
PROC __keyb_installKeyboardHandler
    push	ebp
    mov		ebp, esp

	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	ds
	push	es

	; clear state buffer and the two state bytes
	cld
	mov		ecx, (128 / 2) + 1
	mov		edi, offset __keyb_keyboardState
	xor		eax, eax
	rep		stosw

	; store current handler
	push	es
	mov		eax, 3509h			; get current interrupt handler 09h
	int		21h					; in ES:EBX
	mov		[originalKeyboardHandlerS], es	; store SELECTOR
	mov		[originalKeyboardHandlerO], ebx	; store OFFSET
	pop		es

	; set new handler
	push	ds
	mov		ax, cs
	mov		ds, ax
	mov		edx, offset keyboardHandler			; new OFFSET
	mov		eax, 2509h							; set custom interrupt handler 09h
	int		21h									; uses DS:EDX
	pop		ds

	pop		es
	pop		ds
	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax

    mov		esp, ebp
    pop		ebp
    ret
ENDP __keyb_installKeyboardHandler

; Restores the original keyboard handler
PROC __keyb_uninstallKeyboardHandler
    push	ebp
    mov		ebp, esp

	push	eax
	push	edx
	push	ds

	mov		edx, [originalKeyboardHandlerO]		; retrieve OFFSET
	mov		ds, [originalKeyboardHandlerS]		; retrieve SELECTOR
	mov		eax, 2509h							; set original interrupt handler 09h
	int		21h									; uses DS:EDX

	pop		ds
	pop		edx
	pop		eax

    mov		esp, ebp
    pop		ebp
    ret
ENDP __keyb_uninstallKeyboardHandler

; Keyboard handler (Interrupt function, DO NOT CALL MANUALLY!)
PROC keyboardHandler
	KEY_BUFFER	EQU 60h			; the port of the keyboard buffer
	KEY_CONTROL	EQU 61h			; the port of the keyboard controller
	PIC_PORT	EQU 20h			; the port of the peripheral

	push	eax
	push	ebx
	push	esi
	push	ds

	; setup DS for access to data variables
	mov		ax, _DATA
	mov		ds, ax

	; handle the keyboard input
	sti							; re-enable CPU interrupts
	in		al, KEY_BUFFER		; get the key that was pressed from the keyboard
	mov		bl, al				; store scan code for later use
	mov		[__keyb_rawScanCode], al	; store the key in global variable
	in		al, KEY_CONTROL		; set the control register to reflect key was read
	or		al, 82h				; set the proper bits to reset the keyboard flip flop
	out		KEY_CONTROL, al		; send the new data back to the control register
	and		al, 7fh				; mask off high bit
	out		KEY_CONTROL, al		; complete the reset
	mov		al, 20h				; reset command
	out		PIC_PORT, al		; tell PIC to re-enable interrupts

	; process the retrieved scan code and update __keyboardState and __keysActive
	; scan codes of 128 or larger are key release codes
	mov		al, bl				; put scan code in al
	shl		ax, 1				; bit 7 is now bit 0 in ah
	not		ah
	and		ah, 1				; ah now contains 0 if key released, and 1 if key pressed
	shr		al, 1				; al now contains the actual scan code ([0;127])
	xor		ebx, ebx
	mov		bl, al				; bl now contains the actual scan code ([0;127])
	lea		esi, [__keyb_keyboardState + ebx]	; load address of key relative to __keyboardState in ebx
	mov		al, [esi]			; load the keyboard state of the scan code in al
	; al = tracked state (0 or 1) of pressed key (the value in memory)
	; ah = physical state (0 or 1) of pressed key
	neg		al
	add		al, ah				; al contains -1, 0 or +1 (-1 on key release, 0 on no change and +1 on key press)
	add		[__keyb_keysActive], al	; update __keysActive counter
	mov		al, ah
	mov		[esi], al			; update tracked state

	pop		ds
	pop		esi
	pop		ebx
	pop		eax

	iretd
ENDP keyboardHandler

;-----------------------------------------------------------
; DATA
;-----------------------------------------------------------
DATASEG

  originalKeyboardHandlerS	dw ?			; SELECTOR of original keyboard handler
  originalKeyboardHandlerO	dd ?			; OFFSET of original keyboard handler

__keyb_keyboardState		db 128 dup(?)	; state for all 128 keys
__keyb_rawScanCode			db ?			; scan code of last pressed key
__keyb_keysActive			db ?			; number of actively pressed keys

; -------------------------------------------------------------------
UDATASEG
	palette		db 768 dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
