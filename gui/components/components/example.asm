; Copyright 2023 Carl Georg Biermann

; THIS IS EXAMPLE/DOCUMENTATION CODE!
; DO NOT INCLUDE IN THE ACTUAL PROJECT!

.ifndef ::GUI_COMPONENTS_COMPONENTS_EXAMPLE_ASM

::GUI_COMPONENTS_COMPONENTS_EXAMPLE_ASM = 1

.include "common.asm"

; template component, serves as a working example
.scope component_template

   ; The data members (internal state) of the component.
   ; This struct may be empty.
   ; It is meant primarily as a definition. Access to the data may be done in arbitrary fashion.
   ; If the x/y position is included, it is usually given in absolute on-screen coordinates (multiples of 8 pixels, i.e. whole characters)
   .struct data_members
      pos_x .byte
      pos_y .byte
      color .byte
   .endstruct


   ; Draw the component. 
   ; A reference to the component's data is passed in as a zeropage pointer and offset from the pointed to address in .Y,
   ; so can be accessed via (pointer),y addressing.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   ; IMPORTANT! The draw subroutine is expected to advance the .Y register to one past the data needed by the component.
   ;            This is to ensure efficient parsing of the component data.
   .proc draw
      rts
   .endproc


   ; Check if this component has been clicked.
   ; In case it has been clicked, additional information can be returned which will then be available in the event_click subroutine.
   ; A reference to the component's data is passed in as a zeropage pointer and offset from the pointed to address in .Y,
   ; so can be accessed via (pointer),y addressing.
   ; The Zeropage pointer is 
   ;    components_common::data_pointer.
   ; The mouse coordinates are in 
   ;    mouse_variables::curr_x_downscaled and
   ;    mouse_variables::curr_y_downscaled.
   ; in multiples of 4 pixels (half character size).
   ; Relevant information (such as the number of the tab which the mouse is over etc.) can be stored in
   ;    mouse_variables::curr_data_1 and
   ;    mouse_variables::curr_data_2.
   ; This information is then available in mouse events such as event_click or event_drag.
   ; Return:
   ; * in case of NO HIT: carry flag must be reset.
   ; * in case of HIT: carry flag must be set.
   ; The .Y register may be scrapped.
   .proc check_mouse
      clc
      rts
   .endproc


   ; Update the component's state when a click has occurred on the component.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   ; The relative index is given in
   ;    mouse_variables::curr_component_ofs,
   ; so that the component's data can be accessed by loading the latter into .Y and then (components_common::data_pointer),y.
   ; Relevant data produced by check_mouse is available in
   ;    mouse_variables::curr_data_1 and
   ;    mouse_variables::curr_data_2.
   ; The component's updated state is subsequently read by the parent panel's write subroutine.
   .proc event_click
      rts
   .endproc


   ; Update the component's state when the component is being "dragged".
   ; Here, dragging means either the left or right mouse button was pressed when the mouse was over the component,
   ; and the mouse is being moved while the button is still being held down.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   ; The relative index is given in
   ;    mouse_variables::prev_component_ofs,  (!! not curr_component_ofs)
   ; so that the component's data can be accessed by loading the latter into .Y and then (components_common::data_pointer),y.
   ; When the dragging operation was initiated by holding the left mouse button,
   ;    mouse_variables::curr_data_1
   ; is set to 0. If it was the right mouse button, it is set to 1.
   ; The vertical dragging distance within the last tick is given in
   ;    mouse_variables::delta_x and
   ;    mouse_variables::delta_y
   ; in two's complement and single pixel precision.
   ; The component's updated state can subsequently be read by the parent panel's write subroutine.
   .proc event_drag
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_EXAMPLE_ASM
