; Copyright 2021, 2023 Carl Georg Biermann

; This file contains most of the GUI relevant code at the moment.
; It is called mainly by the mouse.asm driver, and sends commands to the guiutils.asm
; to output GUI elements.
; The appearance and behaviour of the GUI is also hard coded in this file.
; The interaction between the GUI and the timbre (and later perhaps song) data
; is currently also done in this file.



.scope gui

.include "gui_definitions.asm"
.include "components/components.asm"
.include "panels/panels.asm"

; TODO: remove when not used in this file anymore
; placeholder for unimplemented/unnecessary subroutines
dummy_sr:
   rts



.ifdef ::concerto_full_daw
   ; brings up the synth GUI
   ; puts all synth related panels into the GUI stack
   load_synth_gui:
      jsr guiutils::cls
      lda #9 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::global_navigation
      sta panels::panels_stack+0
      lda #panels::ids::synth_navigation
      sta panels::panels_stack+1
      lda #panels::ids::synth_info
      sta panels::panels_stack+2
      lda #panels::ids::fm_general
      sta panels::panels_stack+3
      lda #panels::ids::fm_operators
      sta panels::panels_stack+4
      lda #panels::ids::synth_global
      sta panels::panels_stack+5
      lda #panels::ids::psg_oscillators
      sta panels::panels_stack+6
      lda #panels::ids::envelopes
      sta panels::panels_stack+7
      lda #panels::ids::lfo
      sta panels::panels_stack+8
      jsr refresh_gui
      rts

   load_clip_gui:
      jsr guiutils::cls
      lda #2 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::global_navigation
      sta panels::panels_stack+0
      lda #panels::ids::clip_editing
      sta panels::panels_stack+1
      jsr refresh_gui
      rts

   load_arrangement_gui:
      jsr guiutils::cls
      lda #1 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::global_navigation
      sta panels::panels_stack+0
      jsr refresh_gui
      rts
.else
   ; brings up the synth GUI
   ; puts all synth related panels into the GUI stack
   load_synth_gui:
      jsr guiutils::cls
      lda #8 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::synth_navigation
      sta panels::panels_stack+0
      lda #panels::ids::synth_info
      sta panels::panels_stack+1
      lda #panels::ids::fm_general
      sta panels::panels_stack+2
      lda #panels::ids::fm_operators
      sta panels::panels_stack+3
      lda #panels::ids::synth_global
      sta panels::panels_stack+4
      lda #panels::ids::psg_oscillators
      sta panels::panels_stack+5
      lda #panels::ids::envelopes
      sta panels::panels_stack+6
      lda #panels::ids::lfo
      sta panels::panels_stack+7
      jsr refresh_gui
      rts
.endif

; Goes through the various requests which can be issued during events and addresses them.
; Expects mouse_definitions::curr_panel to be set to the relevant panel.
.proc handle_component_requests
   ; check if component wants an update
   lda gui_definitions::request_component_write
   beq @end_write_request
   stz gui_definitions::request_component_write
   lda mouse_definitions::curr_panel
   asl
   tax
   INDEXED_JSR panels::jump_table_write, @end_write_request
@end_write_request:
   ; check if component wants a redraw
   lda gui_definitions::request_components_redraw
   beq @end_redraw_request
   lda mouse_definitions::curr_panel
   jsr draw_components
   stz gui_definitions::request_components_redraw
@end_redraw_request:
   rts
.endproc


; reads through the stack and draws everything
draw_gui:
   dg_counter = mzpbe ; counter variable
   stz dg_counter
@loop:
   ; TODO: clear area on screen (but when exactly is it needed?)
   ; call panel-specific drawing subroutines
   ldy dg_counter
   lda panels::panels_stack, y
   asl
   tax
   INDEXED_JSR panels::jump_table_draw, @ret_addr
@ret_addr:
   ; draw GUI components
   ldy dg_counter
   lda panels::panels_stack, y
   jsr draw_components
   ; draw captions
   ldy dg_counter
   lda panels::panels_stack, y
   jsr draw_captions
   ; advance in loop
   lda dg_counter
   inc
   cmp panels::panels_stack_pointer
   sta dg_counter
   bne @loop
   rts

; draws all captions from the caption string of a panel
; expects panel ID in register A
draw_captions:
   dcp_pointer = mzpwa
   asl
   tax
   lda panels::capts, x
   sta dcp_pointer
   lda panels::capts+1, x
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

; goes through the stack of active GUI panels and refreshes every one of them
refresh_gui:
   rfg_counter = mzpbe ; counter variable
   stz rfg_counter
@loop:
   ; call panel-specific drawing subroutine
   ldy rfg_counter
   lda panels::panels_stack, y
   asl
   tax
   INDEXED_JSR panels::jump_table_refresh, @ret_addr
@ret_addr:
   ; advance in loop
   lda rfg_counter
   inc
   cmp panels::panels_stack_pointer
   sta rfg_counter
   bne @loop

   jsr draw_gui
   rts








; goes through a GUI component string and draws all components in it
; expects panel ID in register A
draw_components:
   dc_pointer = mzpwa
   asl
   tax
   lda panels::comps, x
   sta dc_pointer
   lda panels::comps+1, x
   sta dc_pointer+1
   ldy #0
@loop:
@return_addr:
   lda (dc_pointer), y
   bmi @end_loop ; end on type 255
   iny
   asl
   tax
   INDEXED_JSR components::jump_table_draw, @return_addr
@end_loop:
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
   lda panels::comps, x
   sta gc_pointer
   lda panels::comps+1, x
   sta gc_pointer+1
   ; iterate over gui elements
   lda #255
   sta gc_counter
   lda #0
@check_gui_loop:
   tay
   ; increment control element identifier
   inc gc_counter
   ; look up which component type is next (type 255 is end of GUI component list)
   lda (gc_pointer), y
   bmi @no_hit ; if component is 255, go end
   pha ; remember component type
   asl
   tax
   iny
   phy ; remember .Y incase it's a hit
   ; jump to according component check
   INDEXED_JSR components::jump_table_check_mouse, @return_addr
@return_addr:
   ply ; recall .Y prior to component check
   plx ; recall component type
   bcs @hit
   ; no hit ... move on to the next component
   tya
   adc components::component_sizes, x ; carry is clear as per BCS above
   bra @check_gui_loop
@hit:
   tya
   sta mouse_definitions::curr_component_ofs
   lda gc_counter
   sta mouse_definitions::curr_component_id
   rts
@no_hit:
   ; 255 still in .A
   sta mouse_definitions::curr_component_id
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
   lda panels::comps, x
   sta ce_pointer
   lda panels::comps+1, x
   sta ce_pointer+1
   ldy mouse_definitions::curr_component_ofs ; load component's offset
   dey
   lda (ce_pointer), y ; and get its type
   asl
   tax
   jmp (components::jump_table_event_click, x) ; the called routines will do the rts for us.




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
   lda panels::comps, x
   sta de_pointer
   lda panels::comps+1, x
   sta de_pointer+1   ; put GUI component string pointer to ZP
   ldy mouse_definitions::curr_component_ofs ; load component's offset
   dey
   lda (de_pointer), y ; and get its type
   asl
   tax
   jmp (components::jump_table_event_drag, x) ; the called routines will do the rts for us.



.include "backward_definitions.asm"

.endscope
