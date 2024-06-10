; Copyright 2021 Carl Georg Biermann


; This file contains the mouse controller unit/routines.
; It interprets the data coming from the mouse and calls subroutines
; of the GUI, like left click, drag, or reset routines

; Mouse controls are:
; Left click behaves as expected. Can also be used for dragging controls
; Right klick is only used for fine tuning certain parameters by dragging.

; The mouse is a finite-state machine.
; On program start, and always when no mouse button is pressed, the mouse is
; in the so-called "idle" state.
; When the left or right button is pressed, the mouse will be set into 
; "hold_L" or "hold_R", respectively.
; In these states, the mouse will wait for all mouse buttons to be released.

.include "mouse_variables.asm"

.scope mouse

; get mouse running
mouse_init:
   ; initialize variables
   stz mouse_variables::status
   ; KERNAL call
   lda #1
   ldx #80
   ldy #60
   jsr MOUSE_CONFIG
   rts

mouse_hide:
   lda #0
   ldx #0
   jsr MOUSE_CONFIG
   rts

; this is called in the main loop
; and handles all mouse input. It interprets the mouse data and turns it into messages
; that are sent to the GUI components (or rather, decides which GUI subroutines are called).
mouse_tick:
   ; move previous position to ref (only if status is not 0)
   lda mouse_variables::status
   beq :+
   lda mouse_variables::curr_x
   sta mouse_variables::prev_x
   lda mouse_variables::curr_x+1
   lda mouse_variables::prev_x+1
   lda mouse_variables::curr_y
   sta mouse_variables::prev_y
   lda mouse_variables::curr_y+1
   lda mouse_variables::prev_y+1
:  ; get mouse data
   mouse_data = gui_variables::mzpwa
   ldx #mouse_data
   jsr MOUSE_GET
   sta mouse_variables::curr_buttons
   lda mouse_data
   sta mouse_variables::curr_x
   lda mouse_data+1
   sta mouse_variables::curr_x+1
   lda mouse_data+2
   sta mouse_variables::curr_y
   lda mouse_data+3
   sta mouse_variables::curr_y+1
   ; update downsampled mouse coordinates
   temp = gui_variables::mzpwa
   ; determine mouse position in multiples of 4 pixels (divide by 4)
   lda mouse_variables::curr_x+1
   lsr
   sta temp
   lda mouse_variables::curr_x
   ror
   sta mouse_variables::curr_x_downscaled
   lda temp
   lsr
   ror mouse_variables::curr_x_downscaled
   ; (high byte is uninteresting, thus not storing it back)
   lda mouse_variables::curr_y+1
   lsr
   lda mouse_variables::curr_y
   ror
   lsr
   sta mouse_variables::curr_y_downscaled
   ; call status subroutine
   ; the mouse handles incoming data differently, depending upon which status it is currently in
   lda mouse_variables::status
   asl
   tax
   jmp (@jmp_table, x)
@jmp_table:
   .word do_idle
   .word do_hold_L
   .word do_hold_other
end_mouse_tick:
   jsr gui_routines::handle_component_requests
   rts

; no buttons are pressed. waiting for button presses.
do_idle:
   lda #1
   sta mouse_variables::drag_start ; in case there is a drag event, this variable is set to 1 for the first call of drag event
   ; check button presses
   ; check left
   lda mouse_variables::curr_buttons
   and #1
   beq :+
   ; left button held down
   lda #mouse_variables::ms_hold_L
   sta mouse_variables::status
   jmp @mouse_down_checks
:  ; check other buttons
   lda mouse_variables::curr_buttons
   beq :+
   ; right button held down
   lda #mouse_variables::ms_hold_other
   sta mouse_variables::status
   bra @mouse_down_checks
:  bra end_mouse_tick
@mouse_down_checks:
   jsr panels::mouse_get_panel
   lda mouse_variables::curr_panel
   bmi :+
   jsr panels::mouse_get_component
   lda mouse_variables::curr_component_id
   sta mouse_variables::prev_component_id
   lda mouse_variables::curr_component_ofs
   sta mouse_variables::prev_component_ofs
   lda mouse_variables::curr_panel
   sta mouse_variables::prev_panel ; now move it into "ref" to compare it when mouse button is released (to see if still the same component is being clicked)
                    ; and for dragging stuff
   bra end_mouse_tick
:  lda #255
   sta mouse_variables::prev_panel
   bra end_mouse_tick

; left button is held down. (and no other button has been pressed)
do_hold_L:
   ; check for any buttons pressed
   lda mouse_variables::curr_buttons
   bne @button_pressed
   ; no buttons pressed anymore --> left click
   ; reset mouse status
   lda #mouse_variables::ms_idle
   sta mouse_variables::status
   ; and do click operation:
   ; check if previous panel & component are the same. If yes, issue a click event.
   jsr panels::mouse_get_panel
   lda mouse_variables::curr_panel
   bpl :+
   bra end_mouse_tick ; no panel clicked.
:  ; a panel has been clicked.
   ; still the same as on mouse-down?
   cmp mouse_variables::prev_panel
   beq :+
   bra end_mouse_tick ; not the same, but a different one
:  ; yes, the same. check if also the same component
   jsr panels::mouse_get_component
   lda mouse_variables::curr_component_id
   bpl :+
   bra end_mouse_tick ; no component being clicked
:  ; yes, a component being clicked.
   ; still the same as on mouse-down?
   cmp mouse_variables::prev_component_id
   beq :+
   bra end_mouse_tick ; not the same, but a different one
:  ; yes, the same component as when the mouse button was pressed down.
   ; NOW, issue a click event.
   jsr gui_routines::click_event
   bra end_mouse_tick
@button_pressed:  ; a button is pressed.  do dragging
   bra do_dragging
   jmp end_mouse_tick ; unreachable code ... optimize away?

; right button is held down. (and no other button has been pressed)
do_hold_other:
   ; check for any buttons pressed
   lda mouse_variables::curr_buttons
   bne :+
   ; no buttons pressed anymore --> right click (unused)
   lda #mouse_variables::ms_idle
   sta mouse_variables::status
   jmp end_mouse_tick
:  ; a button is still being pressed. do fine dragging
   bra do_dragging
   jmp end_mouse_tick

do_dragging:
   ; check if there is actually a component being dragged
   lda mouse_variables::prev_panel
   bmi :+
   sta mouse_variables::curr_panel
   lda mouse_variables::prev_component_id
   bmi :+
   sta mouse_variables::curr_component_id
   lda mouse_variables::prev_component_ofs
   sta mouse_variables::curr_component_ofs
   ; get distance to last frame
   ; we assume it's smaller than 127, so we ignore the high byte xD
   lda mouse_variables::curr_x
   sec
   sbc mouse_variables::prev_x
   sta mouse_variables::delta_x
   ; for vertical delta we intentionally swap prev and curr because for most applications it's more convenient to let "up" have positive sign
   lda mouse_variables::prev_y
   sec
   sbc mouse_variables::curr_y
   sta mouse_variables::delta_y
   jsr gui_routines::drag_event
   stz mouse_variables::drag_start
:  jmp end_mouse_tick

.endscope
