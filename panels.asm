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
      py = osc::py+osc::hg+1
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