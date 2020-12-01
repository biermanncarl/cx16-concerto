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

; GUI control element legend:
; 0: none (end of list)
; 1: button, followed by x and y position (absolute), and width, and address of string
; 2: tab selector, followed by number of tabs
; 3: arrowed edit, followed by x and y position (absolute)
; 4: dragging edit


; PANEL DATA
.scope panels

   ; compiler variables for convenience
   ; and panel data that will be accessed via pointers
   .scope global
      px = 15
      py = 10
      wd = 10
      hg = 18
      cp: STR_FORMAT "global" ; caption of panel
      .scope pos ; positions of GUI elements
         ts_x = px + 2
         ts_y = py + 2
      .endscope
      ; component string of global panel
      comps:
         .byte 3, pos::ts_x, pos::ts_y ; arrowed edit (timbre selection for now)
         .byte 0
   .endscope
   .scope osc
      px = global::px+global::wd
      py = global::py
      wd = 33
      hg = global::hg
      cp: STR_FORMAT "oscillators" ; caption of panel
      ; component string of oscillator panel
      comps:
         .byte 2, 6 ; tabselector
         .byte 0
      ; data specific to the oscillator panel
      active_tab: .byte 0
   .endscope
   .scope env
      px = 15
      py = osc::py+osc::hg
      wd = 24
      hg = 8
      cp: STR_FORMAT "envelopes" ; caption of panel
      ; component string of envelope panel
      comps:
         .byte 2, 3 ; tab selector
         .byte 0
      ; data specific to the envelope panel
      active_tab: .byte 0
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
   ds: .word draw_global, draw_osc, draw_env
   ; GUI component strings
   comps: .word global::comps, osc::comps, env::comps
   ; mouse subroutines:
   ; mouse click subroutines
   cs: .word click_global, click_osc, click_env


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
   ; TODO: clear area on screen (but when exactly is it needed?)
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

; click event. looks in mouse variables which panel has been clicked and calls its routine
click_event:
   lda ms_curr_panel
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addr1 = @ret_addr-1
   lda #(>@ret_addr1)
   pha
   lda #(<@ret_addr1)
   pha
   jmp (cs,x)
@ret_addr:
   rts

; returns the panel index the mouse is currently over. Bit 7 set means none
; panel index returned in register A
mouse_get_panel:
   ; grab those zero page variables for this routine
   gp_cx = mzpwa
   gp_cy = mzpwd
   ; determine position in characters (divide by 8)
   lda ms_curr_x+1
   lsr
   sta gp_cx+1
   lda ms_curr_x
   ror
   sta gp_cx
   lda gp_cx+1
   lsr
   ror gp_cx
   lsr
   ror gp_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda ms_curr_y+1
   lsr
   sta gp_cy+1
   lda ms_curr_y
   ror
   sta gp_cy
   lda gp_cy+1
   lsr
   ror gp_cy
   lsr
   ror gp_cy
   ; now check panels from top to bottom
   lda stack::sp
   tax
@loop:
   dex
   bmi @end_loop
   ldy stack::stack, x ; y will be panel's index
   lda px, y
   dec
   cmp gp_cx
   bcs @loop ; gp_cx is smaller than panel's x
   clc
   adc wd, y
   cmp gp_cx
   bcc @loop ; gp_cx is too big
   lda py, y
   dec
   cmp gp_cy
   bcs @loop ; gp_cy is smaller than panel's y
   clc
   adc hg, y
   cmp gp_cy
   bcc @loop ; gp_cy is too big
   ; we're inside! return index
   tya
   rts
@end_loop:
   ; found no match
   lda #255
   rts



; given the panel, where the mouse is currently at,
; this subroutine finds which GUI component is being clicked
mouse_get_component:
   ; panel number in ms_curr_panel
   ; mouse x and y coordinates in ms_curr_x and ms_curr_y
   ; zero page variables:
   gc_pointer = mzpwa
   gc_cx = mzpwd     ; x and y in multiples of 4 (!) pixels to support half character grid
   gc_cy = mzpwd+1
   gc_counter = mzpba
   ; determine position in multiples of 4 pixels (divide by 4)
   lda ms_curr_x+1
   lsr
   sta gc_cx+1
   lda ms_curr_x
   ror
   sta gc_cx
   lda gc_cx+1
   lsr
   ror gc_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda ms_curr_y+1
   lsr
   sta gc_cy+1
   lda ms_curr_y
   ror
   sta gc_cy
   lda gc_cy+1
   lsr
   ror gc_cy
   ; copy pointer to component string to ZP
   lda ms_curr_panel
   asl
   tax
   lda comps, x
   sta gc_pointer
   lda comps+1, x
   sta gc_pointer+1
   ; iterate over gui elements
   ldy #0
   lda #255
   sta gc_counter
check_gui_loop:
   ; increment control element identifier
   inc gc_counter
   ; look up which component type is next (type 0 is end of GUI component list)
   lda (gc_pointer), y
   iny
   asl
   tax
   ; jump to according component check
   jmp (@jmp_table, x)
@jmp_table:
   .word @end_gui
   .word check_button
   .word check_tab_selector
   .word check_arrowed_edit
@end_gui:
   lda #255
   rts

; component checks (part of mouse_get_component_subroutine)
; ---------------------------------------------------------
check_button:
   ; check if mouse is over the button
   iny
   iny
   iny
   jmp check_gui_loop

; which tab clicked is returned in ms_curr_data
check_tab_selector:
   ; check if mouse is over the tab selector area of the panel
   ; check x direction first
   ldx ms_curr_panel
   lda px, x
   asl ; multiply by 2 to be 4 pixel multiple
   sec
   sbc gc_cx ; now we have negative mouse offset, need to negate it
   eor #255
   ;inc ; would be cancelled by dec
   ; now we got relative y position in 4 pixel multiples
   ; subtract 1 for the top margin
   ;dec ; cancelled by previous inc
   ; now compare with tab selector width, which is 4
   cmp #4
   bcc :+ ; if carry clear, we are in
   iny ; skip data byte in GUI component string before checking next GUI component
   jmp check_gui_loop
:  ; check y direction second
   lda py, x
   asl ; multiply by 2 to be 4 pixel multiple
   sec
   sbc gc_cy ; now we have negative mouse offset, need to negate it
   eor #255
   ;inc ; would be cancelled by dec
   ; now we got relative y position in 4 pixel multiples
   ; subtract 1 for the top margin, and then divide by 4, because that's the height of each tab selector
   ;dec ; cancelled by previous inc
   lsr
   lsr
   ; now we have the index of the tab clicked
   ; compare it to number of tabs present
   cmp (gc_pointer), y
   iny
   bcs :+ ; if carry set, no tab has been clicked
   ; otherwise, tab has been selected
   sta ms_curr_data
   lda gc_counter
   rts
:  jmp check_gui_loop

; which arrow clicked is returned in ms_curr_data
ca_which_arrow: .byte 0
check_arrowed_edit:
   stz ca_which_arrow
   ; check if mouse is over the edit
   ; check x direction
   lda gc_cx
   lsr ; we want cursor position in whole characters (8 pixel multiples), not half characters (4 pixel multiples)
   sec
   sbc (gc_pointer), y ; subtract edit's position. so all valid values are smaller than edit size
   iny
   cmp #5 ; size of arrowed edit
   bcc :+
   iny
   jmp check_gui_loop
:  ; correct x range. Now check for click on one of the arrows
   cmp #0 ; arrow to the left
   bne :+
   lda #1
   sta ca_which_arrow
   bra :++
:  cmp #4
   bne :+
   lda #2
   sta ca_which_arrow
:  ; check y direction
   lda gc_cy
   lsr
   cmp (gc_pointer), y
   beq :+ ; only if it's equal
   iny
   jmp check_gui_loop
:  ; mouse is at correct height
   lda ca_which_arrow
   sta ms_curr_data
   lda gc_counter
   iny
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
   sta guiutils::draw_data1
   lda #0
   sta guiutils::draw_data2
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
   ; draw timbre selector
   lda #global::pos::ts_x
   sta guiutils::draw_x
   lda #global::pos::ts_y
   sta guiutils::draw_y
   lda Timbre
   sta guiutils::draw_data1
   jsr guiutils::draw_arrowed_edit
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
   sta guiutils::draw_data1
   lda osc::active_tab
   inc
   sta guiutils::draw_data2
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
   sta guiutils::draw_data1
   lda env::active_tab
   inc
   sta guiutils::draw_data2
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


click_global:
   lda ms_curr_component
   cmp #0
   beq @timbre_selector
   rts
@timbre_selector:
   ; which direction?
   lda ms_curr_data
   bne :+
   rts
:  cmp #1
   bne @right
@left:
   dec Timbre
   bpl :+
   lda #(N_TIMBRES - 1)
   sta Timbre
:  bra @update_timbre_select
@right:
   lda Timbre
   inc
   cmp #N_TIMBRES
   bne :+
   lda #0
:  sta Timbre
@update_timbre_select:
   jsr draw_global
   rts

; oscillator panel being clicked
click_osc:
   ; tab selector ?
   lda ms_curr_component
   cmp #0
   bne :+
   lda ms_curr_data
   sta osc::active_tab
   jsr draw_osc ; TODO replace with draw_tabs to prevent flicker
:  rts

click_env:
   ; tab selector ?
   lda ms_curr_component
   cmp #0
   bne :+
   lda ms_curr_data
   sta env::active_tab
   jsr draw_env ; TODO replace with draw_tabs
:  rts

.endscope