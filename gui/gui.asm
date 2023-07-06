; Copyright 2021, 2023 Carl Georg Biermann

.include "drag_and_drop/notes.asm"

; This file contains most of the GUI relevant code at the moment.
; It is called mainly by the mouse.asm driver, and sends commands to the guiutils.asm
; to output GUI elements.
; The appearance and behaviour of the GUI is also hard coded in this file.
; The interaction between the GUI and the timbre (and later perhaps song) data
; is currently also done in this file.

; Panels are rectangular areas on the screen that contain basic GUI elements
; like listboxes, checkboxes etc.
; They behave a bit like windows.
; The look and behaviour of all panels are hard coded.
; However, panels can be made visible/invisible individually, and also their order can be changed.
; The order affects which panels appear on top and thus also receive mouse events first.
; This is used to be able to dynamically swap out parts of the GUI, or do things like popup menus.
; The tool for that is a "panel stack" that defines which panels are shown in which order.

; Each panel has multiple byte strings hard coded. Those byte strings define elements shown on the GUI.
;   * one string that defines all interactive GUI components, such as checkboxes, listboxes etc.
;     It is often called "comps", "component string" or something similar.
;     In many subroutines, this component string is given as a zero page pointer together with an offset.
;     Those component strings can inherently only be 256 bytes or shorter.
;   * one string that defines all static labels displaying text. Those are not interactive.
;     It is often called "captions" or something similar.
;     It too can only be 256 bytes or shorter. However, this doesn't include the captions themselves,
;     but only pointers to them.
; Also, some curcial data like position and size and the addresses of aforementioned data blocks are
; stored in arrays that can be accessed via the panel's index.

; The data blocks that contain the data about the GUI components are partially regarded as constant,
; and partially as variable.
; Technically, everything about a component could be changed at runtime. However, e.g. for drag edits,
; only the shown value and the display state (fine or coarse) are intended to be changed at runtime.

; Every panel and every component type have a number of "methods", e.g. every panel and every component
; has a "draw" method. Those methods are registered in various jump-tables across the code, so
; higher-level drawing and event handlers know what to do with each panel and each component.


; Caption List data format:
; first byte: color (foreground and background). If it's zero, it marks the end of the list.
; second and third bytes: x and y position
; fourth and fifth bytes: pointer to a zero-terminated PETSCII string (thus, the symbol "@" cannot be represented)


; *******************************************************************************************
; GUI control element legend with component string format
; 0: none (end of list)
; 1: button, followed by x and y position (absolute), and width, and address of label (16 bit)
; 2: tab selector, followed by x and y position (abs), number of tabs, and active tab
; 3: arrowed edit, followed by x and y position (abs), min value, max value, value
; 4: dragging edit, followed by x and y position (abs), options (flags), min value, max value, coarse value, fine value
; 5: checkbox, followed by x and y position (abs), width, checked boolean
; 6: listbox, followed by x and y position (abs), width, length of stringlist, stringlist pointer (16 bit), selection index
; 7: dummy component, no other data. always registers a click event, so that a panel never misses a click (for popups).
; *******************************************************************************************

; ADDITIONAL INFORMATION ON GUI COMPONENTS
; ****************************************

; BUTTONS are actually height 2, and appear to be one below the position set in the GUI 
; component string. That is, because they have one row of characters above the actual
; text label to make them look nicer.
; However, click detection only recognizes the text label area, that is, one below the specified Y position.

; DRAG EDIT flags options:
; bit 0: coarse/fine option enabled
; bit 1: fine active
; bit 2: signed
; options irrelevant for drawing the component:
; bit 7: zero is forbidden value (for signed scale5 values)

button_data_size = 6
tab_selector_data_size = 5
arrowed_edit_data_size = 6
drag_edit_data_size = 8
checkbox_data_size = 5
listbox_data_size = 8
dummy_data_size = 1




.scope gui

   ; Panel Lookup tables
   ; Each label marks a list of values, one for each panel.
   ; These lists must have length N_PANELS.
   ; X positions
   px: .byte synth_global::px, osc::px, env::px, snav::px, listbox_popup::px, lfo::px, info::px, fm_gen::px, fm_op::px, globalnav::px, clip_edit::px
   ; Y positions
   py: .byte synth_global::py, osc::py, env::py, snav::py, listbox_popup::py, lfo::py, info::py, fm_gen::py, fm_op::py, globalnav::py, clip_edit::py
   ; widths
   wd: .byte synth_global::wd, osc::wd, env::wd, snav::wd, listbox_popup::wd, lfo::wd, info::wd, fm_gen::wd, fm_op::wd, globalnav::wd, clip_edit::wd
   ; heights
   hg: .byte synth_global::hg, osc::hg, env::hg, snav::hg, listbox_popup::hg, lfo::hg, info::hg, fm_gen::hg, fm_op::hg, globalnav::hg, clip_edit::hg
   ; GUI component strings
   comps: .word synth_global::comps, osc::comps, env::comps, snav::comps, listbox_popup::comps, lfo::comps, info::comps, fm_gen::comps, fm_op::comps, globalnav::comps, clip_edit::comps
   ; GUI captions
   capts: .word synth_global::capts, osc::capts, env::capts, snav::capts, listbox_popup::capts, lfo::capts, info::capts, fm_gen::capts, fm_op::capts, globalnav::capts, clip_edit::capts


; The Panel Stack
; defines which panels are drawn in which order, and which panels receive mouse events first.
; The first elements in the stack are at the bottom.
.scope stack
   stack: PANEL_BYTE_FIELD    ; the actual stack, containing the indices of the panels
   sp: .byte 0                ; stack pointer, counts how many elements are on the stack
.endscope

; placeholder for unimplemented/unnecessary subroutines
dummy_sr:
   rts


; brings up the synth GUI
; puts all synth related panels into the GUI stack
load_synth_gui:
   jsr guiutils::cls
   lda #9 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #9 ; global navigation bar
   sta stack::stack+0
   lda #3 ; synth navigation bar
   sta stack::stack+1
   lda #6 ; help/info panel
   sta stack::stack+2
   lda #7 ; FM general settings panel
   sta stack::stack+3
   lda #8 ; FM operator settings panel
   sta stack::stack+4
   lda #0 ; global synth settings panel
   sta stack::stack+5
   lda #1 ; oscillator panel
   sta stack::stack+6
   lda #2 ; envelope panel
   sta stack::stack+7
   lda #5 ; LFO panel
   sta stack::stack+8
   jsr draw_gui
   jsr refresh_gui
   rts


load_clip_gui:
   jsr guiutils::cls
   lda #2 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #9 ; global navigation bar
   sta stack::stack+0
   lda #10 ; clip editing area
   sta stack::stack+1
   rts


load_arrangement_gui:
   jsr guiutils::cls
   lda #1 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #9 ; global navigation bar
   sta stack::stack+0
   rts


; reads through the stack and draws everything
draw_gui:
   dg_counter = mzpbe ; counter variable
   stz dg_counter
@loop:
   ; TODO: clear area on screen (but when exactly is it needed?)
   ; call panel-specific drawing subroutines
   ldy dg_counter
   lda stack::stack, y
   asl
   tax
   INDEXED_JSR @jmp_tbl, @ret_addr
@jmp_tbl:
   .word draw_synth_global
   .word draw_osc
   .word draw_env
   .word draw_snav
   .word draw_lb_popup
   .word draw_lfo
   .word draw_info
   .word draw_fm_gen
   .word draw_fm_op
   .word draw_globalnav
   .word draw_clip_edit
@ret_addr:
   ; draw GUI components
   ldy dg_counter
   lda stack::stack, y
   jsr draw_components
   ; draw captions
   ldy dg_counter
   lda stack::stack, y
   jsr draw_captions
   ; advance in loop
   lda dg_counter
   inc
   cmp stack::sp
   sta dg_counter
   bne @loop
   rts

; draws all captions from the caption string of a panel
; expects panel ID in register A
draw_captions:
   dcp_pointer = mzpwa
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
   INDEXED_JSR (@jmp_tbl-2), @ret_addr ;-2 because there's no drawing routine for "none" component
@jmp_tbl:
   .word draw_button  ; button
   .word draw_tab_select  ; tab-select (no drawing routine, drawing is done in panel-specific routine)
   .word draw_arrowed_edit  ; arrowed edit
   .word draw_drag_edit ; drag edit
   .word draw_checkbox
   .word draw_listbox
   .word dummy_sr  ; since Y is already one past the component's start address, dummy_sr already does all that is expected! :DD
@end_loop:
   rts

; GUI components' drawing routines
; --------------------------------
; expect GUI component string address in dc_pointer, and offset (+1) in register Y
; and are expected to advance register Y to the start (i.e. the identifier) of the next component

draw_button:
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   lda (dc_pointer), y
   sta guiutils::draw_width
   iny
   lda (dc_pointer), y
   sta guiutils::str_pointer
   iny
   lda (dc_pointer), y
   sta guiutils::str_pointer+1
   iny
   phy
   jsr guiutils::draw_button
   ply
   rts

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

draw_checkbox:
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   iny
   lda (dc_pointer), y
   sta guiutils::draw_data1
   phy
   jsr guiutils::draw_checkbox
   ply
   iny
   rts

draw_listbox:
   dlb_strp = guiutils::str_pointer
   lda (dc_pointer), y
   sta guiutils::draw_x
   iny
   lda (dc_pointer), y
   sta guiutils::draw_y
   iny
   lda (dc_pointer), y
   sta guiutils::draw_width
   iny
   iny
   ; now determine the label of the selected option
   lda (dc_pointer), y
   sta dlb_strp
   iny
   lda (dc_pointer), y
   sta dlb_strp+1
   iny
   lda (dc_pointer), y  ; put index of selected option in X
   tax
   iny
   phy
   ldy #0
   ; advance as long as X > 0
@loop:
   dex
   bmi @end_loop
@loop2:
   iny  ; having iny before reading the byte cannot cope with empty strings! It assumes the string has at least length 1
   lda (dlb_strp), y
   bne @loop2
   iny
   bra @loop
@end_loop:
   ; now (dlb_strp+y) is the starting address of selected label
   ; compute starting address and store put it into the string pointer
   tya
   clc
   adc dlb_strp
   sta guiutils::str_pointer
   lda dlb_strp+1
   adc #0
   sta guiutils::str_pointer+1
   jsr guiutils::draw_listbox
   ply
   rts





; click event. looks in mouse variables which panel has been clicked and calls its routine
; also looks which component has been clicked and calls according routine
click_event:
   ; call GUI component's click subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   ce_pointer = mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   ; put GUI component string pointer to ZP
   stz mouse_state::gui_write
   lda mouse_state::curr_panel
   asl
   tax
   lda comps, x
   sta ce_pointer
   lda comps+1, x
   sta ce_pointer+1
   ldy mouse_state::curr_component_ofs ; load component's offset
   lda (ce_pointer), y ; and get its type
   asl
   tax
   INDEXED_JSR (@jmp_tblA-2), @ret_addrA ; -2 because there is nothing to do for component type 0
@jmp_tblA:
   .word click_button
   .word click_tab_select
   .word click_arrowed_edit
   .word dummy_sr ; drag edit - no click event necessary
   .word click_checkbox
   .word click_listbox
   .word click_dummy
@ret_addrA:
   ; check if component wants an update
   lda mouse_state::gui_write
   bne :+
   rts
:  ; call panel's writing subroutine, which is part of the interface between GUI and internal data
   lda mouse_state::curr_panel
   asl
   tax
   INDEXED_JSR panel_write_subroutines, @ret_addrB
@ret_addrB:
   rts  ; we could actually leave the jsr away and just jmp to the subroutine... but I'll leave it for now. Optimizations later...

; GUI component's click subroutines
; ---------------------------------
; expect component string's pointer in ce_pointer on zero page,
; and also the component's offset in mouse_state::curr_component_ofs
; and relevant click data (determined by the click detection) in mouse_state::curr_data_1

click_button:
   ; register the click to trigger a write_...
   inc mouse_state::gui_write
   ; nothing else to be done here. click events are handled inside the panels'
   ; write_... subroutines, because they can identify individual buttons and know
   ; what actions to perform.
   rts

click_tab_select:
   inc mouse_state::gui_write
   ; put new tab into GUI component list
   lda mouse_state::curr_data_1
   ldy mouse_state::curr_component_ofs
   iny
   iny
   iny
   iny
   sta (ce_pointer), y
   ; and redraw it
   ldy mouse_state::curr_component_ofs
   iny
   jsr draw_tab_select
   rts

click_arrowed_edit:
   cae_value = mzpbe
   ; check if one of the arrows has been clicked
   lda mouse_state::curr_data_1
   bne :+
   rts
:  ; yes, one of the arrows has been clicked...
   inc mouse_state::gui_write ; register a change on the GUI
   ; now, get value from edit
   lda mouse_state::curr_component_ofs
   clc
   adc #5
   tay
   lda (ce_pointer), y
   sta cae_value
   ; now, decide whether left or right was clicked
   dey
   lda mouse_state::curr_data_1
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
   bra @update_gui
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
@update_gui:
   ldy mouse_state::curr_component_ofs
   iny
   jsr draw_arrowed_edit
   rts

click_checkbox:
   inc mouse_state::gui_write ; register a change on the GUI
   ldy mouse_state::curr_component_ofs
   iny
   iny
   iny
   iny
   lda (ce_pointer), y
   beq @tick
@untick:
   lda #0
   sta (ce_pointer), y
   bra @update_gui
@tick:
   lda #1
   sta (ce_pointer), y
@update_gui:
   ldy mouse_state::curr_component_ofs
   iny
   jsr draw_checkbox
   rts

click_listbox:
   ; we don't activate mouse_state::gui_write, because the first click on the listbox
   ; doesn't change any actual data,
   ; bring up popup panel
   ; TODO: later we would need to calculate the popup position based on the listbox position
   ; and a possibly oversized popup (so that it would range beyond the screen)
   ; We'll deal with that as soon as this becomes an issue.
   ; For now, we'll just directly place it where we want it.
   ldy mouse_state::curr_component_ofs
   iny
   lda (ce_pointer), y
   sta listbox_popup::box_x
   iny
   lda (ce_pointer), y
   inc ; we'll see where exactly we want the popup (TODO)
   sta listbox_popup::box_y
   ; load additional info into popup panel data
   iny 
   lda (ce_pointer), y
   sta listbox_popup::box_width
   iny 
   lda (ce_pointer), y
   sta listbox_popup::box_height
   iny
   lda (ce_pointer), y
   sta listbox_popup::strlist
   iny
   lda (ce_pointer), y
   sta listbox_popup::strlist+1
   lda mouse_state::curr_component_ofs
   sta listbox_popup::lb_ofs
   lda ce_pointer
   sta listbox_popup::lb_addr
   lda ce_pointer+1
   sta listbox_popup::lb_addr+1
   lda mouse_state::prev_component_id
   sta listbox_popup::lb_id
   lda mouse_state::curr_panel
   sta listbox_popup::lb_panel
   ; now do the GUI stack stuff
   ldx stack::sp
   lda #4
   sta stack::stack, x
   inc stack::sp
@update_gui:
   jsr draw_lb_popup
   rts

click_dummy:
   inc mouse_state::gui_write
   rts


; drag event. looks in mouse variables which panel's component has been dragged and calls its routine
; expects L/R information in mouse_state::curr_data_1 (0 for left drag, 1 for right drag)
; and dragging distance in mouse_state::curr_data_2
drag_event:
   ; call GUI component's drag subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   de_pointer = mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   stz mouse_state::gui_write
   lda mouse_state::curr_panel
   asl
   tax
   lda comps, x
   sta de_pointer
   lda comps+1, x
   sta de_pointer+1   ; put GUI component string pointer to ZP
   ldy mouse_state::curr_component_ofs ; load component's offset
   lda (de_pointer), y ; and get its type
   asl
   tax
   INDEXED_JSR @jmp_tblA-2, @ret_addrA ; -2 because there's nothing needed for none component type (0)
@jmp_tblA:
   .word dummy_sr
   .word dummy_sr
   .word dummy_sr
   .word drag_drag_edit
   .word dummy_sr
   .word dummy_sr
   .word dummy_sr
@ret_addrA:
   ; check if component wants an update
   lda mouse_state::gui_write
   bne :+
   rts
:  ; call panel's drag subroutine, which is part of the interface between GUI and internal data
   lda mouse_state::curr_panel
   asl
   tax
   INDEXED_JSR panel_write_subroutines, @ret_addrB
@ret_addrB:
   rts  ; we could leave that away and just jmp to the subroutines instead of jsr, but optimizations later.

; GUI component's drag subroutines
; ---------------------------------
; expect component string's pointer in de_pointer on zero page,
; and also the component's offset in mouse_state::prev_component_ofs (not curr!)
; and whether dragging is done with left or right mouse button in mouse_state::curr_data_1 (left=0, right=1)
; and drag distance compared to previous frame in mouse_state::curr_data_2

drag_drag_edit:
   inc mouse_state::gui_write
   ; first check if drag edit has fine editing enabled
   ldy mouse_state::prev_component_ofs
   iny
   iny
   iny
   lda (de_pointer), y
   and #%00000001
   beq @coarse_drag  ; if there is no fine editing enabled, we jump straight to coarse editing
   ; check mouse for fine or coarse dragging mode
   lda mouse_state::curr_data_1
   beq @coarse_drag
   jmp @fine_drag
@coarse_drag:
   ; set coarse drag mode
   lda (de_pointer), y
   pha
   and #%11111101
   sta (de_pointer), y
   ; prepare the increment
   iny
   iny
   ; check if dragging up or down
   lda mouse_state::curr_data_2
   bmi @coarse_drag_down
@coarse_drag_up:
   ; check if adding the increment crosses the border
   lda (de_pointer), y ; load max value, and then subtract current value from it
   iny
   sec
   sbc (de_pointer), y ; now we have the distance to the upper border in the accumulator
   sec
   sbc mouse_state::curr_data_2 ; if this overflowed, we are crossing the border
   bcc @coarse_up_overflow
@coarse_up_normal:
   lda (de_pointer), y
   clc
   adc mouse_state::curr_data_2
   sta (de_pointer), y
   ; check if zero forbidden
   pla
   bpl :+
   ; if we're here, zero is forbidden -> check if we are at zero
   lda (de_pointer), y
   bne :+
   ; if we are here, we are at zero. Since we are dragging up, simply increment one
   lda #1
   sta (de_pointer), y
:  bra @update_gui
@coarse_up_overflow:
   ; on overflow, simply put the maximal value into the edit
   dey
   lda (de_pointer), y
   iny
   sta (de_pointer), y
   pla ; pull options byte
   bra @update_gui
@coarse_drag_down:
   ; check if adding the increment crosses the min value
   iny
   lda (de_pointer), y ; load current value, and then subtract min value from it
   dey
   dey
   sec
   sbc (de_pointer), y ; now we have the distance to the min value in the accumulator
   clc
   adc mouse_state::curr_data_2 ; if the result is negative, we are crossing the border
   bcc @coarse_down_overflow
@coarse_down_normal:
   iny
   iny
   lda (de_pointer), y
   clc
   adc mouse_state::curr_data_2
   sta (de_pointer), y
   ; check if zero forbidden
   pla
   bpl :+
   ; if we're here, zero is forbidden -> check if we are at zero
   lda (de_pointer), y
   bne :+
   ; if we are here, we are at zero. Since we are dragging down, simply decrement one
   lda #255
   sta (de_pointer), y
:  bra @update_gui
@coarse_down_overflow:
   ; if overflow occurs, simply put minimal value into edit
   lda (de_pointer), y
   iny
   iny
   sta (de_pointer), y
   pla ; pull options byte
   bra @update_gui
; 4: dragging edit, followed by x and y position (abs), options (flags), min value, max value, coarse value, fine value
@fine_drag:
   ; set fine drag mode
   lda (de_pointer), y
   ora #%00000010
   sta (de_pointer), y
   ; prepare the increment
   iny
   iny
   iny
   iny
   ; check if dragging up or down
   lda mouse_state::curr_data_2
   bmi @fine_drag_down
@fine_drag_up:
   ; check if adding the increment crosses the border
   lda #255 ; load max value, and then subtract current value from it
   sec
   sbc (de_pointer), y ; now we have the distance to the upper border in the accumulator
   sec
   sbc mouse_state::curr_data_2 ; if this overflowed, we are crossing the border
   bcc @fine_up_overflow
@fine_up_normal:
   lda (de_pointer), y
   clc
   adc mouse_state::curr_data_2
   sta (de_pointer), y
   bra @update_gui
@fine_up_overflow:
   ; on overflow, simply put the maximal value into the edit
   lda #255
   sta (de_pointer), y
   bra @update_gui
@fine_drag_down:
   ; check if adding the increment crosses the min value
   lda (de_pointer), y ; load current value
   clc
   adc mouse_state::curr_data_2 ; if overflow occurs, we are crossing the border
   bcc @fine_down_overflow
@fine_down_normal:
   lda (de_pointer), y
   clc
   adc mouse_state::curr_data_2
   sta (de_pointer), y
   bra @update_gui
@fine_down_overflow:
   ; if overflow occurs, simply put minimal value into edit
   lda #0
   sta (de_pointer), y
   bra @update_gui
@update_gui:
   ldy mouse_state::prev_component_ofs
   iny
   jsr draw_drag_edit
   rts


; goes through the stack of active GUI panels and refreshes every one of them
refresh_gui:
   rfg_counter = mzpbe ; counter variable
   stz rfg_counter
@loop:
   ; call panel-specific drawing subroutine
   ldy rfg_counter
   lda stack::stack, y
   asl
   tax
   INDEXED_JSR @jmp_tbl, @ret_addr
@jmp_tbl:
   .word refresh_synth_global
   .word refresh_osc
   .word refresh_env
   .word refresh_snav
   .word dummy_sr   ; listbox popup ... popups don't need to be refreshed
   .word refresh_lfo
   .word dummy_sr   ; info box - no refresh necessary yet
   .word refresh_fm_gen
   .word refresh_fm_op
   .word dummy_sr  ; globalnav - no refresh necessary
   .word refresh_clip_edit
@ret_addr:
   ; advance in loop
   lda rfg_counter
   inc
   cmp stack::sp
   sta rfg_counter
   bne @loop
   rts







; returns the panel index the mouse is currently over. Bit 7 set means none
; panel index returned in mouse_state::curr_panel
mouse_get_panel:
   ; grab those zero page variables for this routine
   gp_cx = mzpwa
   gp_cy = mzpwd
   ; determine position in characters (divide by 8)
   lda mouse_state::curr_x+1
   lsr
   sta gp_cx+1
   lda mouse_state::curr_x
   ror
   sta gp_cx
   lda gp_cx+1
   lsr
   ror gp_cx
   lsr
   ror gp_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda mouse_state::curr_y+1
   lsr
   sta gp_cy+1
   lda mouse_state::curr_y
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
   sta mouse_state::curr_panel
   rts
@end_loop:
   ; found no match
   lda #255
   sta mouse_state::curr_panel
   rts



; given the panel, where the mouse is currently at,
; this subroutine finds which GUI component is being clicked
mouse_get_component:
   ; panel number in mouse_state::curr_panel
   ; mouse x and y coordinates in mouse_state::curr_x and mouse_state::curr_y
   ; zero page variables:
   gc_pointer = mzpwa
   gc_cx = mzpwd     ; x and y in multiples of 4 (!) pixels to support half character grid
   gc_cy = mzpwd+1
   gc_counter = mzpbe
   ; determine mouse position in multiples of 4 pixels (divide by 4)
   lda mouse_state::curr_x+1
   lsr
   sta gc_cx+1
   lda mouse_state::curr_x
   ror
   sta gc_cx
   lda gc_cx+1
   lsr
   ror gc_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda mouse_state::curr_y+1
   lsr
   sta gc_cy+1
   lda mouse_state::curr_y
   ror
   sta gc_cy
   lda gc_cy+1
   lsr
   ror gc_cy
   ; copy pointer to component string to ZP
   lda mouse_state::curr_panel
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
   .word check_checkbox
   .word check_listbox
   .word check_dummy
@end_gui:
   lda #255 ; none found
   sta mouse_state::curr_component_id
   rts

; component checks (part of mouse_get_component subroutine)
; ---------------------------------------------------------
; These routines check whether the mouse is over the specified GUI component, and,
; in case it is, even return additional information, like e.g. which tab has been clicked.
; These routines are not independent, but are part of the above mouse_get_component subroutine.
; The mouse coordinates are given in 4 pixel multiples.
; These routines expect mouse_state::curr_panel and gc_pointer to be set, also gc_cx and gc_cy for mouse positions
; and register Y to be at the first "data" position of the component (one past the identifier byte).
; The return procedure is as follows:
; * If a click has been registered, the variables 
;   mouse_state::curr_component_id, mouse_state::curr_component_ofs and mouse_state::curr_data_1
;   have to be set, and RTS called to exit the check.
; * If no click has been registered, JMP check_gui_loop is called to continue checking.
;   mouse_state::curr_component_ofs and mouse_state::curr_data_1 are not returned if ms_curr_component's bit 7 is set
;   The checks are expected to advance the Y register to the start of the next component, in the case
;   that there was no click detected, so the checks can continue with the next component.

check_button:
   ; check if mouse is over the button
   ; this code is nearly identical to the check_checkbox bit,
   ; apart from the number of INYs required, and the different Y position (off by 1)
   cb_width = mzpbf
   ; this is basically an "mouse is inside box" check
   ; with variable width
   ; get the width of the checkbox
   iny
   iny
   lda (gc_pointer), y
   sta cb_width
   dey
   dey
   ; check x direction
   lda gc_cx
   lsr
   sec
   sbc (gc_pointer), y ; now we have the distance of the mouse pointer to the left side of the checkbox
   iny
   ; now A must be smaller than the checkbox' width.
   cmp cb_width
   bcs @exit_from_y
   bra :+
   ; we're out
@exit_from_y:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position data
   iny
   iny
   iny
   iny
   jmp check_gui_loop
:  ; we're in
   ; check y direction
   lda gc_cy
   lsr
   dec ; this is to make up for the button actually being in the line below
   cmp (gc_pointer), y
   bne @exit_from_y
   ; we're in
   tya
   dec
   dec
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts

; which tab clicked is returned in mouse_state::curr_data_1
check_tab_selector:
   ; check if mouse is over the tab selector area of the panel
   ; check x direction first
   ldx mouse_state::curr_panel
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
   sta mouse_state::curr_data_1 ; store tab being clicked
   tya ; determine component's offset
   sec
   sbc #3 ; correct?
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts
:  iny
   iny
   jmp check_gui_loop

; check arrowed edit for mouse click
; which arrow clicked is returned in mouse_state::curr_data_1
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
   sta mouse_state::curr_data_1
   tya ; determine offset in component-string
   sec
   sbc #4 ; correct?
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts

; check drag edit for mouse click
check_drag_edit:
   cde_bittest = mzpbf
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
@exit_from_y:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position
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
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts

check_checkbox:
   ccb_width = mzpbf
   ; this is basically an "mouse is inside box" check
   ; with variable width
   ; get the width of the checkbox
   iny
   iny
   lda (gc_pointer), y
   sta ccb_width
   dey
   dey
   ; check x direction
   lda gc_cx
   lsr
   sec
   sbc (gc_pointer), y ; now we have the distance of the mouse pointer to the left side of the checkbox
   iny
   ; now A must be smaller than the checkbox' width.
   cmp ccb_width
   bcs @exit_from_y
   bra :+
   ; we're out
@exit_from_y:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position data
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
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts

; listbox check is identical to checkbox check, apart from the number of INYs needed at the end
; actually, we should reuse this code!
; need some sort of universal "mouse is on line Y and within X range" test
check_listbox:
   clb_width = mzpbf
   ; this is basically an "mouse is inside box" check
   ; with variable width
   ; get the width of the listbox
   iny
   iny
   lda (gc_pointer), y
   sta clb_width
   dey
   dey
   ; check x direction
   lda gc_cx
   lsr
   sec
   sbc (gc_pointer), y ; now we have the distance of the mouse pointer to the left side of the checkbox
   iny
   ; now A must be smaller than the checkbox' width.
   cmp clb_width
   bcs @exit_from_y
   bra :+
   ; we're out
@exit_from_y:   ; "from y" refers to the Y register being at the position of the y coordinate of the component's position data
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
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts

; dummy always registers a click event, regardless of where the mouse is. Useful for popups.
check_dummy:
   ; get mouse coordinates (in 8 pixel multiples) and put them into data
   lda gc_cx
   lsr
   sta mouse_state::curr_data_1
   lda gc_cy
   lsr
   sta mouse_state::curr_data_2
   dey
   tya
   sta mouse_state::curr_component_ofs
   lda gc_counter
   sta mouse_state::curr_component_id
   rts



; PANEL SPECIFIC STUFF
; --------------------

; panel drawing subroutines
; -------------------------
; These subroutines draw stuff that is very specific to each panel, and is not covered
; by the component and label lists.
; They don't depend on anything other than the individual panel variables.

draw_synth_global:
   ; draw panel
   lda #synth_global::px
   sta guiutils::draw_x
   lda #synth_global::py
   sta guiutils::draw_y
   lda #synth_global::wd
   sta guiutils::draw_width
   lda #synth_global::hg
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
   ; TODO - nothing to be done yet?
   rts

draw_lb_popup:
   dlbp_pointer = mzpwd
   lda listbox_popup::box_x
   sta guiutils::draw_x
   lda listbox_popup::box_y
   sta guiutils::draw_y
   lda listbox_popup::box_width
   sta guiutils::draw_width
   lda listbox_popup::box_height
   sta guiutils::draw_height
   lda listbox_popup::strlist
   sta guiutils::str_pointer
   lda listbox_popup::strlist+1
   sta guiutils::str_pointer+1
   jsr guiutils::draw_lb_popup
   rts

draw_lfo:
   ; draw panel
   lda #lfo::px
   sta guiutils::draw_x
   lda #lfo::py
   sta guiutils::draw_y
   lda #lfo::wd
   sta guiutils::draw_width
   lda #lfo::hg
   sta guiutils::draw_height
   lda #0
   sta guiutils::draw_data1
   jsr guiutils::draw_frame
   rts

draw_info:
   ; draw frame
   lda #info::px
   sta guiutils::draw_x
   lda #info::py
   sta guiutils::draw_y
   lda #info::wd
   sta guiutils::draw_width
   lda #info::hg
   sta guiutils::draw_height
   lda #0
   sta guiutils::draw_data1
   jsr guiutils::draw_frame
   rts

draw_fm_gen:
   ; draw frame
   lda #fm_gen::px
   sta guiutils::draw_x
   lda #fm_gen::py
   sta guiutils::draw_y
   lda #fm_gen::wd
   sta guiutils::draw_width
   lda #fm_gen::hg
   sta guiutils::draw_height
   lda #0
   sta guiutils::draw_data1
   jsr guiutils::draw_frame
   rts

draw_fm_op:
   ; draw frame
   lda #fm_op::px
   sta guiutils::draw_x
   lda #fm_op::py
   sta guiutils::draw_y
   lda #fm_op::wd
   sta guiutils::draw_width
   lda #fm_op::hg
   sta guiutils::draw_height
   lda #N_OPERATORS
   sta guiutils::draw_data1
   lda fm_op::active_tab
   inc
   sta guiutils::draw_data2
   jsr guiutils::draw_frame
   rts

draw_globalnav:
   lda globalnav::active_tab
   sta guiutils::draw_data1
   jsr guiutils::draw_globalnav
   rts

draw_clip_edit:
   ; load dummy arguments for now
   lda clip_edit::time_stamp
   sta notes::argument_x
   lda clip_edit::time_stamp+1
   sta notes::argument_x+1
   lda clip_edit::low_note
   sta notes::argument_y
   lda clip_edit::zoom_level
   sta notes::argument_z
   ; event vectors are set by setup_test_clip (and we never touch them elsewhere)
   jsr notes::draw_events
   rts



; utility subroutines
; -------------------

; on the GUI, "no modulation source" is 0, but in the synth engine, it is 128 (bit 7 set)
; The following two routines map between those two formats.
map_modsource_from_gui:
   cmp #0
   beq :+
   dec
   rts
:  lda #128
   rts

map_modsource_to_gui:
   cmp #0
   bmi :+
   inc
   rts
:  lda #0
   rts

; this is for the modulation depths
map_twos_complement_to_signed_7bit:
   cmp #0
   bpl @done
   eor #%01111111
   inc
@done:
   rts

map_signed_7bit_to_twos_complement:
   cmp #0
   bpl @done
   dec
   eor #%01111111
@done:
   rts


; panels' write subroutines
; -------------------------
; These subroutines are called when a GUI component has been changed by the user.
; It reads the value from the component and writes it into the timbre (or later song) data.
; They expect wr_pointer to contain the pointer to the corresponding GUI component string
; and the mouse variables set according to the action, that is
; mouse_state::prev_component_id
; mouse_state::prev_component_ofs

; jump table
panel_write_subroutines:
   .word write_synth_global
   .word write_osc
   .word write_env
   .word write_snav
   .word write_lb_popup
   .word write_lfo
   .word dummy_sr ; info box - nothing to edit here
   .word write_fm_gen
   .word write_fm_op
   .word write_globalnav
   .word write_clip_edit

dummy_plx:
   plx
   rts


; subroutine of the global synth settings panel
write_synth_global:
   ldx Timbre ; may be replaced later
   lda mouse_state::curr_component_ofs
   clc
   adc #4
   tay ; there's no component type where the data is before this index
   ; now jump to component which has been clicked/dragged
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @n_oscs
   .word @n_envs
   .word @n_lfos
   .word @retr_activate
   .word @porta_activate
   .word @porta_rate
   .word @vibrato_amount
@n_oscs:
   phy
   jsr concerto_synth::voices::panic ; If we don't do this, a different number of oscillators might be released than initially acquired by a voice. Safety first.
   ply
   plx
   iny
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::n_oscs, x
   rts
@n_envs:
   plx
   iny
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::n_envs, x
   rts
@n_lfos:
   plx
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::n_lfos, x
   rts
@retr_activate:
   plx
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::retrig, x
   rts
@porta_activate:
   plx
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::porta, x
   rts
@porta_rate:
   plx
   iny
   iny
   lda synth_global::comps, y
   sta concerto_synth::timbres::Timbre::porta_r, x
   rts
@vibrato_amount:
   plx
   iny
   iny
   lda synth_global::comps, y ; if this value is 0, that means vibrato off, which is represented as a negative value internally
   beq :+
   jsr concerto_synth::map_twos_complement_to_scale5
   sta concerto_synth::timbres::Timbre::vibrato, x
   rts
:  lda #$FF
   sta concerto_synth::timbres::Timbre::vibrato, x
   rts


; oscillator panel being changed
write_osc:
   ; first, determine the offset of the oscillator in the Timbre data
   lda Timbre ; may be replaced later
   ldx osc::active_tab ; envelope number
@loop:
   cpx #0
   beq @end_loop
   clc
   adc #N_TIMBRES
   dex
   bra @loop
@end_loop:
   tax ; oscillator index is in x
   ; prepare component readout
   lda mouse_state::curr_component_ofs
   clc
   adc #4
   tay ; there's no component type where the data is before this index
   ; now determine which component has been changed
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @tab_slector
   .word @waveform
   .word @pulsewidth ; pulse width
   .word @ampsel ; amp listbox
   .word @volume ; oscillator volume
   .word @channelsel ; L/R select
   .word @semitones
   .word @finetune
   .word @keytrack
   .word @pmsel1 ; pitch mod select 1
   .word @pmsel2 ; pitch mod select 2
   .word @pwmsel ; pw mod select
   .word @volmsel ; vol mod select
   .word @pitchmoddep1 ; pitch mod depth 1
   .word @pitchmoddep2 ; pitch mod depth 2
   .word @pwmdep ; pw mod depth
   .word @vmdep ; vol mod depth
@tab_slector:
   plx
   lda mouse_state::curr_data_1
   sta osc::active_tab
   jsr refresh_osc
   rts
@waveform:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   clc
   ror
   ror
   ror
   sta concerto_synth::timbres::Timbre::osc::waveform, x
   rts
@pulsewidth:
   plx
   iny
   iny
   lda osc::comps, y
   sta concerto_synth::timbres::Timbre::osc::pulse, x
   rts
@ampsel:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   sta concerto_synth::timbres::Timbre::osc::amp_sel, x
   rts
@volume:
   plx
   iny
   iny
   lda osc::comps, y
   sta concerto_synth::timbres::Timbre::osc::volume, x
   rts
@channelsel:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   clc
   ror
   ror
   ror
   sta concerto_synth::timbres::Timbre::osc::lrmid, x
   rts
@semitones:
   plx
   iny
   iny
   ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
   lda concerto_synth::timbres::Timbre::osc::fine, x
   bmi :+
   lda osc::comps, y
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   rts
:  lda osc::comps, y
   dec
   sta concerto_synth::timbres::Timbre::osc::pitch, x
   rts
@finetune:
   plx
   iny
   iny
   ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
   ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
   lda concerto_synth::timbres::Timbre::osc::fine, x
   bmi @fine_negative
@fine_positive:
   lda osc::comps, y
   bpl @fine_normal
   dec concerto_synth::timbres::Timbre::osc::pitch, x
   bra @fine_normal
@fine_negative:
   lda osc::comps, y
   bmi @fine_normal
   inc concerto_synth::timbres::Timbre::osc::pitch, x
@fine_normal:
   sta concerto_synth::timbres::Timbre::osc::fine, x
   rts
@keytrack:
   plx
   lda osc::comps, y
   sta concerto_synth::timbres::Timbre::osc::track, x
   rts
@pmsel1:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   jsr map_modsource_from_gui
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   rts
@pmsel2:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   jsr map_modsource_from_gui
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   rts
@pwmsel:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   jsr map_modsource_from_gui
   sta concerto_synth::timbres::Timbre::osc::pwm_sel, x
   rts
@volmsel:
   plx
   iny
   iny
   iny
   lda osc::comps, y
   jsr map_modsource_from_gui
   sta concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   rts
@pitchmoddep1:
   plx
   iny
   iny
   lda osc::comps, y
   jsr concerto_synth::map_twos_complement_to_scale5
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   rts
@pitchmoddep2:
   plx
   iny
   iny
   lda osc::comps, y
   jsr concerto_synth::map_twos_complement_to_scale5
   sta concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   rts
@pwmdep:
   plx
   iny
   iny
   lda osc::comps, y
   jsr map_twos_complement_to_signed_7bit
   sta concerto_synth::timbres::Timbre::osc::pwm_dep, x
   rts
@vmdep:
   plx
   iny
   iny
   lda osc::comps, y
   jsr map_twos_complement_to_signed_7bit
   sta concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   rts

; something on envelope panel being changed
write_env:
   ; first, determine the offset of the envelope in the Timbre data
   lda Timbre ; may be replaced later
   ldx env::active_tab ; envelope number
@loop:
   cpx #0
   beq @end_loop
   clc
   adc #N_TIMBRES
   dex
   bra @loop
@end_loop:
   tax ; envelope index is in x
   ; prepare drag edit readout
   lda mouse_state::curr_component_ofs
   clc
   adc #6 ; 6 because most of the control elements are drag edits anyway
   tay ; drag edit's coarse value offset is in Y
   ; now determine which component has been dragged
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @tab_select
   .word @attack
   .word @decay
   .word @sustain
   .word @release
@tab_select:
   plx
   lda mouse_state::curr_data_1
   sta env::active_tab
   jsr refresh_env
   rts
@attack:
   plx
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::attackH, x
   iny
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::attackL, x
   rts
@decay:
   plx
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::decayH, x
   iny
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::decayL, x
   rts
@sustain:
   plx
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::sustain, x
   rts
@release:
   plx
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::releaseH, x
   iny
   lda env::comps, y
   sta concerto_synth::timbres::Timbre::env::releaseL, x
   rts
@skip:
   plx
   rts


write_snav:
   ; prepare component string offset
   lda mouse_state::curr_component_ofs
   clc
   adc #5 ; currently, we're reading only arrowed edits and drag edits
   tay
   ; prepare jump
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @timbre_selector
   .word @load_preset
   .word @save_preset
   .word @copy_preset
   .word @paste_preset
   .word @change_file_name
   .word @set_play_volume
   .word @load_bank
   .word @save_bank
@timbre_selector:
   ; read data from component string and write it to the Timbre setting
   lda snav::comps, y
   sta Timbre
   jsr refresh_gui
   rts
@load_preset:
   sei
   jsr concerto_synth::voices::panic
   ldx Timbre
   jsr concerto_synth::timbres::load_timbre
   jsr refresh_gui
   cli
   rts
@save_preset:
   ldx Timbre
   jsr concerto_synth::timbres::save_timbre
   rts
@copy_preset:
   lda Timbre
   sta concerto_synth::timbres::copying
   rts
@paste_preset:
   sei
   jsr concerto_synth::voices::panic
   ldx Timbre
   jsr concerto_synth::timbres::copy_paste
   jsr refresh_gui
   cli
   rts
@change_file_name:
   ; clear string
   ;ldy #MAX_FILENAME_LENGTH
   ;lda #' '
;:  sta concerto_synth::timbres::file_name,y
   ;dey
   ;bpl :-
   ; do input string
   lda #snav::ti_x
   sta r2L
   lda #snav::ti_y
   sta r2H
   lda #<concerto_synth::timbres::file_name
   sta r0L
   lda #>concerto_synth::timbres::file_name
   sta r0H
   ldx #CCOLOR_CAPTION
   ldy #MAX_FILENAME_LENGTH
   jsr guiutils::vtui_input_str
   rts
@set_play_volume:
   iny
   lda snav::comps, y
   sta play_volume
   rts
@load_bank:
   sei
   jsr concerto_synth::voices::panic
   jsr concerto_synth::timbres::load_bank
   jsr refresh_gui
   cli
   rts
@save_bank:
   jsr concerto_synth::timbres::save_bank
   rts

; since there is only the dummy component on the popup,
; this subroutine doesn't have to deal with components, but it interprets the click event itself
write_lb_popup:
   clbp_pointer = mzpwa ; mzpwa is already used in the click_event routine, but once we get to this point, it should have served its purpose, so we can reuse it here.
   ; TODO: determine selection (or skip if none was selected)
   ; mouse coordinates are in mouse_state::curr_data_1 and mouse_state::curr_data_2 (been put there by the dummy GUI component)
   ; check if we're in correct x range
   lda mouse_state::curr_data_1
   sec
   sbc listbox_popup::box_x
   cmp listbox_popup::box_width
   bcs @close_popup
   ; we're inside!
   ; check if we're in correct y range
   lda mouse_state::curr_data_2
   sec
   sbc listbox_popup::box_y
   cmp listbox_popup::box_height
   bcs @close_popup
   ; we're inside!
   ; now the accumulator holds the new selection index. Put it back into the listbox.
   pha
   lda listbox_popup::lb_addr
   sta clbp_pointer
   lda listbox_popup::lb_addr+1
   sta clbp_pointer+1
   lda listbox_popup::lb_ofs
   clc
   adc #7
   tay
   pla
   sta (clbp_pointer), y
@close_popup:
   ; one thing that always happens, is that the popup is closed upon clicking.
   ; close popup
   dec stack::sp
   ; clear area where the popup has been before
   ; jsr guiutils::cls ; would be the cheap solution
   lda listbox_popup::box_x
   sta guiutils::draw_x
   lda listbox_popup::box_y
   sta guiutils::draw_y
   lda listbox_popup::box_width
   sta guiutils::draw_width
   lda listbox_popup::box_height
   sta guiutils::draw_height
   jsr guiutils::clear_lb_popup
   ; call writing function of panel
   lda listbox_popup::lb_ofs
   sta mouse_state::curr_component_ofs
   lda listbox_popup::lb_id
   sta mouse_state::curr_component_id
   lda listbox_popup::lb_panel
   asl
   tax
   INDEXED_JSR panel_write_subroutines, @ret_addr
@ret_addr:
   ; redraw gui
   jsr draw_gui
   rts

; LFO panel being changed
write_lfo:
   ldx Timbre ; may be replaced later
   lda mouse_state::curr_component_ofs
   clc
   adc #4
   tay ; there's no component type where the data is before this index
   ; now determine which component has been dragged
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @wave
   .word @retr
   .word @rate
   .word @offs
@wave:
   plx
   iny
   iny
   iny
   lda lfo::comps, y
   sta concerto_synth::timbres::Timbre::lfo::wave, x
   rts
@retr:
   plx
   lda lfo::comps, y
   sta concerto_synth::timbres::Timbre::lfo::retrig, x
   rts
@rate:
   plx
   iny
   iny
   lda lfo::comps, y
   sta concerto_synth::timbres::Timbre::lfo::rateH, x
   iny
   lda lfo::comps, y
   sta concerto_synth::timbres::Timbre::lfo::rateL, x
   rts
@offs:
   plx
   iny
   iny
   lda lfo::comps, y
   sta concerto_synth::timbres::Timbre::lfo::offs, x
   rts

write_fm_gen:
   wfm_bits = mzpbe
   ; invalidate all FM timbres that have been loaded onto the YM2151 (i.e. enforce reload after timbre has been changed)
   jsr concerto_synth::voices::panic
   jsr concerto_synth::voices::invalidate_fm_timbres
   ; do the usual stuff
   ldx Timbre
   lda mouse_state::curr_component_ofs
   clc
   adc #4
   tay ; there's no component type where the data is before this index
   ; now determine which component has been dragged
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @connection
   .word @feedback
   .word @op1_active
   .word @op2_active
   .word @op3_active
   .word @op4_active
   .word @lr_select
   .word @semitones
   .word @finetune
   .word @keytrack
   .word @pmsel ; pitch mod select
   .word @pitchmoddep ; pitch mod depth
@connection:
   plx
   iny
   lda fm_gen::comps, y
   sta concerto_synth::timbres::Timbre::fm_general::con, x
   ; draw FM algorithm
   sta guiutils::draw_data1
   jsr guiutils::draw_fm_alg
   rts
@feedback:
   plx
   iny
   iny
   lda fm_gen::comps, y
   sta concerto_synth::timbres::Timbre::fm_general::fl, x
   rts
@op1_active:
   lda #%00000001
   sta wfm_bits
   bra @op_active_common
@op2_active:
   lda #%00000010
   sta wfm_bits
   bra @op_active_common
@op3_active:
   lda #%00000100
   sta wfm_bits
   bra @op_active_common
@op4_active:
   lda #%00001000
   sta wfm_bits
   bra @op_active_common
@op_active_common: ; DON'T put this label into jump table ...
   plx
   ; get checkbox value
   lda fm_gen::comps, y
   ; push into carry flag
   lsr
   lda wfm_bits
   bcc :+
   ; checkbox activated
   ora concerto_synth::timbres::Timbre::fm_general::op_en, x
   bra :++
:  ; checkbox deactivated
   eor #%11111111
   and concerto_synth::timbres::Timbre::fm_general::op_en, x
:  sta concerto_synth::timbres::Timbre::fm_general::op_en, x
   rts
@lr_select:
   plx
   iny
   iny
   iny
   lda fm_gen::comps, y
   clc
   ror
   ror
   ror
   sta concerto_synth::timbres::Timbre::fm_general::lr, x
   rts
@semitones:
   plx
   iny
   iny
   ; decide if we need to tune down to compensate for fine tuning (because fine tuning internally only goes up)
   lda concerto_synth::timbres::Timbre::fm_general::fine, x
   bmi :+
   lda fm_gen::comps, y
   sta concerto_synth::timbres::Timbre::fm_general::pitch, x
   rts
:  lda fm_gen::comps, y
   dec
   sta concerto_synth::timbres::Timbre::fm_general::pitch, x
   rts
@finetune:
   plx
   iny
   iny
   ; if fine tune is now negative, but was non-negative beforehand, we need to decrement semitones
   ; and the other way round: if fine tune was negative, but now is non-negative, we need to increment semitones
   lda concerto_synth::timbres::Timbre::fm_general::fine, x
   bmi @fine_negative
@fine_positive:
   lda fm_gen::comps, y
   bpl @fine_normal
   dec concerto_synth::timbres::Timbre::fm_general::pitch, x
   bra @fine_normal
@fine_negative:
   lda fm_gen::comps, y
   bmi @fine_normal
   inc concerto_synth::timbres::Timbre::fm_general::pitch, x
@fine_normal:
   sta concerto_synth::timbres::Timbre::fm_general::fine, x
   rts
@keytrack:
   plx
   lda fm_gen::comps, y
   sta concerto_synth::timbres::Timbre::fm_general::track, x
   rts
@pmsel:
   plx
   iny
   iny
   iny
   lda fm_gen::comps, y
   jsr map_modsource_from_gui
   sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
   rts
@pitchmoddep:
   plx
   iny
   iny
   lda fm_gen::comps, y
   jsr concerto_synth::map_twos_complement_to_scale5
   sta concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
   rts


write_fm_op:
   ; invalidate all FM timbres that have been loaded onto the YM2151 (i.e. enforce reload after timbre has been changed)
   jsr concerto_synth::voices::panic
   jsr concerto_synth::voices::invalidate_fm_timbres
   ; determine operator index
   ldx fm_op::active_tab
   lda Timbre
   clc
@loop:
   dex
   bmi @loop_done
   adc #N_TIMBRES
   bra @loop
@loop_done:
   tax
   ; component offset
   lda mouse_state::curr_component_ofs
   adc #4 ; carry should be clear from previous code
   tay ; there's no component type where the data is before this index
   ; now determine which component has been dragged
   phx
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @tab_select
   .word @attack
   .word @decay1
   .word @decay_level
   .word @decay2
   .word @release
   .word @mul
   .word @fine
   .word @coarse
   .word @vol
   .word @key_scaling
   .word @vol_sens
@tab_select:
   plx
   lda mouse_state::curr_data_1
   sta fm_op::active_tab
   jsr refresh_fm_op
   rts
@attack:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::ar, x
   rts
@decay1:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::d1r, x
   rts
@decay_level:
   plx
   iny
   iny
   sec
   lda #15
   sbc fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::d1l, x
   rts
@decay2:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::d2r, x
   rts
@release:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::rr, x
   rts
@mul:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::mul, x
   rts
@fine:
   plx
   iny
   iny
   lda fm_op::comps, y
   bpl :+
   ; transform -3 ... -0 range to 5 .. 7 (4 is unused, since it does the same thing as 0)
   eor #%11111111
   clc
   adc #5
:  sta concerto_synth::timbres::Timbre::operators::dt1, x
   rts
@coarse:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::dt2, x
   rts
@vol:
   plx
   iny
   iny
   lda #127
   sec
   sbc fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::level, x
   rts
@key_scaling:
   plx
   iny
   iny
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::ks, x
   rts
@vol_sens:
   plx
   lda fm_op::comps, y
   sta concerto_synth::timbres::Timbre::operators::vol_sens, x
   rts

write_globalnav:
   lda mouse_state::curr_data_2 ; y position in multiples of 8 pixels
   ; tabs start at row 12 and are 16 high each
   sec
   sbc #12
   lsr
   lsr
   lsr
   lsr
   sta globalnav::active_tab
   cmp #0
   beq @load_arrangement_view
   cmp #1
   beq @load_clip_view
   jsr load_synth_gui
   bra @end
@load_arrangement_view:
   jsr load_arrangement_gui
   bra @end
@load_clip_view:
   jsr load_clip_gui
@end:
   jsr draw_gui
   rts

write_clip_edit:
   ; prepare component string offset
   lda mouse_state::curr_component_ofs
   clc
   adc #5 ; we're reading only arrowed edits
   tay
   ; prepare jump
   lda mouse_state::curr_component_id
   asl
   tax
   jmp (@jmp_tbl, x)
@jmp_tbl:
   .word @zoom_level
   .word @go_left
   .word @go_up
   .word @go_down
   .word @go_right
   .word @edit_notes
@zoom_level:
   ; read data from component string and write it to the zoom setting
   lda clip_edit::comps, y
   dec
   sta clip_edit::zoom_level
   ; make sure the time stamp is aligned with the current grid ... very crude method. TODO: "round to nearest"
   stz clip_edit::time_stamp
   stz clip_edit::time_stamp+1
   jsr refresh_gui
   rts
@go_left:
   ; TODO: provide different strides at different zoom levels
   lda clip_edit::time_stamp
   sec
   sbc timing::detail::quarter_ticks
   sta clip_edit::time_stamp
   lda clip_edit::time_stamp+1
   sbc #0
   sta clip_edit::time_stamp+1
   jsr refresh_gui
   rts
@go_up:
   lda clip_edit::low_note
   clc
   adc #6
   sta clip_edit::low_note
   jsr refresh_gui
   rts
@go_down:
   lda clip_edit::low_note
   sec
   sbc #6
   sta clip_edit::low_note
   jsr refresh_gui
   rts
@go_right:
   ; TODO: provide different strides at different zoom levels
   lda clip_edit::time_stamp
   clc
   adc timing::detail::quarter_ticks
   sta clip_edit::time_stamp
   lda clip_edit::time_stamp+1
   adc #0
   sta clip_edit::time_stamp+1
   jsr refresh_gui
   rts
@edit_notes:
   rts



; panels' refresh subroutines
; ---------------------------
; These update the data that is shown in the control elements incase the underlying
; data has changed.
; E.g. when switching tabs, or when changing the timbre.
; Note that these subroutines only refresh certain components, while leaving others
; as they are, e.g. tab-selectors are not affected (in fact, they affect the other components)


refresh_synth_global:
   ldx Timbre ; may be replaced later
   ; number of oscillators
   lda concerto_synth::timbres::Timbre::n_oscs, x
   ldy #(0*checkbox_data_size+0*drag_edit_data_size+1*arrowed_edit_data_size-1)
   sta synth_global::comps, y
   ; number of envelopes
   lda concerto_synth::timbres::Timbre::n_envs, x
   ldy #(0*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
   sta synth_global::comps, y
   ; LFO activate checkbox
   lda concerto_synth::timbres::Timbre::n_lfos, x
   ldy #(1*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
   sta synth_global::comps, y
   ; retrigger checkbox
   lda concerto_synth::timbres::Timbre::retrig, x
   ldy #(2*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
   sta synth_global::comps, y
   ; porta activate checkbox
   lda concerto_synth::timbres::Timbre::porta, x
   ldy #(3*checkbox_data_size+0*drag_edit_data_size+2*arrowed_edit_data_size-1)
   sta synth_global::comps, y
   ; porta rate edit
   lda concerto_synth::timbres::Timbre::porta_r, x
   ldy #(3*checkbox_data_size+1*drag_edit_data_size+2*arrowed_edit_data_size-2)
   sta synth_global::comps, y
   ; vibrato amount edit
   lda concerto_synth::timbres::Timbre::vibrato, x
   bmi :+
   jsr concerto_synth::map_scale5_to_twos_complement
   bra :++
:  lda #0
:  ldy #(3*checkbox_data_size+2*drag_edit_data_size+2*arrowed_edit_data_size-2)
   sta synth_global::comps, y
   ; redraw components
   lda #0
   jsr draw_components
   rts

refresh_osc:
   ; first, determine the offset of the oscillator in the Timbre data
   lda Timbre ; may be replaced later
   ldx osc::active_tab ; envelope number
@loop:
   cpx #0
   beq @end_loop
   clc
   adc #N_TIMBRES
   dex
   bra @loop
@end_loop:
   tax ; oscillator index is in x
   ; read Timbre data and load it into GUI components
   ; waveform
   lda concerto_synth::timbres::Timbre::osc::waveform, x
   clc
   rol
   rol
   rol
   ldy #(tab_selector_data_size+listbox_data_size-1)
   sta osc::comps, y
   ; pulse width
   lda concerto_synth::timbres::Timbre::osc::pulse, x
   ldy #(tab_selector_data_size+listbox_data_size+0*checkbox_data_size+drag_edit_data_size-2)
   sta osc::comps, y
   ; amplifier select
   lda concerto_synth::timbres::Timbre::osc::amp_sel, x
   ldy #(tab_selector_data_size+2*listbox_data_size+0*checkbox_data_size+drag_edit_data_size-1)
   sta osc::comps, y
   ; volume
   lda concerto_synth::timbres::Timbre::osc::volume, x
   ldy #(tab_selector_data_size+2*listbox_data_size+0*checkbox_data_size+2*drag_edit_data_size-2)
   sta osc::comps, y
   ; L/R
   lda concerto_synth::timbres::Timbre::osc::lrmid, x
   clc
   rol
   rol
   rol
   ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+2*drag_edit_data_size-1)
   sta osc::comps, y
   ; semitones
   ; we need to check fine tune to get correct semi tones.
   ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
   lda concerto_synth::timbres::Timbre::osc::fine, x
   bmi :+
   lda concerto_synth::timbres::Timbre::osc::pitch, x
   bra :++
:  lda concerto_synth::timbres::Timbre::osc::pitch, x
   inc
:  ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+3*drag_edit_data_size-2)
   sta osc::comps, y
   ; fine tune
   lda concerto_synth::timbres::Timbre::osc::fine, x
   ldy #(tab_selector_data_size+3*listbox_data_size+0*checkbox_data_size+4*drag_edit_data_size-2)
   sta osc::comps, y
   ; key track
   lda concerto_synth::timbres::Timbre::osc::track, x
   ldy #(tab_selector_data_size+3*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
   sta osc::comps, y
   ; pitch mod select 1
   lda concerto_synth::timbres::Timbre::osc::pitch_mod_sel1, x
   jsr map_modsource_to_gui
   ldy #(tab_selector_data_size+4*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
   sta osc::comps, y
   ; pitch mod select 2
   lda concerto_synth::timbres::Timbre::osc::pitch_mod_sel2, x
   jsr map_modsource_to_gui
   ldy #(tab_selector_data_size+5*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
   sta osc::comps, y
   ; pwm select
   lda concerto_synth::timbres::Timbre::osc::pwm_sel, x
   jsr map_modsource_to_gui
   ldy #(tab_selector_data_size+6*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
   sta osc::comps, y
   ; vol mod select
   lda concerto_synth::timbres::Timbre::osc::vol_mod_sel, x
   jsr map_modsource_to_gui
   ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+4*drag_edit_data_size-1)
   sta osc::comps, y
   ; pitch mod depth 1
   lda concerto_synth::timbres::Timbre::osc::pitch_mod_dep1, x
   jsr concerto_synth::map_scale5_to_twos_complement
   ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+5*drag_edit_data_size-2)
   sta osc::comps, y
   ; pitch mod depth 2
   lda concerto_synth::timbres::Timbre::osc::pitch_mod_dep2, x
   jsr concerto_synth::map_scale5_to_twos_complement
   ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+6*drag_edit_data_size-2)
   sta osc::comps, y
   ; pwm depth
   lda concerto_synth::timbres::Timbre::osc::pwm_dep, x
   jsr map_signed_7bit_to_twos_complement
   ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+7*drag_edit_data_size-2)
   sta osc::comps, y
   ; volume mod depth
   lda concerto_synth::timbres::Timbre::osc::vol_mod_dep, x
   jsr map_signed_7bit_to_twos_complement
   ldy #(tab_selector_data_size+7*listbox_data_size+1*checkbox_data_size+8*drag_edit_data_size-2)
   sta osc::comps, y
   ; redraw components
   lda #1
   jsr draw_components
   rts

refresh_env:
   ; first, determine the offset of the envelope in the Timbre data
   lda Timbre ; may be replaced later
   ldx env::active_tab ; envelope number
@loop:
   cpx #0
   beq @end_loop
   clc
   adc #N_TIMBRES
   dex
   bra @loop
@end_loop:
   tax ; envelope index is in x
   ; read ADSR data from Timbre and load it into edits
   ; attack edit
   ldy #(tab_selector_data_size + 6)
   lda concerto_synth::timbres::Timbre::env::attackH, x
   sta env::comps, y
   iny
   lda concerto_synth::timbres::Timbre::env::attackL, x
   sta env::comps, y
   ; decay edit
   tya
   clc
   adc #(drag_edit_data_size-1)
   tay
   lda concerto_synth::timbres::Timbre::env::decayH, x
   sta env::comps, y
   iny
   lda concerto_synth::timbres::Timbre::env::decayL, x
   sta env::comps, y
   ; sustain edit
   tya
   clc
   adc #(drag_edit_data_size-1)
   tay
   lda concerto_synth::timbres::Timbre::env::sustain, x
   sta env::comps, y
   ; release edit
   tya
   clc
   adc #(drag_edit_data_size)
   tay
   lda concerto_synth::timbres::Timbre::env::releaseH, x
   sta env::comps, y
   iny
   lda concerto_synth::timbres::Timbre::env::releaseL, x
   sta env::comps, y
   ; redraw components
   lda #2
   jsr draw_components
   rts

refresh_snav:
   ; nothing to be done here (yet)
   rts


refresh_lfo:
   ldx Timbre ; may be replaced later
   ; LFO waveform
   lda concerto_synth::timbres::Timbre::lfo::wave, x
   ldy #(0*checkbox_data_size+0*drag_edit_data_size+1*listbox_data_size-1)
   sta lfo::comps, y
   ; LFO retrigger
   lda concerto_synth::timbres::Timbre::lfo::retrig, x
   ldy #(1*checkbox_data_size+0*drag_edit_data_size+1*listbox_data_size-1)
   sta lfo::comps, y
   ; LFO rate
   lda concerto_synth::timbres::Timbre::lfo::rateH, x
   ldy #(1*checkbox_data_size+1*drag_edit_data_size+1*listbox_data_size-2)
   sta lfo::comps, y
   iny
   lda concerto_synth::timbres::Timbre::lfo::rateL, x
   sta lfo::comps, y
   ; phase offset
   lda concerto_synth::timbres::Timbre::lfo::offs, x
   ldy #(1*checkbox_data_size+2*drag_edit_data_size+1*listbox_data_size-2)
   sta lfo::comps, y
   ; redraw components
   lda #5
   jsr draw_components
   rts

refresh_fm_gen:
   @rfm_bits = mzpbd
   ldx Timbre
   ; connection scheme
   lda concerto_synth::timbres::Timbre::fm_general::con, x
   ldy #(0*checkbox_data_size+0*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; feedback level
   lda concerto_synth::timbres::Timbre::fm_general::fl, x
   ldy #(0*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-2)
   sta fm_gen::comps, y
   ; operators enable
   lda concerto_synth::timbres::Timbre::fm_general::op_en, x
   sta @rfm_bits
   ; operator 1 enable
   lda #0
   bbr0 @rfm_bits, :+
   lda #1
:  ldy #(1*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; operator 2 enable
   lda #0
   bbr1 @rfm_bits, :+
   lda #1
:  ldy #(2*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; operator 3 enable
   lda #0
   bbr2 @rfm_bits, :+
   lda #1
:  ldy #(3*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; operator 4 enable
   lda #0
   bbr3 @rfm_bits, :+
   lda #1
:  ldy #(4*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; LR channel select
   lda concerto_synth::timbres::Timbre::fm_general::lr, x
   clc
   rol
   rol
   rol
   ldy #(4*checkbox_data_size+1*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; semitones
   ; we need to check fine tune to get correct semi tones.
   ; if fine tune is negative, we need to increment one to the semitone value to be displayed on the GUI
   lda concerto_synth::timbres::Timbre::fm_general::fine, x
   bmi :+
   lda concerto_synth::timbres::Timbre::fm_general::pitch, x
   bra :++
:  lda concerto_synth::timbres::Timbre::fm_general::pitch, x
   inc
:  ldy #(4*checkbox_data_size+2*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-2)
   sta fm_gen::comps, y
   ; fine tune
   lda concerto_synth::timbres::Timbre::fm_general::fine, x
   ldy #(4*checkbox_data_size+3*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-2)
   sta fm_gen::comps, y
   ; key track
   lda concerto_synth::timbres::Timbre::fm_general::track, x
   ldy #(5*checkbox_data_size+3*drag_edit_data_size+1*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; pitch mod select
   lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_sel, x
   jsr map_modsource_to_gui
   ldy #(5*checkbox_data_size+3*drag_edit_data_size+2*listbox_data_size+1*arrowed_edit_data_size-1)
   sta fm_gen::comps, y
   ; pitch mod depth
   lda concerto_synth::timbres::Timbre::fm_general::pitch_mod_dep, x
   jsr concerto_synth::map_scale5_to_twos_complement
   ldy #(5*checkbox_data_size+4*drag_edit_data_size+2*listbox_data_size+1*arrowed_edit_data_size-2)
   sta fm_gen::comps, y

   ; redraw components
   lda #7
   jsr draw_components
   ; redraw FM algorithm
   ldx Timbre
   lda concerto_synth::timbres::Timbre::fm_general::con, x
   sta guiutils::draw_data1
   jsr guiutils::draw_fm_alg
   rts

refresh_fm_op:
   ; determine operator index
   ldx fm_op::active_tab
   lda Timbre
   clc
@loop:
   dex
   bmi @loop_done
   clc
   adc #N_TIMBRES
   bra @loop
@loop_done:
   tax
   ; attack
   lda concerto_synth::timbres::Timbre::operators::ar, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+1*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; decay 1
   lda concerto_synth::timbres::Timbre::operators::d1r, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+2*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; decay level
   sec
   lda #15
   sbc concerto_synth::timbres::Timbre::operators::d1l, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+3*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; decay 2
   lda concerto_synth::timbres::Timbre::operators::d2r, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+4*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; release
   lda concerto_synth::timbres::Timbre::operators::rr, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+5*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; mul
   lda concerto_synth::timbres::Timbre::operators::mul, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+6*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; fine
   lda concerto_synth::timbres::Timbre::operators::dt1, x
   and #%00000100
   beq :+
   lda concerto_synth::timbres::Timbre::operators::dt1, x
   eor #%11111111
   clc
   adc #5
   bra :++
:  lda concerto_synth::timbres::Timbre::operators::dt1, x
:  ldy #(tab_selector_data_size + 0*checkbox_data_size+7*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; coarse
   lda concerto_synth::timbres::Timbre::operators::dt2, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+8*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; vol
   sec
   lda #127
   sbc concerto_synth::timbres::Timbre::operators::level, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+9*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; key scaling
   lda concerto_synth::timbres::Timbre::operators::ks, x
   ldy #(tab_selector_data_size + 0*checkbox_data_size+10*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-2)
   sta fm_op::comps, y
   ; volume sensitivity
   lda concerto_synth::timbres::Timbre::operators::vol_sens, x
   ldy #(tab_selector_data_size + 1*checkbox_data_size+10*drag_edit_data_size+0*listbox_data_size+0*arrowed_edit_data_size-1)
   sta fm_op::comps, y
   ; redraw components
   lda #8
   jsr draw_components
   rts

refresh_clip_edit:
   jsr draw_clip_edit
   rts


.endscope