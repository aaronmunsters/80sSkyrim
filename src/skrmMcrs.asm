; SOME MACRO DEFINITIONS WHICH MAKE THE CODE MORE READABLE

;-----BOOLEANS-----
TRUE  = 1
FALSE = 0

;-----KEY-SCAN-CODES----
KEY_A     EQU 1eh
KEY_B     EQU 30h
KEY_UP    EQU 48h
KEY_DOWN  EQU 50h
KEY_LEFT  EQU 4bh
KEY_RIGHT EQU 4dh
KEY_ESC   EQU 01h

;----PROGRAM-LOOP------
IN_GAME EQU 00000000b
IN_MENU EQU 11111111b

;-----FIELD-MATRIX-----
FIELDWIDTH  EQU 16
FIELDHEIGHT EQU 8

LEFTMOST_X_VAL  EQU 0
RIGHTMOST_X_VAL EQU FIELDWIDTH - 1
HIGHEST_Y_VAL   EQU 0
LOWEST_Y_VAL    EQU FIELDHEIGHT - 1

;-----CELL-PROPERTIES-----
; for every cell 4 bits determine it's floor and 4 a prop on top
; LMS bit determines if it is walkable -> 16 floor types and 15 props
WALKABLE EQU 1

;-----GAME-LOGIC-----
; 4 possible directions:
UP    EQU 00b;
RIGHT EQU 01b;| adding 2 to a direction == opposite direction
DOWN  EQU 10b;| (if the third least significant bit is discarded)
LEFT  EQU 11b;

; 2 input possibilities:
A EQU 0
B EQU 1

; 4 possible combinations that define damage
NO_WEAP EQU 00b
MELEE   EQU 01b
RANGE   EQU 10b
MAGE    EQU 11b

; all possible items:
EMPTY		EQU 0000b
SHIELD	EQU 0001b
DAGGER	EQU 0010b
BOW			EQU 0011b
STAFF		EQU 0100b
HELMET	EQU 0101b
CHEST		EQU 0110b
ARROW		EQU 0111b
FIRE		EQU 1000b
KEY			EQU 1001b
POTION	EQU 1010b
DUCK		EQU 1011b

; 4 possible health-values (ranging from 0 to 3)
DEAD EQU 0
; the other are just numbers

; possible damage-values
DAGGER_DAMAGE EQU 1

; entities can be active or inactive, this determines wether the entity will be drawn
INACTIVE EQU 0
ACTIVE   EQU 1

;-----ENTITY-PROPERTIES-----
; Armour/Helmet:
NOT_WEARING EQU 0
NO_ARMOUR   EQU 0
NO_HELMET   EQU 0
NO_SHIELD   EQU 0

WEARING        EQU 1
WEARING_ARMOUR EQU 1
WEARING_HELMET EQU 1
WEARING_SHIELD EQU 1

;AI-properties (only relevant for hostile entities)
AGGRESSIVE    EQU 1
NONAGGRESSIVE EQU 0

STARTING      EQU 0
ROTATING      EQU 1
START_WALKING EQU 2
WALKING       EQU 3

IN_FRONT_OF     EQU 0
ATTACKING       EQU 1
BACKED_UP       EQU 2
WAITING_FOR_ATT EQU 3

;Entity types
TYPE_HUMAN    EQU 0
TYPE_SKELETON EQU 1
TYPE_DRAUGHR  EQU 2
TYPE_DRAGON   EQU 3

MAX_AMOUNT_OF_MOBS_PER_FIELD EQU 6

; how far hostile entities can spot another entity
MOBS_SIGHT = 3

;-----BIT-PROCEDURE-LOGIC-----
; The shift- and bits-values are used by a generic 'getDataVal' and 'giveDataNewVal' function
; this requires the value-size and shifts to correctly return the requested information

; entitie-properties:
SHIFT_ACTIVE    EQU 0
SHIFT_Y_POS     EQU 1
SHIFT_X_POS     EQU 4
SHIFT_DIRECTION EQU 8
SHIFT_LIFE      EQU 10
SHIFT_HELMET    EQU 12
SHIFT_ARMOUR    EQU 13
SHIFT_SHIELD    EQU 14
SHIFT_WEAPON    EQU 15

SHIFT_ENT_TYPE  EQU 17
SHIFT_AI_MODE   EQU 19
SHIFT_AI_STATE  EQU 20

BITS_ACTIVE     EQU 1 ;
BITS_Y_POS      EQU 3 ;
BITS_X_POS      EQU 4 ;
BITS_DIRECTION  EQU 2 ; --> total of 16 bits
BITS_LIFE       EQU 2 ;
BITS_HELMET     EQU 1 ;
BITS_ARMOUR     EQU 1 ;
BITS_SHIELD     EQU 1 ;
BITS_WEAPON     EQU 2 ;

BITS_ENT_TYPE   EQU 2
BITS_AI_MODE    EQU 1
BITS_AI_STATE   EQU 2


; cell-properties:
SHIFT_WALKABILITY EQU 0
SHIFT_TERRAIN     EQU 0
SHIFT_ITEM        EQU 4
SHIFT_WORLD_Y     EQU 0
SHIFT_WORLD_X     EQU 2

BITS_WALKABILITY EQU 1
BITS_ITEM        EQU 4
BITS_TERRAIN     EQU 4
BITS_WORLD_X     EQU 2
BITS_WORLD_Y     EQU 2


;-----WORLD-MATRIX-----
WORLDWIDTH  EQU 4
WORLDHEIGHT EQU 4

FIELDS_IN_WORLD EQU WORLDWIDTH * WORLDHEIGHT

LEFTMOST_WORLD_X_VAL  EQU 0
RIGHTMOST_WORLD_X_VAL EQU WORLDWIDTH - 1
HIGHEST_WORLD_Y_VAL   EQU 0
LOWEST_WORLD_Y_VAL    EQU WORLDHEIGHT - 1

;-----MENU-----
MENU_FIELD EQU 16

START EQU 0
EXIT EQU 1

MOBS_NON_SUSPICIOUS_GAME_TICK EQU 20; Amount of VBI-refreshes before one game-tick passes
MOBS_SUSPICIOUS_GAME_TICK     EQU  5; Amount of VBI-refreshes before one game-tick passes

RAND_A = 1103515245	;used by rand-call
RAND_C = 12345

;-----INVENTORY-----
INVENTORY_HEIGHT = 3
INVENTORY_WIDTH  = 8

INVENTORY_LOWEST_Y_VAL    EQU INVENTORY_HEIGHT - 1
INVENTORY_HIGHEST_Y_VAL   EQU 0
INVENTORY_LEFTMOST_X_VAL  EQU 0
INVENTORY_RIGHTMOST_X_VAL EQU INVENTORY_WIDTH - 1

INVENTORY_SIZE   = INVENTORY_HEIGHT * INVENTORY_WIDTH
; -------------------------------------------------------------------
