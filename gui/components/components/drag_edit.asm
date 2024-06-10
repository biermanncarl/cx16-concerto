; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_EDIT_ASM

::GUI_COMPONENTS_COMPONENTS_DRAG_EDIT_ASM = 1

.include "common.asm"

.scope drag_edit
   .struct data_members
      pos_x .byte
      pos_y .byte
      options .byte
      min_value .byte
      max_value .byte
      coarse_value .byte
      fine_value .byte
   .endstruct

   ; DRAG EDIT flags options:
   ; bit 0: coarse/fine option enabled
   ; bit 1: fine active
   ; bit 2: signed
   ; options irrelevant for drawing the component:
   ; bit 7: if active, zero is forbidden value (for signed scale5 values)


   .proc draw
      lda (components_common::data_pointer), y
      sta guiutils::draw_x
      iny
      lda (components_common::data_pointer), y
      sta guiutils::draw_y
      iny
      lda (components_common::data_pointer), y
      and #%01111111    ; get rid of drawing-irrelevant bits
      sta guiutils::draw_data2
      ; select fine or coarse value:
      lda (components_common::data_pointer), y
      iny
      iny
      iny
      and #%00000010
      beq :+
      ; fine
      iny
      lda (components_common::data_pointer), y
      bra :++
   :  ; coarse
      lda (components_common::data_pointer), y
      iny
   :  sta guiutils::draw_data1
      iny
      phy
      jsr guiutils::draw_drag_edit
      ply
      rts
   .endproc

   .proc check_mouse
      cde_bittest = gui_variables::mzpbf
      ; get edit's options
      iny
      iny
      lda (components_common::data_pointer), y
      dey
      dey
      sta cde_bittest
      ; check x direction
      lda mouse_variables::curr_x_downscaled
      lsr
      sec
      sbc (components_common::data_pointer), y
      ; now A must be smaller than the edit's width,
      ; which is, however, dependent on the edit's options.
      ; We first check if it's smaller than the maximally possible width.
      cmp #5
      bcs @out
      ; Now we increase A if a smaller option is active, thus making it "harder" to be inside
      ; coarse/fine switch?
      bbs0 cde_bittest, :+
      inc
   :  ; signed?
      bbs2 cde_bittest, :+
      inc
   :  cmp #5 ; maximal size of drag edit with all options enabled
      bcc @horizontal_in
   @out:
      clc
      rts
   @horizontal_in:
      ; check y direction
      lda mouse_variables::curr_y_downscaled
      lsr
      iny
      cmp (components_common::data_pointer), y
      bne @out
      ; we're in
      sec
      rts
   .endproc

   event_click = components_common::dummy_subroutine

   .proc event_drag
      inc gui_variables::request_component_write
      ; first check if drag edit has fine editing enabled
      ldy mouse_variables::prev_component_ofs
      iny
      iny
      lda (components_common::data_pointer), y
      and #%00000001
      beq @coarse_drag  ; if there is no fine editing enabled, we jump straight to coarse editing
      ; check mouse for fine or coarse dragging mode
      lda mouse_variables::status
      cmp #mouse_variables::ms_hold_L
      beq @coarse_drag
      jmp @fine_drag
   @coarse_drag:
      ; set coarse drag mode
      lda (components_common::data_pointer), y
      pha
      and #%11111101
      sta (components_common::data_pointer), y
      ; prepare the increment
      iny
      iny
      ; check if dragging up or down
      lda mouse_variables::delta_y
      bmi @coarse_drag_down
   @coarse_drag_up:
      ; check if adding the increment crosses the border
      lda (components_common::data_pointer), y ; load max value, and then subtract current value from it
      iny
      sec
      sbc (components_common::data_pointer), y ; now we have the distance to the upper border in the accumulator
      sec
      sbc mouse_variables::delta_y ; if this overflowed, we are crossing the border
      bcc @coarse_up_overflow
   @coarse_up_normal:
      lda (components_common::data_pointer), y
      clc
      adc mouse_variables::delta_y
      sta (components_common::data_pointer), y
      ; check if zero forbidden
      pla
      bpl :+
      ; if we're here, zero is forbidden -> check if we are at zero
      lda (components_common::data_pointer), y
      bne :+
      ; if we are here, we are at zero. Since we are dragging up, simply increment one
      lda #1
      sta (components_common::data_pointer), y
   :  bra @update_gui
   @coarse_up_overflow:
      ; on overflow, simply put the maximal value into the edit
      dey
      lda (components_common::data_pointer), y
      iny
      sta (components_common::data_pointer), y
      pla ; pull options byte
      bra @update_gui
   @coarse_drag_down:
      ; check if adding the increment crosses the min value
      iny
      lda (components_common::data_pointer), y ; load current value, and then subtract min value from it
      dey
      dey
      sec
      sbc (components_common::data_pointer), y ; now we have the distance to the min value in the accumulator
      clc
      adc mouse_variables::delta_y ; if the result is negative, we are crossing the border
      bcc @coarse_down_overflow
   @coarse_down_normal:
      iny
      iny
      lda (components_common::data_pointer), y
      clc
      adc mouse_variables::delta_y
      sta (components_common::data_pointer), y
      ; check if zero forbidden
      pla
      bpl :+
      ; if we're here, zero is forbidden -> check if we are at zero
      lda (components_common::data_pointer), y
      bne :+
      ; if we are here, we are at zero. Since we are dragging down, simply decrement one
      lda #255
      sta (components_common::data_pointer), y
   :  bra @update_gui
   @coarse_down_overflow:
      ; if overflow occurs, simply put minimal value into edit
      lda (components_common::data_pointer), y
      iny
      iny
      sta (components_common::data_pointer), y
      pla ; pull options byte
      bra @update_gui
   ; 4: dragging edit, followed by x and y position (abs), options (flags), min value, max value, coarse value, fine value
   @fine_drag:
      ; set fine drag mode
      lda (components_common::data_pointer), y
      ora #%00000010
      sta (components_common::data_pointer), y
      ; prepare the increment
      iny
      iny
      iny
      iny
      ; check if dragging up or down
      lda mouse_variables::delta_y
      bmi @fine_drag_down
   @fine_drag_up:
      ; check if adding the increment crosses the border
      lda #255 ; load max value, and then subtract current value from it
      sec
      sbc (components_common::data_pointer), y ; now we have the distance to the upper border in the accumulator
      sec
      sbc mouse_variables::delta_y ; if this overflowed, we are crossing the border
      bcc @fine_up_overflow
   @fine_up_normal:
      lda (components_common::data_pointer), y
      clc
      adc mouse_variables::delta_y
      sta (components_common::data_pointer), y
      bra @update_gui
   @fine_up_overflow:
      ; on overflow, simply put the maximal value into the edit
      lda #255
      sta (components_common::data_pointer), y
      bra @update_gui
   @fine_drag_down:
      ; check if adding the increment crosses the min value
      lda (components_common::data_pointer), y ; load current value
      clc
      adc mouse_variables::delta_y ; if overflow occurs, we are crossing the border
      bcc @fine_down_overflow
   @fine_down_normal:
      lda (components_common::data_pointer), y
      clc
      adc mouse_variables::delta_y
      sta (components_common::data_pointer), y
      bra @update_gui
   @fine_down_overflow:
      ; if overflow occurs, simply put minimal value into edit
      lda #0
      sta (components_common::data_pointer), y
      bra @update_gui
   @update_gui:
      ldy mouse_variables::prev_component_ofs
      jsr draw
      rts
   .endproc
.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_DRAG_EDIT_ASM
