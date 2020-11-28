; This file contains stuff related to panels on the GUI.
; Panels are rectangular areas on the screen that contain basic GUI elements
; like buttons, checkboxes etc.
; They behave a bit like windows.
; The look and behaviour of all panels are hard coded.
; However, they can be made visible/invisible and also their order can be changed.
; The order affects which panels appear on top and which receive mouse events first.


; Panel legend:
; 0: global settings
; 1: oscillator settings
; 2: envelope settings

; PANEL DATA
; might eventually get moved to the .RODATA section in a separate file
.scope panels

   ; compiler variables for convenience
   ; and panel data that will be accessed via pointers
   .scope global
      px = 15
      py = 10
      wd = 10
      hg = 18
      cp: STR_FORMAT "global"
   .endscope
   .scope osc
      px = global::px+global::wd
      py = global::py
      wd = 33
      hg = global::hg
      cp: STR_FORMAT "oscillators"
   .endscope
   .scope env
      px = 15
      py = osc::py+osc::hg
      wd = 24
      hg = 8
      cp: STR_FORMAT "envelopes"
   .endscope

   ; Actual Panel Data
   ; Each label marks a list of values, one for each panel.
   ; These lists must have length N_PANELS.
   ; X positions
   px: .byte global::px, osc::px, env::px
   ; Y positions
   py: .byte global::py, osc::py, env::py
   ; widths
   wd: .byte global::wd, osc::wd, env::wd
   ; heights
   hg: .byte global::hg, osc::hg, env::hg
   ; drawing subroutines
   ds: .word panels::draw_global, panels::draw_osc, panels::draw_env
   ; mouse subroutines
   ; TODO



; The Panel Stack
; defines which panels are drawn in which order, and which panels receive mouse events first.
; The first elements in the stack are at the bottom.
.scope stack
   stack: PANEL_BYTE_FIELD    ; the actual stack, containing the indices of the panels
   sp: .byte 0                ; stack pointer, counts how many elements are on the stack
.endscope

; brings up the synth GUI
load_synth_gui:
   jsr guiutils::cls
   lda #3
   sta stack::sp
   lda #0
   sta stack::stack
   lda #1
   sta stack::stack+1
   lda #2
   sta stack::stack+2
   jsr draw_panels
   rts

; reads through the stack and draws everything
draw_panels:
   counter = mzpba ; counter variable
   stz counter
@loop:
   ; TODO: clear area on screen
   ; call drawing subroutine
   lda counter
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addr1 = @ret_addr-1
   lda #(>@ret_addr1)
   pha
   lda #(<@ret_addr1)
   pha
   jmp (ds,x)
@ret_addr:
   ; advance in loop
   lda counter
   inc
   cmp stack::sp
   sta counter
   bne @loop
   rts


; returns the panel index the mouse is currently over. Bit 7 set means none
; panel index returned in register A
mouse_get_panel:
   ; grab those zero page variables for this routine
   cx = mzpwa
   cy = mzpwd
   ; determine position in characters (divide by 8)
   lda ms_curr_x+1
   lsr
   sta cx+1
   lda ms_curr_x
   ror
   sta cx
   lda cx+1
   lsr
   ror cx
   lsr
   ror cx
   ; (high byte is uninteresting, thus not storing it back)
   lda ms_curr_y+1
   lsr
   sta cy+1
   lda ms_curr_y
   ror
   sta cy
   lda cy+1
   lsr
   ror cy
   lsr
   ror cy
   ; now check panels from top to bottom
   lda stack::sp
   tax
@loop:
   dex
   bmi @end_loop
   ldy stack::stack, x ; y will be panel's index
   lda px, y
   dec
   cmp cx
   bcs @loop ; cx is smaller than panel's x
   clc
   adc wd, y
   cmp cx
   bcc @loop ; cx is too big
   lda py, y
   dec
   cmp cy
   bcs @loop ; cy is smaller than panel's y
   clc
   adc hg, y
   cmp cy
   bcc @loop ; cy is too big
   ; we're inside! return index
   tya
   rts
@end_loop:
   ; found no match
   lda #255
   rts



; PANEL SPECIFIC STUFF
; --------------------

draw_global:
   ; draw panel
   lda #global::px
   sta guiutils::draw_x
   lda #global::py
   sta guiutils::draw_y
   lda #global::wd
   sta guiutils::draw_width
   lda #global::hg
   sta guiutils::draw_height
   lda #0
   sta guiutils::draw_n_tabs
   lda #0
   sta guiutils::draw_active
   jsr guiutils::draw_frame
   ; draw caption
   lda #global::px
   clc
   adc #2
   sta guiutils::cur_x
   lda #global::py
   sta guiutils::cur_y
   lda #(<global::cp)
   sta guiutils::str_pointer
   lda #(>global::cp)
   sta guiutils::str_pointer+1
   lda #(16*COLOR_BACKGROUND+COLOR_CAPTION)
   sta guiutils::color
   jsr guiutils::print
   rts

draw_osc:
   ; draw panel
   lda #osc::px
   sta guiutils::draw_x
   lda #osc::py
   sta guiutils::draw_y
   lda #osc::wd
   sta guiutils::draw_width
   lda #osc::hg
   sta guiutils::draw_height
   lda #MAX_OSCS_PER_VOICE
   sta guiutils::draw_n_tabs
   lda #3
   sta guiutils::draw_active
   jsr guiutils::draw_frame
   ; draw caption
   lda #osc::px
   clc
   adc #4
   sta guiutils::cur_x
   lda #osc::py
   sta guiutils::cur_y
   lda #(<osc::cp)
   sta guiutils::str_pointer
   lda #(>osc::cp)
   sta guiutils::str_pointer+1
   lda #(16*COLOR_BACKGROUND+COLOR_CAPTION)
   sta guiutils::color
   jsr guiutils::print
   rts

draw_env:
   ; draw panel
   lda #env::px
   sta guiutils::draw_x
   lda #env::py
   sta guiutils::draw_y
   lda #env::wd
   sta guiutils::draw_width
   lda #env::hg
   sta guiutils::draw_height
   lda #MAX_ENVS_PER_VOICE
   sta guiutils::draw_n_tabs
   lda #1
   sta guiutils::draw_active
   jsr guiutils::draw_frame
   ; draw caption
   lda #env::px
   clc
   adc #4
   sta guiutils::cur_x
   lda #env::py
   sta guiutils::cur_y
   lda #(<env::cp)
   sta guiutils::str_pointer
   lda #(>env::cp)
   sta guiutils::str_pointer+1
   lda #(16*COLOR_BACKGROUND+COLOR_CAPTION)
   sta guiutils::color
   jsr guiutils::print
   rts


.endscope