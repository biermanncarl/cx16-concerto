; This file contains the mouse controller unit/routines.
; It interprets the data coming from the mouse and calls subroutines
; of the GUI, like left click, drag, or reset routines

; Mouse controls are:
; Left click behaves as expected. Can also be used for dragging controls
; Right klick is only used for fine tuning certain parameters by dragging,
; While dragging/clicking, the parameter can be reset by also pressing
; the other mouse button. Depending on whether left or right button was
; pressed first, either the entire parameter or just the fine part gets reset.


; Because mouse buttons can be combined, interpretation of mouse button events
; is non-trivial. Which button-press-history leads to which events?
; The following scheme answers this question

; On program start, and always when no mouse button is pressed, the mouse is
; in the so-called "idle" state.
; When the left or right button is pressed, the mouse will be set into 
; "hold_L" or "hold_R", respectively.
; In these states, the mouse will wait for either all mouse buttons to be released
; or for the other button to be pressed.
; If the other button is pressed while still holding down, the state of the mouse
; is changed.

.scope mouse

; status definitions
ms_idle = 0
ms_hold_L = 1
ms_hold_R = 2
ms_armed_reset = 3
ms_armed_fine_reset = 4

; mouse variables
status: .byte 0
; reference values
ref_x: .word 0
ref_y: .word 0
ref_buttons: .byte 0
ref_panel: .byte 0
ref_component: .byte 0
; current values
curr_x: .word 0
curr_y: .word 0
curr_buttons: .byte 0
curr_panel: .byte 0
curr_component: .byte 0

; get mouse running
mouse_init:
   ; initialize variables
   stz status
   ; KERNAL call
   lda #1
   ldx #1
   jsr MOUSE_CONFIG
   rts



; this is called in the main loop
; and handles all mouse input. It interprets the mouse data and turns it into messages
; that are sent to the GUI components (or rather, decides which GUI subroutines are called).
mouse_tick:
   ; get mouse data
   mouse_data = mzpwa
   ldx #mouse_data
   jsr MOUSE_GET
   sta curr_buttons
   lda mouse_data
   sta curr_x
   lda mouse_data+1
   sta curr_x+1
   lda mouse_data+2
   sta curr_y
   lda mouse_data+3
   sta curr_y+1
   ; call status subroutine
   ; the mouse handles incoming data differently, depending upon which status it is currently in
   lda status
   asl
   tax
   jmp (@jmp_table, x)
@jmp_table:
   .word do_idle
   .word do_hold_L
   .word do_hold_R
   .word do_armed_reset
   .word do_armed_fine_reset
end_mouse_tick:
   rts

; no buttons are pressed. waiting for button presses.
do_idle:
   ; check button presses
   ; check left
   lda curr_buttons
   and #1
   beq :+
   ; left button held down
   lda #ms_hold_L
   sta status
   jmp end_mouse_tick
:  ; check right
   lda curr_buttons
   and #2
   beq :+
   ; left button held down
   lda #ms_hold_R
   sta status
:  jmp end_mouse_tick

; left button is held down. (And center button hasn't been down)
do_hold_L:
   ; check for any buttons pressed
   lda curr_buttons
   bne :+
   ; no buttons pressed anymore --> left click
   lda #ms_idle
   sta status
   nop ; TODO
   jmp end_mouse_tick
:  ; a button is pressed. check right one first
   and #2
   beq :+
   ; right one is pressed. arm for reset
   lda #ms_armed_reset
   sta status
   jmp end_mouse_tick
:  ; check left button
   lda curr_buttons
   and #1
   beq :+
   ; left one is still being pressed. do dragging
   nop ; TODO
:  jmp end_mouse_tick

; right button is held down. (And center button hasn't been down)
do_hold_R:
   ; check for any buttons pressed
   lda curr_buttons
   bne :+
   ; no buttons pressed anymore --> right click (unused)
   lda #ms_idle
   sta status
   jmp end_mouse_tick
:  ; a button is pressed. check left one first
   and #1
   beq :+
   ; left one is pressed. arm for fine reset
   lda #ms_armed_fine_reset
   sta status
   jmp end_mouse_tick
:  ; check right button
   lda curr_buttons
   and #2
   beq :+
   ; right one is still being pressed. do fine dragging
   nop ; TODO
:  jmp end_mouse_tick

; waiting for buttons to be released to reset a parameter
do_armed_reset:
   ; check for any buttons pressed
   lda curr_buttons
   bne :+
   ; no buttons pressed --> do reset
   lda #ms_idle
   sta status
   nop ; TODO
:  jmp end_mouse_tick

; waiting for buttons to be released to reset the "fine" part of a parameter
do_armed_fine_reset:
   ; check for any buttons pressed
   lda curr_buttons
   bne :+
   ; no buttons pressed --> do fine reset
   lda #ms_idle
   sta status
   nop ; TODO
:  jmp end_mouse_tick

.endscope