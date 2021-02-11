; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************


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

; The mouse is a finite-state machine.
; On program start, and always when no mouse button is pressed, the mouse is
; in the so-called "idle" state.
; When the left or right button is pressed, the mouse will be set into 
; "hold_L" or "hold_R", respectively.
; In these states, the mouse will wait for either all mouse buttons to be released
; or for the other button to be pressed.
; If the other button is pressed while still holding down, the state of the mouse
; is changed to one of the "reset" states, which wait for all buttons to be released.
; NOTE: the reset function has not been implemented on the GUI yet.
; The GUI currently only reacts to click and drag events.

.scope mouse

; status definitions
ms_idle = 0
ms_hold_L = 1
ms_hold_R = 2


; get mouse running
mouse_init:
   ; initialize variables
   stz ms_status
   ; KERNAL call
   lda #1
   ldx #1
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
   lda ms_curr_x
   sta ms_ref_x
   lda ms_curr_x+1
   lda ms_ref_x+1
   lda ms_curr_y
   sta ms_ref_y
   lda ms_curr_y+1
   lda ms_ref_y+1
:  ; get mouse data
   mouse_data = mzpwa
   ldx #mouse_data
   jsr MOUSE_GET
   sta ms_curr_buttons
   lda mouse_data
   sta ms_curr_x
   lda mouse_data+1
   sta ms_curr_x+1
   lda mouse_data+2
   sta ms_curr_y
   lda mouse_data+3
   sta ms_curr_y+1
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
   rts

; no buttons are pressed. waiting for button presses.
do_idle:
   ; check button presses
   ; check left
   lda ms_curr_buttons
   and #1
   beq :+
   ; left button held down
   lda #ms_hold_L
   sta ms_status
   jmp @mouse_down_checks
:  ; check right
   lda ms_curr_buttons
   and #2
   beq :+
   ; right button held down
   lda #ms_hold_R
   sta ms_status
   jmp @mouse_down_checks
:  jmp end_mouse_tick
@mouse_down_checks:
   jsr gui::mouse_get_panel
   lda ms_curr_panel
   bmi :+
   jsr gui::mouse_get_component
   lda ms_curr_component_id
   sta ms_ref_component_id
   lda ms_curr_component_ofs
   sta ms_ref_component_ofs
   lda ms_curr_panel
   sta ms_ref_panel ; now move it into "ref" to compare it when mouse button is released (to see if still the same component is being clicked)
                    ; and for dragging stuff
   jmp end_mouse_tick
:  lda #255
   sta ms_ref_panel
   jmp end_mouse_tick

; left button is held down. (and no other button has been pressed)
do_hold_L:
   ; check for any buttons pressed
   lda ms_curr_buttons
   bne @button_pressed
   ; no buttons pressed anymore --> left click
   ; reset mouse status
   lda #ms_idle
   sta ms_status
   ; and do click operation:
   ; check if previous panel & component are the same. If yes, issue a click event.
   jsr gui::mouse_get_panel
   lda ms_curr_panel
   bpl :+
   jmp end_mouse_tick ; no panel clicked.
:  ; a panel has been clicked.
   ; still the same as on mouse-down?
   cmp ms_ref_panel
   beq :+
   jmp end_mouse_tick ; not the same, but a different one
:  ; yes, the same. check if also the same component
   jsr gui::mouse_get_component
   lda ms_curr_component_id
   bpl :+
   jmp end_mouse_tick ; no component being clicked
:  ; yes, a component being clicked.
   ; still the same as on mouse-down?
   cmp ms_ref_component_id
   beq :+
   jmp end_mouse_tick ; not the same, but a different one
:  ; yes, the same component as when the mouse button was pressed down.
   ; NOW, issue a click event.
   jsr gui::click_event
   jmp end_mouse_tick
@button_pressed:  ; a button is pressed.  do dragging
   ; left mouse button dragging = 0 in ms_curr_data
   lda #0
   sta ms_curr_data
   jmp do_dragging
   jmp end_mouse_tick

; right button is held down. (and no other button has been pressed)
do_hold_R:
   ; check for any buttons pressed
   lda ms_curr_buttons
   bne :+
   ; no buttons pressed anymore --> right click (unused)
   lda #ms_idle
   sta ms_status
   jmp end_mouse_tick
:  ; a button is still being pressed. do fine dragging
   ; right mouse button dragging = 1 in ms_curr_data
   lda #1
   sta ms_curr_data
   jmp do_dragging
   jmp end_mouse_tick

do_dragging:
   ; check if there is actually a component being dragged
   lda ms_ref_panel
   bmi :+
   sta ms_curr_panel
   lda ms_ref_component_id
   bmi :+
   sta ms_curr_component_id
   lda ms_ref_component_ofs
   sta ms_curr_component_ofs
   ; get Y difference to last frame
   ; we assume it's smaller than 127, so we ignore the high byte xD
   lda ms_ref_y
   sec
   sbc ms_curr_y
   sta ms_curr_data2
   jsr gui::drag_event
:  jmp end_mouse_tick

.endscope
