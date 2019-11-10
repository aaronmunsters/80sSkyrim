VMADR	EQU 0A0000h	; video memory address
SCRWIDTH 	EQU 320	; screen witdth
SCRHEIGHT	EQU 200	; screen height

CELLSIZE 	EQU 20
ITEMSIZE 	EQU 8
MOBSIZE 	EQU 18

LOGO_X EQU 149
LOGO_Y EQU 62
;;;------------------- all types of terrain -------------------
;walkable types of terrain
WALL 	EQU 0000b
ROCK 	EQU 0010b
TREE 	EQU 0100b
CHAIR	EQU 0110b
TABL 	EQU 1000b
LEAF 	EQU 1010b
WATER 	EQU 1100b
BUSH 	EQU 1110b

;non walkable types of terrain
GRASS 	EQU 0001b
SNOW 	EQU 0011b
GRAVEL 	EQU 0101b
PATH 	EQU 0111b
SAND 	EQU 1001b
DIRT 	EQU 1011b
WWATER 	EQU 1101b
WBUSH 	EQU 1111b
;;;----------------------------------------------------------

;;;------------------- all types of items -------------------
EMPTY 	EQU 0000b
SHIELD 	EQU 0001b
DAGGER 	EQU 0010b
BOW 		EQU 0011b
STAFF 	EQU 0100b
HELMET 	EQU 0101b
ARMOR 	EQU 0110b
ARROW 	EQU 0111b
FIRE 	EQU 1000b
KEY 		EQU 1001b
POTION 	EQU 1010b
DUCK 	EQU 1011b

;not really items but have to be drawn with the same size

;;;----------------------------------------------------------

;;;------------------- all types of props -------------------
AMOUNTOFPROPS EQU 9

DOVAH EQU 0000b
;; HELMET till staff are already assigned with the items
SKELETON EQU 0111b
DRAUGR EQU 1000b

MAXHEALTH EQU 3
;;;----------------------------------------------------------

;;;---------------------- UI ELEMENTS -----------------------
START_X 		EQU 	9
START_Y 		EQU	170
START_BUTTON	EQU 0

STOP_X		EQU	9
STOP_Y		EQU	180
STOP_BUTTON		EQU 1

SELECTED_BUTTON   EQU 2

LIVES_X		EQU	70
LIVES_Y		EQU	176
LIVES_ALIVE EQU	0
LIVES_DEAD	EQU	1

EQUIPABLES_X	EQU 	119
EQUIPABLES_Y	EQU	169

ITEM_A_X	 	EQU 	122
ITEM_A_Y		EQU	176

ITEM_B_X		EQU 	138
ITEM_B_Y		EQU 	176

HELMET_X	 	EQU 	130
HELMET_Y		EQU	170

PANTS_x	 	EQU 	130
PANTS_Y		EQU	182

INVENTORY_X	EQU 	159
INVENTORY_Y	EQU	167

WORLD_X	 	EQU 	249
WORLD_Y 		EQU	163

WORLDSIZE 		EQU 4
FIELDWIDTH 		EQU 16
FIELDHEIGHT 		EQU 8
INVENTORY_WIDTH 	EQU 8
INVENTORY_HEIGHT	EQU 3
BUTTONAMMOUNT     EQU 2

STARTSELECTION EQU 1
STOPSELECTION EQU 2
FIRSTITEMSELECTION EQU 3
;;;----------------------------------------------------------
