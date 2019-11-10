
;gets a cell, an x_value and a y value and prints the cell in the right place
GLOBAL display_terrain:PROC
GLOBAL display_item:PROC

;procedures that draw a prop(an entity)
GLOBAL display_prop:PROC           ;X,Y,direction
GLOBAL display_dovah:PROC          ;X,Y,direction
GLOBAL display_skeleton:PROC       ;X,Y,direction
GLOBAL display_draughr:PROC        ;X,Y,direction
GLOBAL display_helmet:PROC         ;X,Y,direction
GLOBAL display_armor:PROC          ;X,Y,direction
GLOBAL display_shield:PROC         ;X,Y,direction
GLOBAL display_sword:PROC          ;X,Y,direction
GLOBAL display_bow:PROC            ;X,Y,direction
GLOBAL display_staff:PROC          ;X,Y,direction

;procedures that draw an item in the right spot
GLOBAL display_inventory_item:PROC      ;item, X(int), Y(int)
GLOBAL display_equipable_item:PROC      ;item, place(0 - 3)

;procedures that draw a special sprite
GLOBAL display_logo:PROC           ; /
GLOBAL display_dragon:PROC         ;X(int), Y(int)

;procedures that draw a red selection around the selected item
GLOBAL display_item_selected:PROC       ;X(int), Y(int)
GLOBAL display_BUTTON_selected:PROC     ;selection(start or stop)

;the procedures that draw the ui
GLOBAL display_UI:PROC        ; /
GLOBAL display_map:PROC       ; map(array), field(int)
GLOBAL display_lives:PROC     ; amount(int)

;gets a color and fills the complete background with this color
GLOBAL fillBackground:PROC    ; color(int)

;copies the Buffermemoryadress to the real memory address
;hase to be called at the end of every draw cyclus
GLOBAL copyVMADR:PROC         ; /

;;sets the video mode to the right mode  (hase to be 13h)
GLOBAL setVideoMode:PROC      ; 13H

;no arguments, terminates the window
GLOBAL terminateProcess:PROC       ; /
