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

.include "mouse_definitions.asm"

.scope mouse

; status definitions
ms_idle = 0
ms_hold_L = 1
ms_hold_R = 2

; "private" mouse variables
ms_status: .byte 0

; get mouse running
mouse_init:
   ; initialize variables
   stz ms_status
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
   lda ms_status
   beq :+
   lda mouse_definitions::curr_x
   sta mouse_definitions::prev_x
   lda mouse_definitions::curr_x+1
   lda mouse_definitions::prev_x+1
   lda mouse_definitions::curr_y
   sta mouse_definitions::prev_y
   lda mouse_definitions::curr_y+1
   lda mouse_definitions::prev_y+1
:  ; get mouse data
   mouse_data = mzpwa
   ldx #mouse_data
   jsr MOUSE_GET
   sta mouse_definitions::curr_buttons
   lda mouse_data
   sta mouse_definitions::curr_x
   lda mouse_data+1
   sta mouse_definitions::curr_x+1
   lda mouse_data+2
   sta mouse_definitions::curr_y
   lda mouse_data+3
   sta mouse_definitions::curr_y+1
   ; call status subroutine
   ; the mouse handles incoming data differently, depending upon which status it is currently in
   lda ms_status
   asl
   tax
   jmp (@jmp_table, x)
@jmp_table:
   .word do_idle
   .word do_hold_L
   .word do_hold_R
end_mouse_tick:
   jsr gui::handle_component_requests
   rts

; no buttons are pressed. waiting for button presses.
do_idle:
   ; check button presses
   ; check left
   lda mouse_definitions::curr_buttons
   and #1
   beq :+
   ; left button held down
   lda #ms_hold_L
   sta ms_status
   jmp @mouse_down_checks
:  ; check right
   lda mouse_definitions::curr_buttons
   and #2
   beq :+
   ; right button held down
   lda #ms_hold_R
   sta ms_status
   jmp @mouse_down_checks
:  jmp end_mouse_tick
@mouse_down_checks:
   jsr gui::panels::mouse_get_panel
   lda mouse_definitions::curr_panel
   bmi :+
   jsr gui::mouse_get_component
   lda mouse_definitions::curr_component_id
   sta mouse_definitions::prev_component_id
   lda mouse_definitions::curr_component_ofs
   sta mouse_definitions::prev_component_ofs
   lda mouse_definitions::curr_panel
   sta mouse_definitions::prev_panel ; now move it into "ref" to compare it when mouse button is released (to see if still the same component is being clicked)
                    ; and for dragging stuff
   jmp end_mouse_tick
:  lda #255
   sta mouse_definitions::prev_panel
   jmp end_mouse_tick

; left button is held down. (and no other button has been pressed)
do_hold_L:
   ; check for any buttons pressed
   lda mouse_definitions::curr_buttons
   bne @button_pressed
   ; no buttons pressed anymore --> left click
   ; reset mouse status
   lda #ms_idle
   sta ms_status
   ; and do click operation:
   ; check if previous panel & component are the same. If yes, issue a click event.
   jsr gui::panels::mouse_get_panel
   lda mouse_definitions::curr_panel
   bpl :+
   jmp end_mouse_tick ; no panel clicked.
:  ; a panel has been clicked.
   ; still the same as on mouse-down?
   cmp mouse_definitions::prev_panel
   beq :+
   jmp end_mouse_tick ; not the same, but a different one
:  ; yes, the same. check if also the same component
   jsr gui::mouse_get_component
   lda mouse_definitions::curr_component_id
   bpl :+
   jmp end_mouse_tick ; no component being clicked
:  ; yes, a component being clicked.
   ; still the same as on mouse-down?
   cmp mouse_definitions::prev_component_id
   beq :+
   jmp end_mouse_tick ; not the same, but a different one
:  ; yes, the same component as when the mouse button was pressed down.
   ; NOW, issue a click event.
   jsr gui::click_event
   jmp end_mouse_tick
@button_pressed:  ; a button is pressed.  do dragging
   ; left mouse button dragging = 0 in mouse_definitions::curr_data_1
   lda #0
   sta mouse_definitions::curr_data_1
   jmp do_dragging
   jmp end_mouse_tick

; right button is held down. (and no other button has been pressed)
do_hold_R:
   ; check for any buttons pressed
   lda mouse_definitions::curr_buttons
   bne :+
   ; no buttons pressed anymore --> right click (unused)
   lda #ms_idle
   sta ms_status
   jmp end_mouse_tick
:  ; a button is still being pressed. do fine dragging
   ; right mouse button dragging = 1 in mouse_definitions::curr_data_1
   lda #1
   sta mouse_definitions::curr_data_1
   jmp do_dragging
   jmp end_mouse_tick

do_dragging:
   ; check if there is actually a component being dragged
   lda mouse_definitions::prev_panel
   bmi :+
   sta mouse_definitions::curr_panel
   lda mouse_definitions::prev_component_id
   bmi :+
   sta mouse_definitions::curr_component_id
   lda mouse_definitions::prev_component_ofs
   sta mouse_definitions::curr_component_ofs
   ; get Y difference to last frame
   ; we assume it's smaller than 127, so we ignore the high byte xD
   lda mouse_definitions::prev_y
   sec
   sbc mouse_definitions::curr_y
   sta mouse_definitions::curr_data_2
   jsr gui::drag_event
:  jmp end_mouse_tick

.endscope
