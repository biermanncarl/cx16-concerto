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
; 3: synth navigation bar (snav)

; Caption List data format:
; first byte: color (foreground and background). If it's zero, it marks the end of the list.
; second and third bytes: x and y position
; fourth and fifth bytes: pointer to zero-terminated string.

; GUI control element legend:
; 0: none (end of list)
; 1: button, followed by x and y position (absolute), and width, and address of string
; 2: tab selector, followed by x and y position (abs), number of tabs, and active tab
; 3: arrowed edit, followed by x and y position (abs), min value, max value, value
; 4: dragging edit, followed by x and y position (abs), options (flags), min value, max value, coarse value, fine value

; drag edit flags options:
; bit 0: coarse/fine option enabled
; bit 1: fine active
; bit 2: signed
; options irrelevant for drawing the component:
; bit 7: zero forbidden (for signed scale5 values)





.scope gui
   ; PANEL DATA

   ; compiler variables for convenience
   ; and panel data that will be accessed via pointers
   .scope global
      px = 15
      py = 10
      wd = 10
      hg = 18
      .scope pos ; positions of GUI elements
         ts_x = px + 2
         ts_y = py + 3
      .endscope
      ; GUI component string of global panel
      comps:
         .byte 3, pos::ts_x, pos::ts_y, 0, 4, 0 ; arrowed edit (timbre selection for now)
         .byte 3, pos::ts_x, pos::ts_y+3, 0, 4, 1 ; arrowed edit (timbre selection for now)
         .byte 0
      ; caption list of global panel
      capts:
         .byte CCOLOR_CAPTION, px+2, py
         .word cp
         .byte 0
      cp: STR_FORMAT "global" ; caption of panel
   .endscope
   .scope osc
      px = global::px+global::wd
      py = global::py
      wd = 33
      hg = global::hg
      ; GUI component string of oscillator panel
      comps:
         .byte 2, px, py, 6, 0 ; tabselector
         .byte 4, px+4, py+2, %00000101, 0, 255, 0, 0 ; drag edit
         .byte 0
      ; caption list of oscillator panel
      capts:
         .byte CCOLOR_CAPTION, px+4, py
         .word cp
         .byte 0
      ; data specific to the oscillator panel
      active_tab: .byte 0
      cp: STR_FORMAT "oscillators" ; caption of panel
   .endscope
   .scope env
      px = 15
      py = osc::py+osc::hg
      wd = 24
      hg = 8
      ; GUI component string of envelope panel
      comps:
         .byte 2, px, py, 3, 0 ; tab selector
         .byte 4, px+4 , py+3, %00000001, 0, 127, 0, 0 ; drag edit - attack
         .byte 4, px+9 , py+3, %00000001, 0, 127, 0, 0 ; drag edit - decay
         .byte 4, px+14, py+3, %00000000, 0, 127, 0, 0 ; drag edit - sustain
         .byte 4, px+18, py+3, %00000001, 0, 127, 0, 0 ; drag edit - release
         .byte 0
      ; caption list of envelope panel
      capts:
         .byte CCOLOR_CAPTION, px+4, py
         .word cp
         .byte CCOLOR_CAPTION, px+4, py+2
         .word lb_attack
         .byte CCOLOR_CAPTION, px+9, py+2
         .word lb_decay
         .byte CCOLOR_CAPTION, px+14, py+2
         .word lb_sustain
         .byte CCOLOR_CAPTION, px+18, py+2
         .word lb_release
         .byte 0
      ; data specific to the envelope panel
      active_tab: .byte 0
      cp: STR_FORMAT "envelopes" ; caption of panel
      lb_attack: STR_FORMAT "att"
      lb_decay: STR_FORMAT "dec"
      lb_sustain: STR_FORMAT "sus"
      lb_release: STR_FORMAT "rel"
   .endscope
   .scope snav
      px = 0
      py = 0
      wd = 80
      hg = 4
      ; GUI component string of envelope panel
      comps:
         .byte 3, 11, 1, 0, 4, 0 ; arrowed edit (timbre selection)
         .byte 0
      ; caption list of envelope panel
      capts:
         .byte CCOLOR_CAPTION, 1, 1
         .word cp
         .byte 0
      ; data specific to the envelope panel
      active_tab: .byte 0
      cp: STR_FORMAT "timbre" ; caption of panel
   .endscope

   ; Panel Lookup tables
   ; Each label marks a list of values, one for each panel.
   ; These lists must have length N_PANELS.
   ; X positions
   px: .byte global::px, osc::px, env::px, snav::px
   ; Y positions
   py: .byte global::py, osc::py, env::py, snav::py
   ; widths
   wd: .byte global::wd, osc::wd, env::wd, snav::wd
   ; heights
   hg: .byte global::hg, osc::hg, env::hg, snav::hg
   ; drawing subroutines
   drws: .word draw_global, draw_osc, draw_env, draw_snav
   ; GUI component strings
   comps: .word global::comps, osc::comps, env::comps, snav::comps
   ; GUI captions
   capts: .word global::capts, osc::capts, env::capts, snav::capts
   ; mouse subroutines:
   ; mouse click subroutines
   cs: .word click_global, click_osc, click_env, click_snav
   ; drag subroutines
   drgs: .word drag_global, drag_osc, drag_env, drag_snav


; The Panel Stack
; defines which panels are drawn in which order, and which panels receive mouse events first.
; The first elements in the stack are at the bottom.
.scope stack
   stack: PANEL_BYTE_FIELD    ; the actual stack, containing the indices of the panels
   sp: .byte 0                ; stack pointer, counts how many elements are on the stack
.endscope

; placeholder for unimplemented subroutines
dummy_sr:
   rts


; brings up the synth GUI
; puts all synth panels into GUI stack
load_synth_gui:
   jsr guiutils::cls
   lda #4
   sta stack::sp
   lda #0
   sta stack::stack
   lda #1
   sta stack::stack+1
   lda #2
   sta stack::stack+2
   lda #3
   sta stack::stack+3
   jsr draw_gui
   rts




; reads through the stack and draws everything
draw_gui:
   counter = mzpba ; counter variable
   stz counter
@loop:
   ; TODO: clear area on screen (but when exactly is it needed?)
   ; call panel-specific drawing subroutine
   lda counter
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addr1 = @ret_addr-1
   lda #(>@ret_addr1)
   pha
   lda #(<@ret_addr1)
   pha
   jmp (drws,x)
@ret_addr:
   ; draw GUI components
   lda counter
   jsr draw_components
   ; draw captions
   lda counter
   jsr draw_captions
   ; advance in loop
   lda counter
   inc
   cmp stack::sp
   sta counter
   bne @loop
   rts

; draws all captions from the caption string of a panel
; expects panel ID in register A
draw_captions:
   dcp_pointer = mzpwd
   ; mzpwa is used by print subroutine,
   ; and that's where we pass the pointers to our strings.
   asl
   tax
   lda capts, x
   sta dcp_pointer
   lda capts+1, x
   sta dcp_pointer+1
   ldy #0
@loop:
   lda (dcp_pointer), y
   beq @end_loop
   sta guiutils::color
   iny
   lda (dcp_pointer), y
   sta guiutils::cur_x
   iny
   lda (dcp_pointer), y
   sta guiutils::cur_y
   iny
   lda (dcp_pointer), y
   sta guiutils::str_pointer
   iny
   lda (dcp_pointer), y
   sta guiutils::str_pointer+1
   iny
   phy
   jsr guiutils::print
   ply
   jmp @loop
@end_loop:
   rts

; goes through a GUI component string and draws all components in it
; expects panel ID in register A
draw_components:
   dc_pointer = mzpwa
   asl
   tax
   lda comps, x
   sta dc_pointer
   lda comps+1, x
   sta dc_pointer+1
   ldy #0
@loop:
@ret_addr:
   lda (dc_pointer), y
   beq @end_loop
   iny
   asl
   tax
   ; emulate a jsr
@ret_addr1 = @ret_addr-1
   lda #(>@ret_addr1)
   pha
   lda #(<@ret_addr1)
   pha
   jmp (@jmp_table-2,x) ;-2 because there's no drawing routine for "none" component
@jmp_table:
   .word dummy_sr  ; button
   .word draw_tab_select  ; tab-select (no drawing routine, drawing is done in panel-specific routine)
   .word draw_arrowed_edit  ; arrowed edit
   .word draw_drag_edit ; drag edit
@end_loop:
   rts

; GUI components' drawing routines
; --------------------------------
; expect GUI component string address in dc_pointer, and offset (+1) in register Y
; and are expected to advance register Y to the start of the next component

draw_tab_select:
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   lda (dc_pointer), y
   sta guiutils::draw_data1
   iny
   lda (dc_pointer), y
   inc
   sta guiutils::draw_data2
   iny
   phy
   jsr guiutils::draw_tabs
   ply
   rts

draw_arrowed_edit:
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   iny
   iny
   lda (dc_pointer), y
   iny
   sta guiutils::draw_data1
   phy
   jsr guiutils::draw_arrowed_edit
   ply
   rts

; 4: dragging edit, followed by x and y position (abs), options (flags), min value, max value, coarse value, fine value
draw_drag_edit:
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   lda (dc_pointer), y
   and #%01111111    ; get rid of drawing-irrelevant bits
   sta guiutils::draw_data2
   ; select fine or coarse value:
   lda (dc_pointer), y
   iny
   iny
   iny
   and #%00000010
   beq :+
   ; fine
   iny
   lda (dc_pointer), y
   bra :++
:  ; coarse
   lda (dc_pointer), y
   iny
:  sta guiutils::draw_data1
   iny
   phy
   jsr guiutils::draw_drag_edit
   ply
   rts


; click event. looks in mouse variables which panel has been clicked and calls its routine
; also looks which component has been clicked and calls according routine
click_event:
   ; call GUI component's click subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   ce_pointer = mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   lda ms_curr_panel
   asl
   tax
   lda comps, x
   sta ce_pointer
   lda comps+1, x
   sta ce_pointer+1   ; put GUI component string pointer to ZP
   ldy ms_curr_component_ofs ; load component's offset
   lda (ce_pointer), y ; and get its type
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addrA1 = @ret_addrA-1
   lda #(>@ret_addrA1)
   pha
   lda #(<@ret_addrA1)
   pha
   jmp (@jmp_tbl-2,x) ; -2 because there is nothing to do for component type 0
@jmp_tbl:
   .word click_button
   .word click_tab_select
   .word click_arrowed_edit
   .word click_drag_edit
@ret_addrA:
   ; call panel's click subroutine, which is part of the interface between GUI and internal data
   lda ms_curr_panel
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addrB1 = @ret_addrB-1
   lda #(>@ret_addrB1)
   pha
   lda #(<@ret_addrB1)
   pha
   jmp (cs,x)
@ret_addrB:
   rts

; GUI component's click subroutines
; ---------------------------------
; expect component string's pointer in ce_pointer on zero page,
; and also the component's offset in ms_curr_component_ofs
; and relevant click data (determined by the click detection) in ms_curr_data

click_button:
   rts

click_tab_select:
   ; put new tab into GUI component list
   lda ms_curr_data
   ldy ms_curr_component_ofs
   iny
   iny
   iny
   iny
   sta (ce_pointer), y
   ; and redraw it
   ldy ms_curr_component_ofs
   iny
   jsr draw_tab_select
   rts

click_arrowed_edit:
   cae_value = mzpba
   ; check if one of the arrows has been clicked
   lda ms_curr_data
   bne :+
   rts
:  ; yes, one of the arrows has been clicked...
   ; now, get value from edit
   lda ms_curr_component_ofs
   clc
   adc #5
   tay
   lda (ce_pointer), y
   sta cae_value
   ; now, decide whether left or right was clicked
   dey
   lda ms_curr_data
   cmp #1
   bne @right
@left:   ; decrement value
   ; get minimal value
   dey
   lda (ce_pointer), y
   cmp cae_value
   bne :+
   ; if we're here, we're sitting at the bottom of valid range, need to wrap around
   ; need to get maximal value
   iny
   lda (ce_pointer), y
   dey
   inc ; increment it to cancel upcoming decrement
   sta cae_value
:  ; decrement
   lda cae_value
   dec
   ; and store it back
   iny
   iny
   sta (ce_pointer), y
   bra @update
@right:   ; increment value
   ; get maximal value
   lda (ce_pointer), y
   cmp cae_value
   bne :+
   ; if we're here, we're sitting at the top of the valid range, need to wrap around
   ; need to get minimal value
   dey
   lda (ce_pointer), y
   iny
   dec ; decrement it to cancel upcoming increment
   sta cae_value
:  ; increment
   lda cae_value
   inc
   ; and store it back
   iny
   sta (ce_pointer), y
   bra @update
@update:
   ldy ms_curr_component_ofs
   iny
   jsr draw_arrowed_edit
   rts

click_drag_edit:
   rts



; drag event. looks in mouse variables which panel's component has been dragged and calls its routine
; expects L/R information in ms_curr_data (0 for left drag, 1 for right drag)
; and dragging distance in ms_curr_data2
drag_event:
   ; call GUI component's drag subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   de_pointer = mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   lda ms_ref_panel
   asl
   tax
   lda comps, x
   sta de_pointer
   lda comps+1, x
   sta de_pointer+1   ; put GUI component string pointer to ZP
   ldy ms_ref_component_ofs ; load component's offset
   lda (de_pointer), y ; and get its type
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addrA1 = @ret_addrA-1
   lda #(>@ret_addrA1)
   pha
   lda #(<@ret_addrA1)
   pha
   jmp (@jmp_tbl-2,x) ; -2 because there is nothing to do for component type 0
   ;jmp @ret_addrA
@jmp_tbl:
   .word dummy_sr
   .word dummy_sr
   .word dummy_sr
   .word drag_drag_edit
@ret_addrA:
   ; call panel's drag subroutine, which is part of the interface between GUI and internal data
   lda ms_ref_panel
   asl
   tax
   ; want to emulate a jsr. need to push return address minus 1 to the stack
@ret_addrB1 = @ret_addrB-1
   lda #(>@ret_addrB1)
   pha
   lda #(<@ret_addrB1)
   pha
   jmp (drgs,x)
@ret_addrB:
   rts

; GUI component's drag subroutines
; ---------------------------------
; expect component string's pointer in de_pointer on zero page,
; and also the component's offset in ms_ref_component_ofs (not curr!)
; and whether dragging is done with left or right mouse button in ms_curr_data (left=0, right=1)
; and drag distance compared to previous frame in ms_curr_data2

drag_drag_edit:
   ldy ms_ref_component_ofs
   iny
   iny
   iny
   lda ms_curr_data
   beq @left_drag
   jmp @right_drag
@left_drag:
   ; set coarse drag mode
   lda (de_pointer), y
   and #%11111101
   sta (de_pointer), y
   ; increment
   iny
   iny
   iny
   lda (de_pointer), y
   clc
   adc ms_curr_data2
   sta (de_pointer), y
   bra @update_gui
@right_drag:
   ; set fine drag mode
   lda (de_pointer), y
   ora #%00000010
   sta (de_pointer), y
   ; increment
   iny
   iny
   iny
   iny
   lda (de_pointer), y
   clc
   adc ms_curr_data2
   sta (de_pointer), y
@update_gui:
   ldy ms_ref_component_ofs
   iny
   jsr draw_drag_edit
   rts






; returns the panel index the mouse is currently over. Bit 7 set means none
; panel index returned in ms_curr_panel
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
   ;lda px, y
   ;dec
   ;cmp gp_cx
   ;bcs @loop ; gp_cx is smaller than panel's x
   lda gp_cx
   cmp px, y
   bcc @loop ; gp_cx is smaller than panel's x
   lda px, y
   clc
   adc wd, y
   dec
   cmp gp_cx
   bcc @loop ; gp_cx is too big
   lda gp_cy
   cmp py, y
   bcc @loop ; gp_cy is smaller than panel's y
   lda py, y
   clc
   adc hg, y
   dec
   cmp gp_cy
   bcc @loop ; gp_cy is too big
   ; we're inside! return index
   tya
   sta ms_curr_panel
   rts
@end_loop:
   ; found no match
   lda #255
   sta ms_curr_panel
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
   ; determine mouse position in multiples of 4 pixels (divide by 4)
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
   .word check_drag_edit
@end_gui:
   lda #255 ; none found
   sta ms_curr_component_id
   rts

; component checks (part of mouse_get_component_subroutine)
; ---------------------------------------------------------
; expect ms_curr_panel and gc_pointer to be set, also gc_cx and gc_cy for mouse positions
; and register Y to be at the first "data" position of the component (one past the identifier byte).
; The return procedure is as follows:
; If a click has been registered, the variables 
; ms_curr_component_id, ms_curr_component_ofs and ms_curr_data
; have to be set, and RTS called to exit the check.
; If no click has been registered, JMP check_gui_loop is called to continue checking.
; ms_curr_component_ofs and ms_curr_data are not returned if ms_curr_component's bit 7 is set
; The checks are expected to advance the Y register to the start of the next component, in the case
; that there was no click detected, so the checks can continue with the next component.

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
   iny ; skip data bytes in GUI component string before checking next GUI component
   iny
   iny
   iny
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
   iny
   iny
   cmp (gc_pointer), y
   bcs :+ ; if carry set, no tab has been clicked
   ; otherwise, tab has been selected
   sta ms_curr_data ; store tab being clicked
   tya ; determine component's offset
   sec
   sbc #3 ; correct?
   sta ms_curr_component_ofs
   lda gc_counter
   sta ms_curr_component_id
   rts
:  iny
   iny
   jmp check_gui_loop

; check arrowed edit for mouse click
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
   iny ; X
   cmp #6 ; size of arrowed edit
   bcc :+
   iny ; Y
   iny ; min
   iny ; max
   iny ; val
   jmp check_gui_loop
:  ; correct x range. Now check for click on one of the arrows
   cmp #0 ; arrow to the left
   bne :+
   lda #1
   sta ca_which_arrow
   bra :++
:  cmp #5
   bne :+
   lda #2
   sta ca_which_arrow
:  ; check y direction
   lda gc_cy
   lsr
   cmp (gc_pointer), y
   beq :+ ; only if it's equal
   iny ; Y
   iny ; min
   iny ; max
   iny ; val
   jmp check_gui_loop
:  ; mouse is at correct height
   iny ; Y
   iny ; min
   lda ca_which_arrow
   sta ms_curr_data
   tya ; determine offset in component-string
   sec
   sbc #4 ; correct?
   sta ms_curr_component_ofs
   lda gc_counter
   sta ms_curr_component_id
   rts

; check drag edit for mouse click
check_drag_edit:
   cde_bittest = mzpbg
   ; this is basically an "mouse is inside box" check
   ; with variable width
   ; get edit's options
   iny
   iny
   lda (gc_pointer), y
   dey
   dey
   sta cde_bittest
   ; check x direction
   lda gc_cx
   lsr
   sec
   sbc (gc_pointer), y
   iny
   ; now A must be smaller than the edit's width,
   ; which is, however, dependent on the edit's options.
   ; We first check if it's smaller than the maximally possible width.
   cmp #5
   bcs @exit_from_y
   ; Now we increase A if a smaller option is active, thus making it "harder" to be inside
   ; coarse/fine switch?
   bbs0 cde_bittest, :+
   inc
:  ; signed?
   bbs2 cde_bittest, :+
   inc
:  cmp #5 ; maximal size of drag edit with all options enabled
   bcc :+
   ; we're out
@exit_from_y:
   iny
   iny
   iny
   iny
   iny
   iny
   jmp check_gui_loop
:  ; we're in
   ; check y direction
   lda gc_cy
   lsr
   cmp (gc_pointer), y
   bne @exit_from_y
   ; we're in
   tya
   dec
   dec
   sta ms_curr_component_ofs
   lda gc_counter
   sta ms_curr_component_id
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
   rts

draw_snav:
   ; TODO
   rts

; panels' click subroutines
; -------------------------
; expect ce_pointer to contain the pointer to the corresponding GUI component string
; and mouse variables set according to the click action, that is
; ms_curr_component_id
; ms_curr_component_ofs
; ms_curr_panel
; ms_curr_data

; click subroutine of the global settings panel
click_global:
   rts

; oscillator panel being clicked
click_osc:
   ; tab selector ?
   lda ms_curr_component_id
   cmp #0
   bne :+
   lda ms_curr_data
   sta osc::active_tab
:  rts

; envelope panel being clicked
click_env:
   ; tab selector ?
   lda ms_curr_component_id
   cmp #0
   bne :+
   lda ms_curr_data
   sta env::active_tab
:  rts

click_snav:
   lda ms_curr_component_id
   cmp #0
   beq @timbre_selector
   rts
@timbre_selector:
   ; read data from component string and write it to the Timbre setting
   lda ms_curr_component_ofs
   clc
   adc #5
   tay
   lda (ce_pointer), y
   sta Timbre
   rts

; something on global panel being dragged
drag_global:
   rts

; something on oscillator panel being dragged
drag_osc:
   rts

; something on envelope panel being dragged
drag_env:
   rts

drag_snav:
   rts

.endscope