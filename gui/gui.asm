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

; The Panel Stack
; defines which panels are drawn in which order, and which panels receive mouse events first.
; The first elements in the stack are at the bottom.
.scope stack
   stack: PANEL_BYTE_FIELD    ; the actual stack, containing the indices of the panels
   sp: .byte 0                ; stack pointer, counts how many elements are on the stack
.endscope

.include "gui_definitions.asm"
.include "panels/lookup_tables.asm"

; TODO: remove when not used in this file anymore
; placeholder for unimplemented/unnecessary subroutines
dummy_sr:
   rts

; brings up the synth GUI
; puts all synth related panels into the GUI stack
load_synth_gui:
   jsr guiutils::cls
   lda #9 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #panels_luts::ids::global_navigation
   sta stack::stack+0
   lda #panels_luts::ids::synth_navigation
   sta stack::stack+1
   lda #panels_luts::ids::synth_info
   sta stack::stack+2
   lda #panels_luts::ids::fm_general
   sta stack::stack+3
   lda #panels_luts::ids::fm_operators
   sta stack::stack+4
   lda #panels_luts::ids::synth_global
   sta stack::stack+5
   lda #panels_luts::ids::psg_oscillators
   sta stack::stack+6
   lda #panels_luts::ids::envelopes
   sta stack::stack+7
   lda #panels_luts::ids::lfo
   sta stack::stack+8
   jsr refresh_gui
   rts


load_clip_gui:
   jsr guiutils::cls
   lda #2 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #panels_luts::ids::global_navigation
   sta stack::stack+0
   lda #panels_luts::ids::clip_editing
   sta stack::stack+1
   jsr refresh_gui
   rts


load_arrangement_gui:
   jsr guiutils::cls
   lda #1 ; GUI stack size (how many panels are visible)
   sta stack::sp
   lda #panels_luts::ids::global_navigation
   sta stack::stack+0
   jsr refresh_gui
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
   INDEXED_JSR panels_luts::jump_table_draw, @ret_addr
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
   lda panels_luts::capts, x
   sta dcp_pointer
   lda panels_luts::capts+1, x
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
   lda panels_luts::comps, x
   sta dc_pointer
   lda panels_luts::comps+1, x
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
   stz gui_definitions::request_component_write
   lda mouse_definitions::curr_panel
   asl
   tax
   lda panels_luts::comps, x
   sta ce_pointer
   lda panels_luts::comps+1, x
   sta ce_pointer+1
   ldy mouse_definitions::curr_component_ofs ; load component's offset
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
   lda gui_definitions::request_component_write
   bne :+
   rts
:  ; call panel's writing subroutine, which is part of the interface between GUI and internal data
   lda mouse_definitions::curr_panel
   asl
   tax
   INDEXED_JSR panels_luts::jump_table_write, @ret_addrB
@ret_addrB:
   rts  ; we could actually leave the jsr away and just jmp to the subroutine... but I'll leave it for now. Optimizations later...

; GUI component's click subroutines
; ---------------------------------
; expect component string's pointer in ce_pointer on zero page,
; and also the component's offset in mouse_definitions::curr_component_ofs
; and relevant click data (determined by the click detection) in mouse_definitions::curr_data_1

click_button:
   ; register the click to trigger a write_...
   inc gui_definitions::request_component_write
   ; nothing else to be done here. click events are handled inside the panels'
   ; write_... subroutines, because they can identify individual buttons and know
   ; what actions to perform.
   rts

click_tab_select:
   inc gui_definitions::request_component_write
   ; put new tab into GUI component list
   lda mouse_definitions::curr_data_1
   ldy mouse_definitions::curr_component_ofs
   iny
   iny
   iny
   iny
   sta (ce_pointer), y
   ; and redraw it
   ldy mouse_definitions::curr_component_ofs
   iny
   jsr draw_tab_select
   jsr refresh_gui
   rts

click_arrowed_edit:
   cae_value = mzpbe
   ; check if one of the arrows has been clicked
   lda mouse_definitions::curr_data_1
   bne :+
   rts
:  ; yes, one of the arrows has been clicked...
   inc gui_definitions::request_component_write ; register a change on the GUI
   ; now, get value from edit
   lda mouse_definitions::curr_component_ofs
   clc
   adc #5
   tay
   lda (ce_pointer), y
   sta cae_value
   ; now, decide whether left or right was clicked
   dey
   lda mouse_definitions::curr_data_1
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
   ldy mouse_definitions::curr_component_ofs
   iny
   jsr draw_arrowed_edit
   rts

click_checkbox:
   inc gui_definitions::request_component_write ; register a change on the GUI
   ldy mouse_definitions::curr_component_ofs
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
   ldy mouse_definitions::curr_component_ofs
   iny
   jsr draw_checkbox
   rts

click_listbox:
   ; we don't activate gui_definitions::request_component_write, because the first click on the listbox
   ; doesn't change any actual data,
   ; bring up popup panel
   ; TODO: later we would need to calculate the popup position based on the listbox position
   ; and a possibly oversized popup (so that it would range beyond the screen)
   ; We'll deal with that as soon as this becomes an issue.
   ; For now, we'll just directly place it where we want it.
   ldy mouse_definitions::curr_component_ofs
   iny
   lda (ce_pointer), y
   sta panels_luts::listbox_popup::box_x
   iny
   lda (ce_pointer), y
   inc ; we'll see where exactly we want the popup (TODO)
   sta panels_luts::listbox_popup::box_y
   ; load additional info into popup panel data
   iny 
   lda (ce_pointer), y
   sta panels_luts::listbox_popup::box_width
   iny 
   lda (ce_pointer), y
   sta panels_luts::listbox_popup::box_height
   iny
   lda (ce_pointer), y
   sta panels_luts::listbox_popup::strlist
   iny
   lda (ce_pointer), y
   sta panels_luts::listbox_popup::strlist+1
   lda mouse_definitions::curr_component_ofs
   sta panels_luts::listbox_popup::lb_ofs
   lda ce_pointer
   sta panels_luts::listbox_popup::lb_addr
   lda ce_pointer+1
   sta panels_luts::listbox_popup::lb_addr+1
   lda mouse_definitions::curr_component_id
   sta panels_luts::listbox_popup::lb_id
   lda mouse_definitions::curr_panel
   sta panels_luts::listbox_popup::lb_panel
   ; now do the GUI stack stuff
   ldx stack::sp
   lda #panels_luts::ids::listbox_popup
   sta stack::stack, x
   inc stack::sp
@update_gui:
   jsr panels_luts::listbox_popup::draw
   rts

click_dummy:
   inc gui_definitions::request_component_write
   rts


; drag event. looks in mouse variables which panel's component has been dragged and calls its routine
; expects L/R information in mouse_definitions::curr_data_1 (0 for left drag, 1 for right drag)
; and dragging distance in mouse_definitions::curr_data_2
drag_event:
   ; call GUI component's drag subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   de_pointer = mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   stz gui_definitions::request_component_write
   lda mouse_definitions::curr_panel
   asl
   tax
   lda panels_luts::comps, x
   sta de_pointer
   lda panels_luts::comps+1, x
   sta de_pointer+1   ; put GUI component string pointer to ZP
   ldy mouse_definitions::curr_component_ofs ; load component's offset
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
   lda gui_definitions::request_component_write
   bne :+
   rts
:  ; call panel's drag subroutine, which is part of the interface between GUI and internal data
   lda mouse_definitions::curr_panel
   asl
   tax
   INDEXED_JSR panels_luts::jump_table_write, @ret_addrB
@ret_addrB:
   rts  ; we could leave that away and just jmp to the subroutines instead of jsr, but optimizations later.

; GUI component's drag subroutines
; ---------------------------------
; expect component string's pointer in de_pointer on zero page,
; and also the component's offset in mouse_definitions::prev_component_ofs (not curr!)
; and whether dragging is done with left or right mouse button in mouse_definitions::curr_data_1 (left=0, right=1)
; and drag distance compared to previous frame in mouse_definitions::curr_data_2

drag_drag_edit:
   inc gui_definitions::request_component_write
   ; first check if drag edit has fine editing enabled
   ldy mouse_definitions::prev_component_ofs
   iny
   iny
   iny
   lda (de_pointer), y
   and #%00000001
   beq @coarse_drag  ; if there is no fine editing enabled, we jump straight to coarse editing
   ; check mouse for fine or coarse dragging mode
   lda mouse_definitions::curr_data_1
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
   lda mouse_definitions::curr_data_2
   bmi @coarse_drag_down
@coarse_drag_up:
   ; check if adding the increment crosses the border
   lda (de_pointer), y ; load max value, and then subtract current value from it
   iny
   sec
   sbc (de_pointer), y ; now we have the distance to the upper border in the accumulator
   sec
   sbc mouse_definitions::curr_data_2 ; if this overflowed, we are crossing the border
   bcc @coarse_up_overflow
@coarse_up_normal:
   lda (de_pointer), y
   clc
   adc mouse_definitions::curr_data_2
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
   adc mouse_definitions::curr_data_2 ; if the result is negative, we are crossing the border
   bcc @coarse_down_overflow
@coarse_down_normal:
   iny
   iny
   lda (de_pointer), y
   clc
   adc mouse_definitions::curr_data_2
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
   lda mouse_definitions::curr_data_2
   bmi @fine_drag_down
@fine_drag_up:
   ; check if adding the increment crosses the border
   lda #255 ; load max value, and then subtract current value from it
   sec
   sbc (de_pointer), y ; now we have the distance to the upper border in the accumulator
   sec
   sbc mouse_definitions::curr_data_2 ; if this overflowed, we are crossing the border
   bcc @fine_up_overflow
@fine_up_normal:
   lda (de_pointer), y
   clc
   adc mouse_definitions::curr_data_2
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
   adc mouse_definitions::curr_data_2 ; if overflow occurs, we are crossing the border
   bcc @fine_down_overflow
@fine_down_normal:
   lda (de_pointer), y
   clc
   adc mouse_definitions::curr_data_2
   sta (de_pointer), y
   bra @update_gui
@fine_down_overflow:
   ; if overflow occurs, simply put minimal value into edit
   lda #0
   sta (de_pointer), y
   bra @update_gui
@update_gui:
   ldy mouse_definitions::prev_component_ofs
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
   INDEXED_JSR panels_luts::jump_table_refresh, @ret_addr
@ret_addr:
   ; advance in loop
   lda rfg_counter
   inc
   cmp stack::sp
   sta rfg_counter
   bne @loop

   jsr draw_gui
   rts







; returns the panel index the mouse is currently over. Bit 7 set means none
; panel index returned in mouse_definitions::curr_panel
mouse_get_panel:
   ; grab those zero page variables for this routine
   gp_cx = mzpwa
   gp_cy = mzpwd
   ; determine position in characters (divide by 8)
   lda mouse_definitions::curr_x+1
   lsr
   sta gp_cx+1
   lda mouse_definitions::curr_x
   ror
   sta gp_cx
   lda gp_cx+1
   lsr
   ror gp_cx
   lsr
   ror gp_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda mouse_definitions::curr_y+1
   lsr
   sta gp_cy+1
   lda mouse_definitions::curr_y
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
   cmp panels_luts::px, y
   bcc @loop ; gp_cx is smaller than panel's x
   lda panels_luts::px, y
   clc
   adc panels_luts::wd, y
   dec
   cmp gp_cx
   bcc @loop ; gp_cx is too big
   lda gp_cy
   cmp panels_luts::py, y
   bcc @loop ; gp_cy is smaller than panel's y
   lda panels_luts::py, y
   clc
   adc panels_luts::hg, y
   dec
   cmp gp_cy
   bcc @loop ; gp_cy is too big
   ; we're inside! return index
   tya
   sta mouse_definitions::curr_panel
   rts
@end_loop:
   ; found no match
   lda #255
   sta mouse_definitions::curr_panel
   rts



; given the panel, where the mouse is currently at,
; this subroutine finds which GUI component is being clicked
mouse_get_component:
   ; panel number in mouse_definitions::curr_panel
   ; mouse x and y coordinates in mouse_definitions::curr_x and mouse_definitions::curr_y
   ; zero page variables:
   gc_pointer = mzpwa
   gc_cx = mzpwd     ; x and y in multiples of 4 (!) pixels to support half character grid
   gc_cy = mzpwd+1
   gc_counter = mzpbe
   ; determine mouse position in multiples of 4 pixels (divide by 4)
   lda mouse_definitions::curr_x+1
   lsr
   sta gc_cx+1
   lda mouse_definitions::curr_x
   ror
   sta gc_cx
   lda gc_cx+1
   lsr
   ror gc_cx
   ; (high byte is uninteresting, thus not storing it back)
   lda mouse_definitions::curr_y+1
   lsr
   sta gc_cy+1
   lda mouse_definitions::curr_y
   ror
   sta gc_cy
   lda gc_cy+1
   lsr
   ror gc_cy
   ; copy pointer to component string to ZP
   lda mouse_definitions::curr_panel
   asl
   tax
   lda panels_luts::comps, x
   sta gc_pointer
   lda panels_luts::comps+1, x
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
   sta mouse_definitions::curr_component_id
   rts

; component checks (part of mouse_get_component subroutine)
; ---------------------------------------------------------
; These routines check whether the mouse is over the specified GUI component, and,
; in case it is, even return additional information, like e.g. which tab has been clicked.
; These routines are not independent, but are part of the above mouse_get_component subroutine.
; The mouse coordinates are given in 4 pixel multiples.
; These routines expect mouse_definitions::curr_panel and gc_pointer to be set, also gc_cx and gc_cy for mouse positions
; and register Y to be at the first "data" position of the component (one past the identifier byte).
; The return procedure is as follows:
; * If a click has been registered, the variables 
;   mouse_definitions::curr_component_id, mouse_definitions::curr_component_ofs and mouse_definitions::curr_data_1
;   have to be set, and RTS called to exit the check.
; * If no click has been registered, JMP check_gui_loop is called to continue checking.
;   mouse_definitions::curr_component_ofs and mouse_definitions::curr_data_1 are not returned if ms_curr_component's bit 7 is set
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
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
   rts

; which tab clicked is returned in mouse_definitions::curr_data_1
check_tab_selector:
   ; check if mouse is over the tab selector area of the panel
   ; check x direction first
   ldx mouse_definitions::curr_panel
   lda panels_luts::px, x
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
   lda panels_luts::py, x
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
   sta mouse_definitions::curr_data_1 ; store tab being clicked
   tya ; determine component's offset
   sec
   sbc #3 ; correct?
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
   rts
:  iny
   iny
   jmp check_gui_loop

; check arrowed edit for mouse click
; which arrow clicked is returned in mouse_definitions::curr_data_1
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
   sta mouse_definitions::curr_data_1
   tya ; determine offset in component-string
   sec
   sbc #4 ; correct?
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
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
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
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
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
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
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
   rts

; dummy always registers a click event, regardless of where the mouse is. Useful for popups.
check_dummy:
   ; get mouse coordinates (in 8 pixel multiples) and put them into data
   lda gc_cx
   lsr
   sta mouse_definitions::curr_data_1
   lda gc_cy
   lsr
   sta mouse_definitions::curr_data_2
   dey
   tya
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
   rts


.endscope