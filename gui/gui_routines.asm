; Copyright 2021, 2023 Carl Georg Biermann

.include "gui_variables.asm"
.include "components/components.asm"
.include "panels/panels.asm"


.scope gui_routines

.ifdef ::concerto_full_daw
   ; brings up the synth GUI
   ; puts all synth related panels into the GUI stack
   .proc load_synth_gui
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
   .endproc

   .proc load_clip_gui
      jsr guiutils::cls
      lda #3 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::global_navigation
      sta panels::panels_stack+0
      lda #panels::ids::clip_editing
      sta panels::panels_stack+1
      lda #panels::ids::clip_properties
      sta panels::panels_stack+2
      jsr refresh_gui
      rts
   .endproc

   .proc load_arrangement_gui
      jsr guiutils::cls
      lda #1 ; GUI stack size (how many panels are visible)
      sta panels::panels_stack_pointer
      lda #panels::ids::global_navigation
      sta panels::panels_stack+0
      jsr refresh_gui
      rts
   .endproc 

.else
   ; brings up the synth GUI
   ; puts all synth related panels into the GUI stack
   .proc load_synth_gui
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
   .endproc
.endif


; reads through the stack and draws everything
.proc draw_gui
   stz kbd_variables::musical_keyboard_bypass ; panels can activate it in their draw routine
   dg_counter = gui_variables::mzpbe ; counter variable
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
   jsr panels::draw_components
   ; draw captions
   ldy dg_counter
   lda panels::panels_stack, y
   jsr panels::draw_captions
   ; advance in loop
   lda dg_counter
   inc
   cmp panels::panels_stack_pointer
   sta dg_counter
   bne @loop
   rts
.endproc


; goes through the stack of active GUI panels and refreshes every one of them
.proc refresh_gui
   rfg_counter = gui_variables::mzpbe ; counter variable
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
.endproc


; Goes through the various requests which can be issued during events and addresses them.
; Expects mouse_variables::curr_panel to be set to the relevant panel.
.proc handle_component_requests
   ; check if component wants an update
   lda gui_variables::request_component_write
   beq @end_write_request
   stz gui_variables::request_component_write
   lda mouse_variables::curr_panel
   asl
   tax
   INDEXED_JSR panels::jump_table_write, @end_write_request
@end_write_request:
   ; check if component wants a redraw
   lda gui_variables::request_components_redraw
   beq @end_redraw_request
   lda mouse_variables::curr_panel
   jsr panels::draw_components
   stz gui_variables::request_components_redraw
@end_redraw_request:
   rts
.endproc   

; click event. looks in mouse variables which panel has been clicked and calls its routine
; also looks which component has been clicked and calls according routine
.proc click_event
   ; call GUI component's click subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   ce_pointer = gui_variables::mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   ; put GUI component string pointer to ZP
   stz gui_variables::request_component_write
   lda mouse_variables::curr_panel
   asl
   tax
   lda panels::comps, x
   sta ce_pointer
   lda panels::comps+1, x
   sta ce_pointer+1
   ldy mouse_variables::curr_component_ofs ; load component's offset
   dey
   lda (ce_pointer), y ; and get its type
   asl
   tax
   jmp (components::jump_table_event_click, x) ; the called routines will do the rts for us.
.endproc


; drag event. looks in mouse variables which panel's component has been dragged and calls its routine
; expects L/R information in mouse_variables::curr_data_1 (0 for left drag, 1 for right drag)
; and dragging distance in mouse_variables::delta_y / delta_x
.proc drag_event
   ; call GUI component's drag subroutine, to update it.
   ; For that, we need the info about the component from the GUI component string
   ; of the respective panel.
   de_pointer = gui_variables::mzpwa ; it is important that this is the same as dc_pointer, because this routine indirectly calls "their" subroutine, expecting this pointer at the same place
   stz gui_variables::request_component_write
   lda mouse_variables::curr_panel
   asl
   tax
   lda panels::comps, x
   sta de_pointer
   lda panels::comps+1, x
   sta de_pointer+1   ; put GUI component string pointer to ZP
   ldy mouse_variables::curr_component_ofs ; load component's offset
   dey
   lda (de_pointer), y ; and get its type
   asl
   tax
   jmp (components::jump_table_event_drag, x) ; the called routines will do the rts for us.
.endproc


; Currently, only the drag & drop components care about end-of-drag events.
; Hence, we do not create a jump table covering every component, but rather
; do the dispatching "by hand". If needed, we can do it "properly" later on.
.proc drag_end_event
   ; check if *the* drag&drop component is being dragged on
   lda mouse_variables::prev_panel
   cmp #panels::ids::clip_editing
   beq :+
   rts
:  lda mouse_variables::prev_component_id
   bmi :+ ; no component being dragged
   lda mouse_variables::prev_component_ofs ; check if it's the note edit by the offset, as the ID isn't being auto-generated
   cmp #(panels::clip_editing::comps::notes_edit - panels::clip_editing::comps)
   bne :+
   jsr components::drag_and_drop_area::end_drag_event
:  rts
.endproc


; As long as kbd_variables::current_key is non-zero, panels from the panel stack get a chance to inspect the value,
; and if deciding to react to it, set it to zero (thus "using" it).
.proc keypress_event
   ldx panels::panels_stack_pointer
@panels_loop:
   lda kbd_variables::current_key
   beq @panels_loop_end ; finish as early as possible if no key press
   dex
   bmi @panels_loop_end
   lda panels::panels_stack, x
   asl
   phx
   tax
   INDEXED_JSR panels::jump_table_keypress, @return
@return:
   plx
   bra @panels_loop
@panels_loop_end:
   rts
.endproc

.endscope
