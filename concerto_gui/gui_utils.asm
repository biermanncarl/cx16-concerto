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


; Many utility functions for the GUI are found in this file.
; From more basic stuff like setting the VERA "screen cursor" to a specific location
; to displaying more complex stuff like frames, edits, checkboxes etc.

; These routines are designed to be called from within the main program.
; The VERA is used from within the ISR and from within the main program.
; To avoid any disturbances of VERA writes by the ISR (which uses the VERA, too),
; great care has to be taken to always put an SEI before any VERA actions.


.scope guiutils

; variables used by the DISPLAY_BYTE macro
display_100s:       .byte 0
display_10s:        .byte 0
display_1s:         .byte 0

.macro SET_VERA_XY svx, svy
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_high
   lda svy
   sta VERA_addr_mid
   lda svx
   asl
   sta VERA_addr_low
.endmacro

; displays the byte db_data at position db_x and db_y
; used only for debugging.
.macro DISPLAY_BYTE db_data, db_x, db_y
   .local @loop100s
   .local @loop10s
   .local @loop1s

   ; convert binary into decimal
   lda db_data
   ldx #48
@loop100s:
   inx
   sec
   sbc #100
   bcs @loop100s
   adc #100
   dex
   cpx #48
   bne :+
   ldx #32
:  stx guiutils::display_100s

   ldx #48
@loop10s:
   inx
   sec
   sbc #10
   bcs @loop10s
   adc #10
   dex
   cpx #48
   bne :+
   ldx #32
:  stx guiutils::display_10s

   ldx #48
@loop1s:
   inx
   sec
   sbc #1
   bcs @loop1s
   adc #1
   dex
   stx guiutils::display_1s

   sei
   ; set VERA address
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_high
   lda #db_y
   sta VERA_addr_mid
   lda #db_x
   clc
   asl
   sta VERA_addr_low

   ; do output
   lda guiutils::display_100s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda guiutils::display_10s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda guiutils::display_1s
   sta VERA_data0
   lda #$21    ; set color
   sta VERA_data0
   cli
.endmacro

; displays the 0-terminated message at position db_x and db_y
; used only for debugging.
.macro DISPLAY_LABEL msg_start, dm_x, dm_y
.local @loop_msg
.local @done_msg
   sei
   ; set VERA address
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_high
   lda #dm_y
   sta VERA_addr_mid
   lda #dm_x
   clc
   asl
   sta VERA_addr_low

   ; print message
   lda #<msg_start
   sta mzpwa
   lda #>msg_start
   sta mzpwa+1
   ldy #0
@loop_msg:
   lda (mzpwa),y
   beq @done_msg
   sta VERA_data0
   lda #$61    ; set color
   sta VERA_data0
   iny
   bra @loop_msg
@done_msg:
   cli
.endmacro





; UTILITY ROUTINES
; ----------------

; drawing parameters
; "cursor" position
cur_x: .byte 0
cur_y: .byte 0
; color
color: .byte 0
; string pointer
str_pointer = mzpwe
; draw a component at position and with dimensions:
draw_x: .byte 0
draw_y: .byte 0
; NOTE: draw_x/draw_y are kept separate from cur_x/cur_y, because of the drawing of more complex objects like the frame around a panel.
; However, this is the only place where it is necessary ATM, so it might be possible to get rid of either of them and find a different solution for draw_frame.
draw_width: .byte 0
draw_height: .byte 0
; additional drawing parameters
draw_data1: .byte 0  ; e.g. number of tabs
draw_data2: .byte 0  ; e.g. index of active tab



; set cursor
set_cursor:
   SET_VERA_XY cur_x, cur_y
   rts


; displays the 0-terminated message at position cur_x|cur_y
; message pointer is in str_pointer
; color as in variable color
print:
   sei
   ; set VERA address
   jsr set_cursor

   ; print message
   ldx color
   ldy #0
@loop_msg:
   lda (str_pointer),y
   beq @done_msg
   sta VERA_data0
   stx VERA_data0
   iny
   bra @loop_msg
@done_msg:
   cli
   rts


; prints a byte on screen (position as in VERA's address 0)
; color as in register X
; number as in register A
print_byte_simple:
   ; convert binary into decimal
   ldy #48
@loop100s:
   iny
   sec
   sbc #100
   bcs @loop100s
   adc #100
   dey
   cpy #48
   bne :+
   ldy #32
:  sty display_100s
   ldy #48
@loop10s:
   iny
   sec
   sbc #10
   bcs @loop10s
   adc #10
   dey
   cpy #48
   bne :+
   ; digit is zero. now it depends on 100s digit, whether it's space or 0
   ldy display_100s
   cpy #32
   beq :+
   ldy #48
:  sty display_10s
   ldy #48
@loop1s:
   iny
   sec
   sbc #1
   bcs @loop1s
   adc #1
   dey
   sty display_1s
   ; do output
   lda display_100s
   sta VERA_data0
   stx VERA_data0
   lda display_10s
   sta VERA_data0
   stx VERA_data0
   lda display_1s
   sta VERA_data0
   stx VERA_data0
   rts

; clear screen in my own background color
cls:
   ; set background color in a dirty manner (we did not hear that from Greg King)
   ; https://www.commanderx16.com/forum/index.php?/topic/469-change-background-color-using-vpoke/&do=findComment&comment=3084
   lda #(11*16+1)
   sta $376

   ; actually, I'd like a dark green or something
   ; TODO: set custom palette
   ; do the screen clear
   lda #$93
   jsr CHROUT
   rts



; subroutine that draws a frame (around a panel)
; x, y position in draw_x and draw_y
; width and height in draw_width and draw_height
; data1 is number of tabs (0 if there are no tabs)
; data2 is index of active tab (0 to N-1)
draw_frame:
   lda #(16*COLOR_BACKGROUND + COLOR_FRAME)
   sta color

   ; top of frame
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda #85
   sta VERA_data0
   ldx color
   stx VERA_data0
   ldy draw_width
   dey
   dey
@loop_top:
   lda #64
   sta VERA_data0
   stx VERA_data0
   dey
   bne @loop_top
   lda #73
   sta VERA_data0
   stx VERA_data0
   cli
   ; bottom of frame
   lda cur_y
   clc
   adc draw_height
   dec
   sta cur_y
   ldy draw_width
   dey
   dey
   lda draw_data1 ; if 0 tabs, a simple frame is drawn
   beq :+   ; if 1 or more tabs are present, the bottom side is drawn differently
   lda cur_x
   clc
   adc #2
   sta cur_x
   dey
   dey
:  sei
   jsr set_cursor
   lda #74
   sta VERA_data0
   stx VERA_data0
@loop_bottom:
   lda #64
   sta VERA_data0
   stx VERA_data0
   dey
   bne @loop_bottom
   lda #75
   sta VERA_data0
   stx VERA_data0
   cli
   ; right side of frame
   lda draw_x
   clc
   adc draw_width
   dec
   sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldy draw_height
   dey
   dey
   sei
@loop_right:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   dey
   bne @loop_right
   cli
   ; left side of frame
   lda draw_x
   ldy draw_data1
   beq :+
   clc
   adc #2
:  sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldy draw_height
   dey
   dey
   sei
@loop_left:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   dey
   bne @loop_left
   cli

   ; check for tabs
   ldy draw_data1
   beq :+
   jsr draw_tabs
:  rts


; draw tabs
; x, y position in draw_x and draw_y
; independent routine for updating when another tab is selected
; data1 is number of tabs (0 if there are no tabs)
; data2 is index of active tab (0 to N-1)
draw_tabs:
   ldx #(16*COLOR_BACKGROUND + COLOR_FRAME)
   stx color
   lda draw_x
   clc
   adc #2
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda #114
   sta VERA_data0
   lda color
   sta VERA_data0
   ; draw tabs
   lda draw_x
   sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldy #0
   ldx color
   sei
@loop_tabs:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   tya
   clc
   adc #49
   sta VERA_data0
   lda #(COLOR_BACKGROUND*16+COLOR_TABS)
   sta VERA_data0
   lda #66
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   jsr set_cursor
   lda #107
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #115
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   iny
   cpy draw_data1
   bne @loop_tabs

   dec cur_y
   jsr set_cursor
   lda #74
   sta VERA_data0
   cli

   ; draw active tab
   lda draw_data2
   dec
   asl
   clc
   adc draw_y
   sta cur_y
   lda draw_x
   sta cur_x
   ldx color
   sei
   jsr set_cursor
   lda #85
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #75
   ldy draw_data2
   cpy #1
   bne :+
   lda #64
:  sta VERA_data0
   stx VERA_data0
   inc cur_y
   inc cur_y
   jsr set_cursor
   lda #74
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #73
   sta VERA_data0
   stx VERA_data0
   dec cur_y
   inc cur_x
   inc cur_x
   jsr set_cursor
   lda #32
   sta VERA_data0
   cli 
   rts

; draw a button
; x, y position in draw_x and draw_y
; label as address of 0-terminated string in str_pointer
; width in draw_width
draw_button:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ; top of button
   ldx #(1+16*COLOR_BACKGROUND)
   ldy draw_width
   sei
   jsr set_cursor
   lda #100
@loop_top:
   sta VERA_data0
   stx VERA_data0
   dey
   bne @loop_top
   ; label of button
   inc cur_y
   lda #CCOLOR_BUTTON
   sta color
   ldx draw_width
   inx ; this is required by print_with_padding
   ldy #0
   jsr set_cursor
   jsr print_with_padding
   cli
   rts


; draw a number edit that has arrows
; x, y position in draw_x and draw_y
; data1: number on display
draw_arrowed_edit:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   ldx #(16*COLOR_ARROWED_EDIT_BG + COLOR_ARROWED_EDIT_ARROWS)
   lda #60 ; 62
   sta VERA_data0
   stx VERA_data0
   lda draw_data1
   ldx #(16*COLOR_ARROWED_EDIT_BG + COLOR_ARROWED_EDIT_FG)
   jsr print_byte_simple
   lda #32
   sta VERA_data0
   stx VERA_data0
   ldx #(16*COLOR_ARROWED_EDIT_BG + COLOR_ARROWED_EDIT_ARROWS)
   lda #62
   sta VERA_data0
   stx VERA_data0
   cli
   rts


; draw a number edit for drag-edit
; x, y position in draw_x and draw_y
; data1: number on display
; data2: bit 0: coarse/fine available, bit1: coarse/fine switch, bit2: signed
draw_drag_edit:
   dde_bittest = mzpbg ; mzpbg used! (use something else for bit-testing in this routine if this clashes with something else)
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldx #(16*COLOR_ARROWED_EDIT_BG + COLOR_ARROWED_EDIT_FG)
   sei
   jsr set_cursor
   lda draw_data2
   sta dde_bittest   
   bbs2 dde_bittest, @signed
@unsigned:
   bra @check_fine_coarse
@signed:
   lda draw_data1
   bmi @minus
@plus:
   lda #43
   sta VERA_data0
   stx VERA_data0
   bra @check_fine_coarse
@minus:
   eor #%11111111
   inc
   sta draw_data1
   lda #45
   sta VERA_data0
   stx VERA_data0
@check_fine_coarse:
   bbr0 dde_bittest, @no_coarse_fine ; fine/coarse ?
   ; here we are doing fine/coarse
   bbs1 dde_bittest, @fine ; doing fine?
@coarse:
   lda draw_data1
   jsr print_byte_simple
   lda #46
   sta VERA_data0
   stx VERA_data0
   cli
   rts
@fine:
   lda #46
   sta VERA_data0
   stx VERA_data0
   lda draw_data1
   jsr print_byte_simple
   cli
   rts
@no_coarse_fine:
   lda draw_data1
   jsr print_byte_simple
   cli
   rts

; draws a checkbox
; x, y position in draw_x and draw_y
; checked in draw_data1
draw_checkbox:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda draw_data1
   beq @notick
@tick:
   lda #86
   sta VERA_data0
   lda #CCOLOR_CHECKBOX_TICK
   sta VERA_data0
   bra @done
@notick:
   lda #81
   sta VERA_data0
   lda #CCOLOR_CHECKBOX_CLEAR
   sta VERA_data0
@done:
   cli
   rts


; prints a string with padding up to specified width -- quite specific, it is used in listbox & button drawing
; assumes that the VERA address is already set accordingly
; (str_pointer), y   is where printing continues, incrementing Y along the way
; color according to the variable color
; X: overall width plus 1
print_with_padding:
@loop1: ; printing loop. assumes that the string length is less or equal than the listbox/button width minus 2 (really 2 or just 1?)
   lda (str_pointer), y
   beq @end_loop1
   sta VERA_data0
   lda color
   sta VERA_data0
   dex
   iny
   bra @loop1
@end_loop1:
   ; do padding at the end of the listbox/button if necessary
@loop2:
   dex
   beq @end_loop2
   lda #32
   sta VERA_data0
   lda color
   sta VERA_data0
   bra @loop2
@end_loop2:
   rts


; draws a listbox
; x, y position in draw_x and draw_y
; width in draw_width
; label pointer in str_pointer
draw_listbox:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda #90 ; listbox "bullet"
   sta VERA_data0
   ldx #(COLOR_LISTBOX_BG*16+COLOR_LISTBOX_ARROW)
   stx VERA_data0
   lda #32
   sta VERA_data0
   stx VERA_data0
   ldy #0
   ; prepare width counter
   ldx draw_width
   dex ; (for extra characters on the left hand side of the listbox, but just one because of the way we determine the length of the padding)
   lda #(COLOR_LISTBOX_BG*16+COLOR_LISTBOX_FG)
   sta color
   jsr print_with_padding
   cli
   rts

; draws the listbox popup
; x, y position in draw_x and draw_y
; width in draw_width, height in draw_height (also marks number of strings)
; pointer to stringlist in str_pointer
draw_lb_popup:
   dlbp_line_counter = mzpbg
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldy #0
   lda draw_height
   sta dlbp_line_counter
   lda #(16*COLOR_LISTBOX_POPUP_BG+COLOR_LISTBOX_POPUP_FG)
   sta color
   sei
@line_loop:
   jsr set_cursor
   ldx draw_width
   inx
   jsr print_with_padding
   ; advance indices
   inc cur_y
   iny
   lda dlbp_line_counter
   dec
   sta dlbp_line_counter
   bne @line_loop
   cli
   rts

; clears the area on the screen where the listbox popup was before.
; x, y position in draw_x and draw_y
; width in draw_width, height in draw_height
clear_lb_popup:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldy draw_height
   lda #(16*COLOR_BACKGROUND)
   sta color
   sei
@line_loop:
   jsr set_cursor
   ldx draw_width
@column_loop:
   lda #32
   sta VERA_data0
   lda color
   sta VERA_data0
   dex
   bne @column_loop
   ; advance indices
   inc cur_y
   dey
   bne @line_loop
   cli
   rts



.endscope ; gui