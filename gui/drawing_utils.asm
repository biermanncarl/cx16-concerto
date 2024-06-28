; Copyright 2021-2024 Carl Georg Biermann


; Many utility functions for the GUI are found in this file.
; From more basic stuff like setting the VERA "screen cursor" to a specific location
; to displaying more complex stuff like frames, edits, checkboxes etc.


.scope guiutils

original_map_base: .byte 0
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
.endmacro

; displays the 0-terminated message at position db_x and db_y
; not used for the actual GUI, but rather for debugging etc.
.macro DISPLAY_LABEL msg_start, dm_x, dm_y
.local @loop_msg
.local @done_msg
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
str_pointer = gui_variables::mzpwe
sprite_temp = gui_variables::mzpwe
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

; box selection variables
box_select_left:
   .word 0
box_select_top:
   .word 0
box_select_right:
   .word 0
box_select_bottom:
   .word 0



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
   lda #CCOLOR_CAPTION
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
:  jsr set_cursor
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
@loop_right:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   dey
   bne @loop_right
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
@loop_left:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   dey
   bne @loop_left

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
   rts


; draw a number edit that has arrows
; x, y position in draw_x and draw_y
; data1: number on display
draw_arrowed_edit:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
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
   rts


; draw a number edit for drag-edit
; x, y position in draw_x and draw_y
; data1: number on display
; data2: bit 0: coarse/fine available, bit1: coarse/fine switch, bit2: signed
draw_drag_edit:
   dde_bittest = gui_variables::mzpbf ; mzpbf used! (use something else for bit-testing in this routine if this clashes with something else)
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldx #(16*COLOR_ARROWED_EDIT_BG + COLOR_ARROWED_EDIT_FG)
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
   rts
@fine:
   lda #46
   sta VERA_data0
   stx VERA_data0
   lda draw_data1
   jsr print_byte_simple
   rts
@no_coarse_fine:
   lda draw_data1
   jsr print_byte_simple
   rts

; draws a checkbox
; x, y position in draw_x and draw_y
; checked in draw_data1
draw_checkbox:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
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
   rts


; prints a string with padding up to specified width -- quite specific, it is used in combobox & button drawing
; assumes that the VERA address is already set accordingly
; (str_pointer), y   is where printing continues, incrementing Y along the way
; color according to the variable color
; X: overall width plus 1
; Y: start of string relative to (str_pointer)
print_with_padding:
@loop1: ; printing loop. assumes that the string length is less or equal than the combobox/button width minus 2 (really 2 or just 1?)
   lda (str_pointer), y
   beq @end_loop1
   sta VERA_data0
   lda color
   sta VERA_data0
   dex
   iny
   bra @loop1
@end_loop1:
   ; do padding at the end of the combobox/button if necessary
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


; draws a combobox
; x, y position in draw_x and draw_y
; width in draw_width
; label pointer in str_pointer
draw_combobox:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   jsr set_cursor
   lda #90 ; combobox "bullet"
   sta VERA_data0
   ldx #(COLOR_COMBOBOX_BG*16+COLOR_COMBOBOX_ARROW)
   stx VERA_data0
   lda #32
   sta VERA_data0
   stx VERA_data0
   ldy #0
   ; prepare width counter
   ldx draw_width
   dex ; (for extra characters on the left hand side of the combobox, but just one because of the way we determine the length of the padding)
   lda #(COLOR_COMBOBOX_BG*16+COLOR_COMBOBOX_FG)
   sta color
   jsr print_with_padding
   rts

; draws the combobox popup
; x, y position in draw_x and draw_y
; width in draw_width, height in draw_height (also marks number of strings)
; pointer to stringlist in str_pointer
draw_lb_popup:
   dlbp_line_counter = gui_variables::mzpbf
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldy #0
   lda draw_height
   sta dlbp_line_counter
   lda #(16*COLOR_COMBOBOX_POPUP_BG+COLOR_COMBOBOX_POPUP_FG)
   sta color
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
   rts

; clears an area on the screen with the background color
; x, y position in draw_x and draw_y
; width in draw_width, height in draw_height
clear_rectangle:
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   ldy draw_height
   lda #(16*COLOR_BACKGROUND)
   sta color
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
   rts


; draws a box of text buffer
; position of the box in draw_x (must be doubled), draw_y (not preserved)
; width in draw_width, height in draw_height
; VRAM address of the box (assumed to be in the low VRAM bank) in .X/.A (low,high)
.proc draw_buffer_box
   ; Here we do need SEI and CLI because we use the data port 1 of the Vera which isn't being backed up by the ISR (yet).
   php
   sei
   ; setup the VRAM read pointer
   ldy #1 ; select port 1
   sty VERA_ctrl
   stx VERA_addr_low
   sta VERA_addr_mid
   lda #$10 ; auto-increment 1, Bank 0
   sta VERA_addr_high
   plp

   ldy #0
@row_loop:
   ; setup the VRAM write pointer
   lda draw_x
   ldx draw_y
   jsr alternative_gotoxy ; also sets auto-increment to 1
   ldx #0
@column_loop:
   lda VERA_data1
   sta VERA_data0
   inx
   cpx draw_width
   bne @column_loop

   inc draw_y
   iny
   cpy draw_height
   bne @row_loop

   rts
.endproc


; draw FM algorithm
; Alg number in draw_data1
; Position fixed by macros @alg_x, @alg_y
.proc draw_fm_alg
   @alg_x = 32
   @alg_y = 45
   lda #@alg_x
   sta draw_x
   lda #@alg_y
   sta draw_y
   lda #2*5
   sta draw_width
   lda #8
   sta draw_height
   ; calculate VRAM offset (in VRAM, the different layouts are 128 bytes apart for ease of calculating offset)
   lda draw_data1
   lsr
   tay
   lda #0
   ror
   adc #<vram_assets::fm_algs
   tax
   tya
   adc #>vram_assets::fm_algs
   jsr draw_buffer_box
   rts
.endproc


; moves to screen position (.A|.X) (does not preserve .A)
alternative_gotoxy:
   stz VERA_ctrl
   asl
   sta VERA_addr_low
   lda #$10
   sta VERA_addr_high
   stx VERA_addr_mid
   rts


; Operates on .A value
.proc petsciiToScreencode
	cmp #$40
   bcc :+
	sbc #$40
:  rts
.endproc


; expects selected tab in draw_data1
; clobbers some of the other API variables
draw_globalnav:
   @tab_height = 16
   @tab_start = 12 ; y coordinate
   @num_tabs = 3
   ; abuse API variables for temporary storage
   @character_top = draw_x
   @character_bottom = draw_y
   @character_border = draw_width
   @caption_index = draw_data2
   ; TODO: draw lowest character first (which might get overwritten by selected tab)
   stz @caption_index
   stz cur_x
   lda #@tab_start
   sta cur_y
   jsr set_cursor
   ldy #0
@tab_loop:
   ; selects tab index in .Y
   phy
   cpy draw_data1
   beq @selected_tab
@unselected_tab:
   ldx #(16*COLOR_BACKGROUND + COLOR_TABS)
   ldy #77 ; line top left to bottom right
   sty @character_top
   ldy #78 ; line top right to bottom left
   sty @character_bottom
   ldy #106
   sty @character_border
   bra @draw_tab
@selected_tab:
   ldx #(16*COLOR_TABS + COLOR_BACKGROUND)
   ldy #95
   sty @character_top
   ldy #233
   sty @character_bottom
   ldy #32
   sty @character_border
@draw_tab:
   ldy @character_top
   sty VERA_data0
   stx VERA_data0
   jsr move_cursor_down
   ldy #32
   sty VERA_data0
   stx VERA_data0
   ldy @character_top
   sty VERA_data0
   stx VERA_data0
   jsr move_cursor_down
   ldy #32
   sty VERA_data0
   stx VERA_data0
   sty VERA_data0
   stx VERA_data0
   ldy @character_top
   sty VERA_data0
   stx VERA_data0
   ldy #0
@fill_loop_unselected:
   jsr move_cursor_down
   lda #32
   sta VERA_data0
   stx VERA_data0
   phy
   ldy @caption_index
   lda @captions,y
   iny
   sty @caption_index
   ply
   sta VERA_data0
   stx VERA_data0
   lda @character_border
   sta VERA_data0
   stx VERA_data0
   iny
   cpy #@tab_height-5
   bne @fill_loop_unselected ; end of fill_loop
   jsr move_cursor_down
   ldy #32
   sty VERA_data0
   stx VERA_data0
   sty VERA_data0
   stx VERA_data0
   ldy @character_bottom
   sty VERA_data0
   stx VERA_data0
   jsr move_cursor_down
   ldy #32
   sty VERA_data0
   stx VERA_data0
   ldy @character_bottom
   sty VERA_data0
   stx VERA_data0
   jsr move_cursor_down
   ; finish the tab loop
   ply
   iny
   cpy #@num_tabs
   beq :+
   jmp @tab_loop
:  rts
@captions:
   STR_FORMAT "arrangement  c l i p   s y n t h "




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

	phx
	phy
	jsr	$FFE4		; Read keyboard input
	ply
	plx

   ; now take back control and move VERA cursor back to the position we need
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
	rts


; Sets up VERA port 0 to access a sprite of given index. Will position the data pointer at the x position for convenience (not the bitmap address).
; Expects the index of the sprite in .A
; Expects the offset within the sprite data in .Y. Value must be from 0 to 7 (inclusive).
.proc setupSpriteAccess
   sprite_address_mid = sprite_temp
   sprite_address_offset = sprite_temp+1
   sty sprite_address_offset
   stz sprite_address_mid
   ; multiply sprite index by 8
   asl
   rol sprite_address_mid
   asl
   rol sprite_address_mid
   asl
   rol sprite_address_mid
   ; carry is clear as we did initialize sprite_address_high with zero
   adc sprite_address_offset ; Carry will also be clear after this operation, as well, because the lowest three bits are guaranteed zero prior to this.

   stz VERA_ctrl ; select data0
   sta VERA_addr_low
   lda #(1 + 16) ; high bank, increment by 1
   sta VERA_addr_high
   lda sprite_address_mid
   adc #$FC ; offset of sprite data, carry is zero as reasoned above
   sta VERA_addr_mid
   rts
.endproc



; todo: move these variables up to the others, so we have them all in one place


.proc showBoxSelectFrame
   lda #vram_assets::sprite_index_box_selection_frame_top_left
   ldy #2 ; offset of x data
   jsr setupSpriteAccess
   lda mouse_variables::curr_x
   sta box_select_left
   sta VERA_data0
   lda mouse_variables::curr_x+1
   sta box_select_left+1
   sta VERA_data0
   lda mouse_variables::curr_y
   sta box_select_top
   sta VERA_data0
   lda mouse_variables::curr_y+1
   sta box_select_top+1
   sta VERA_data0
   lda #12
   sta VERA_data0
   ; fall through to updateBoxSelectFrame
.endproc
.proc updateBoxSelectFrame
   lda #vram_assets::sprite_index_box_selection_frame_bottom_right
   ldy #2 ; offset of x data
   jsr setupSpriteAccess

   ; determine x position
   ; clamp x position towards box origin x
   lda mouse_variables::curr_x+1
   cmp box_select_left+1
   bcc @use_origin_x ; if high byte is lower, clamp is needed
   bne @use_mouse_x
@check_low_x:
   ; high bytes are equal, need to check low bytes
   lda mouse_variables::curr_x
   cmp box_select_left
   bcs @use_mouse_x
@use_origin_x:
   lda box_select_left
   ldx box_select_right+1
   bra @set_sprite_x
@use_mouse_x:
   lda mouse_variables::curr_x
   ldx mouse_variables::curr_x+1
@set_sprite_x:
   sta box_select_right
   stx box_select_right+1
   sec
   sbc #(vram_assets::box_selection_frame_size-1)
   sta VERA_data0
   txa
   sbc #0
   sta VERA_data0

   ; determine y position
   ; clamp y position towards box origin y
   lda mouse_variables::curr_y+1
   cmp box_select_top+1
   bcc @use_origin_y ; if high byte is lower, clamp is needed
   bne @use_mouse_y
@check_low_y:
   ; high bytes are equal, need to check low bytes
   lda mouse_variables::curr_y
   cmp box_select_top
   bcs @use_mouse_y
@use_origin_y:
   lda box_select_top
   ldx box_select_top+1
   bra @set_sprite_y
@use_mouse_y:
   lda mouse_variables::curr_y
   ldx mouse_variables::curr_y+1
@set_sprite_y:
   sta box_select_bottom
   stx box_select_bottom+1
   sec
   sbc #(vram_assets::box_selection_frame_size-1)
   sta VERA_data0
   txa
   sbc #0
   sta VERA_data0

   ; activate sprite and set hflip/vflip
   lda #15
   sta VERA_data0
   rts
.endproc

.proc hideBoxSelectFrame
   lda #vram_assets::sprite_index_box_selection_frame_top_left
   ldy #6 ; offset of sprite activation
   jsr setupSpriteAccess
   stz VERA_data0

   lda #vram_assets::sprite_index_box_selection_frame_bottom_right
   ldy #6 ; offset of sprite activation
   jsr setupSpriteAccess
   stz VERA_data0
   rts
.endproc

.endscope ; guiutils
