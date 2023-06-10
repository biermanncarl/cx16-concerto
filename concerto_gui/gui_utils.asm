; Copyright 2021 Carl Georg Biermann


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
:  stx concerto_gui::guiutils::display_100s

   ldx #48
@loop10s:
   inx
   sec
   sbc #10
   bcs @loop10s
   adc #10
   dex
   stx concerto_gui::guiutils::display_10s

   ldx #48
@loop1s:
   inx
   sec
   sbc #1
   bcs @loop1s
   adc #1
   dex
   stx concerto_gui::guiutils::display_1s

   php
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
   lda concerto_gui::guiutils::display_100s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda concerto_gui::guiutils::display_10s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda concerto_gui::guiutils::display_1s
   sta VERA_data0
   lda #$21    ; set color
   sta VERA_data0
   plp
.endmacro

; displays the 0-terminated message at position db_x and db_y
; not used for the actual GUI, but rather for debugging etc.
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
   sta concerto_gui::mzpwa
   lda #>msg_start
   sta concerto_gui::mzpwa+1
   ldy #0
@loop_msg:
   lda (concerto_gui::mzpwa),y
   beq @done_msg
   sta VERA_data0
   lda #CCOLOR_CAPTION    ; set color
   sta VERA_data0
   iny
   bra @loop_msg
@done_msg:
   cli
.endmacro


; outputs the state of the FM voice map. used only for debugging
.macro DEBUG_FM_MAP
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist, 1,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+1, 5,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+2, 9,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+3, 13,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+4, 17,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+5, 21,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+6, 25,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::freevoicelist+7, 29,55

   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap, 1,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+1, 5,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+2, 9,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+3, 13,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+4, 17,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+5, 21,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+6, 25,57
   DISPLAY_BYTE concerto_synth::voices::FMmap::timbremap+7, 29,57
   ; ffv, lfv
   DISPLAY_BYTE concerto_synth::voices::FMmap::ffv, 40,55
   DISPLAY_BYTE concerto_synth::voices::FMmap::lfv, 44,55
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

; move the cursor one line down from the current cur_x, cur_y
move_cursor_down:
   inc cur_y
   jsr set_cursor
   rts

; move the cursor two lines down from the current cur_x, cur_y
move_cursor_down2:
   inc cur_y
   inc cur_y
   jsr set_cursor
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
   ; set tilemap base address to zero
   lda #0
   sta VERA_L1_mapbase
   ; clear the screen
   ldy #0
@loop_y:
   lda #0
   sta cur_x
   sty cur_y
   jsr set_cursor
   ldx #0
@loop_x:
   lda #32
   sta VERA_data0
   lda #(11*16+1)
   sta VERA_data0
   inx
   cpx #80
   bne @loop_x
   iny
   cpy #60
   bne @loop_y

   ; actually, I'd like a dark green or something
   ; TODO: set custom palette
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
   dde_bittest = mzpbf ; mzpbf used! (use something else for bit-testing in this routine if this clashes with something else)
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
   dlbp_line_counter = mzpbf
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



; draw FM algorithm
; Alg number in draw_data1
; Position fixed by macros @alg_x, @alg_y
draw_fm_alg:
   @alg_x = 36
   @alg_y = 45
   ; clear drawing area
   lda #@alg_x
   sta draw_x
   lda #@alg_y
   sta draw_y
   lda #5
   sta draw_width
   lda #8
   sta draw_height
   jsr clear_lb_popup
   lda #@alg_x
   sta cur_x
   lda #@alg_y
   sta cur_y
   ; do actual drawing
   sei
   jsr set_cursor
   ldx #CCOLOR_ALG_CONNECTION
   ; operator 1, always the same
   lda #112
   sta VERA_data0
   stx VERA_data0
   lda #110
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   jsr set_cursor
   lda #109
   sta VERA_data0
   stx VERA_data0
   lda #49
   sta VERA_data0
   ldx #CCOLOR_ALG_OP_NUMBERS
   stx VERA_data0
   ; all algs require this
   inc cur_x
   ; now switch depending on alg
   lda draw_data1
   asl
   tax
   INDEXED_JSR @jmp_table, @return
@jmp_table:
   .word @con_0
   .word @con_1
   .word @con_2
   .word @con_3
   .word @con_4
   .word @con_5
   .word @con_6
   .word @con_7
@con_0:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   jsr move_cursor_down2
   lda #50
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #51
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #66
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #66
   sta VERA_data0
   stx VERA_data0
   rts
@con_1:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   lda #50
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #51
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #107
   sta VERA_data0
   stx VERA_data0
   lda #125
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #66
   sta VERA_data0
   stx VERA_data0
   rts
@con_2:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   lda #50
   sta VERA_data0
   stx VERA_data0
   inc cur_x
   jsr move_cursor_down2
   lda #51
   sta VERA_data0
   stx VERA_data0
   dec cur_x
   jsr move_cursor_down
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down
   lda #107
   sta VERA_data0
   stx VERA_data0
   rts
@con_3:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   lda #51
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #50
   sta VERA_data0
   stx VERA_data0
   inc cur_x
   jsr move_cursor_down
   lda #52
   sta VERA_data0
   stx VERA_data0
   dec cur_x
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   sta VERA_data0
   stx VERA_data0
   inc cur_x
   jsr move_cursor_down
   lda #115
   sta VERA_data0
   stx VERA_data0
   rts
@con_4:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   lda #51
   sta VERA_data0
   stx VERA_data0
   jsr move_cursor_down2
   lda #50
   sta VERA_data0
   stx VERA_data0
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   sta VERA_data0
   stx VERA_data0
   rts
@con_5:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   jsr move_cursor_down2
   lda #50
   sta VERA_data0
   stx VERA_data0
   lda #51
   sta VERA_data0
   stx VERA_data0
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #107
   sta VERA_data0
   stx VERA_data0
   lda #114
   sta VERA_data0
   stx VERA_data0
   lda #110
   sta VERA_data0
   stx VERA_data0
   rts
@con_6:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   jsr move_cursor_down2
   lda #51
   sta VERA_data0
   stx VERA_data0
   lda #50
   sta VERA_data0
   stx VERA_data0
   lda #52
   sta VERA_data0
   stx VERA_data0
   ; draw connections
   ldx #CCOLOR_ALG_CONNECTION
   lda #@alg_y+2
   sta cur_y
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   rts
@con_7:
   ; finish off numbers
   ldx #CCOLOR_ALG_OP_NUMBERS
   lda #51
   sta VERA_data0
   stx VERA_data0
   lda #50
   sta VERA_data0
   stx VERA_data0
   lda #52
   sta VERA_data0
   stx VERA_data0
   rts
@return:
   cli
   rts
; moves to screen position (.A|.X) (does not preserve .A)
alternative_gotoxy:
   stz VERA_ctrl
   asl
   sta VERA_addr_low
   lda #$10
   sta VERA_addr_high
   stx VERA_addr_mid
   rts






; This function has been adapted from the awesome VTUI library by JimmyDansbo.
; https://github.com/JimmyDansbo/VTUIlib
; https://www.commanderx16.com/forum/index.php?/files/file/142-vtui-library/

; Unfortunately, we have to modify it severely because the VERA communication
; would otherwise get disrupted by the interrupt.

; *****************************************************************************
; Show a cursor and get a string input from keyboard.
; *****************************************************************************
; INPUTS:	r0 = pointer to buffer to hold string (must be pre-allocated)
;     r2 = screen coordinates
;     r3 = pointer to buffer holding the screen code 
;		.Y = maximum length of string
;		.X = color information for input characters
; OUPUTS:	.Y = actual length of input
; USES:		.A & r1
; *****************************************************************************
vtui_input_str:
@ptr	= r0
@length	= r1L
@invcol	= r1H
@pos_x   = r2L
@pos_y   = r2H

   phx
	sty	@length		; Store maximum length

   ; move cursor to screen position
   sei
   lda @pos_x
   ldx @pos_y
   jsr alternative_gotoxy

	lda	#$A0		; Show a "cursor"
	sta	VERA_data0
   plx
	stx	VERA_data0
	;dec	VERA_addr_low ; only necessary if we do not re-set the cursor later
	;dec	VERA_addr_low
   ; clear remaining area for string input
   phy
   dey
   lda #' '
:  sta VERA_data0
   stx VERA_data0
   dey
   bne :-
   ply

	ldy	#0
@inputloop:
   ; give ISR a moment to interrupt us
   cli

	phx
	phy
	jsr	$FFE4		; Read keyboard input
	ply
	plx

   ; now take back control and move VERA cursor back to the position we need
   sei
   pha
   phx
   tya
   clc
   adc @pos_x
   ldx @pos_y
   jsr alternative_gotoxy
   plx
   pla

	cmp	#$0D		; If RETURN has been pressed, we exit
	beq	@end
	cmp	#$14		; We need to handle backspace
	bne	@istext
	cpy	#0		; If .Y is 0, we can not delete
	beq	@inputloop
	; Here we need to handle backspace
	dey
	lda	#' '		; Delete cursor
	sta	VERA_data0

	lda	VERA_addr_low	; Go 2 chars back = 4 bytes
	sbc	#3
	sta	VERA_addr_low

	lda	#$A0		; Overwrite last char with cursor
	sta	VERA_data0

	dec	VERA_addr_low
	bra	@inputloop
@istext:
	cpy	@length
	beq	@inputloop	; If .Y = @length, we can not add character

	;sta	(@ptr),y	; Store char in buffer  --  original function stored input petscii. Here, we store screen codes
	cmp	#$20		; If < $20, we can not use it
	bcc	@inputloop
	cmp	#$40		; If < $40 & >= $20, screencode is equal to petscii
	bcc	@stvera
	cmp	#$60		; If > $60, we can not use it
	bcs	@inputloop
	sbc	#$3F		; When .A >= $40 & < $60, subtract $3F to get screencode
@stvera:
   sta	(@ptr),y ; store screen code in buffer
	sta	VERA_data0	; Write char to screen with colorcode
	stx	VERA_data0

	lda	#$A0		; Write cursor
	sta	VERA_data0
	stx	VERA_data0

	dec	VERA_addr_low	; Set VERA to point at cursor
	dec	VERA_addr_low
	iny			; Inc .Y to show a char has been added
	bra	@inputloop

@end:	lda	#' '
	sta	VERA_data0
	stx	VERA_data0
   lda   #0
   sta   (@ptr),y ; trailing zero to finish string
   cli
	rts









.endscope ; guiutils