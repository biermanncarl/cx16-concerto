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
   .struct data_members
      .byte x
      .byte y
      .byte data
   .endstruct


   ; Draw the component. 
   ; A reference to the component's data is passed in as a zeropage pointer with index in .Y, so can be accessed via (pointer),y addressing.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   .proc draw
      rts
   .endproc


   ; Check if this component has been clicked.
   ; Incase it has been clicked, additional information can be returned which is then available in the event_click subroutine.
   ; A reference to the component's data is passed in as a zeropage pointer with index in .Y, so can be accessed via (pointer),y addressing.
   ; The Zeropage pointer is 
   ;    components_common::data_pointer.
   ; The mouse coordinates are in 
   ;    components_common::mouse_downscaled_x and
   ;    components_common::mouse_downscaled_y.
   ; in multiples of 4 pixels (half character size).
   ; Relevant information (such as the number of the tab which the mouse is over etc.) can be stored in
   ;    mouse_definitions::curr_data_1 and
   ;    mouse_definitions::curr_data_2.
   ; This information is then available in mouse events such as event_click or event_drag.
   .proc check_mouse
      rts
   .endproc


   ; Update the component's state when a click has occurred on the component.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   ; The relative index is given in
   ;    mouse_definitions::curr_component_ofs,
   ; so that the component's data can be accessed by loading the latter into .Y and then (components_common::data_pointer),y.
   ; Relevant data produced by check_mouse is available in
   ;    mouse_definitions::curr_data_1 and
   ;    mouse_definitions::curr_data_2.
   ; The component's updated state is subsequently read by the respective panel's write subroutine.
   .proc event_click
      rts
   .endproc


   ; Update the component's state when the component is being "dragged".
   ; Here, dragging means either the left or right mouse button was pressed when the mouse was over the component,
   ; and the mouse is being moved while the button is still being held down.
   ; The Zeropage pointer is
   ;    components_common::data_pointer.
   ; The relative index is given in
   ;    mouse_definitions::curr_component_ofs,
   ; so that the component's data can be accessed by loading the latter into .Y and then (components_common::data_pointer),y.
   ; When the dragging operation was initiated by holding the left mouse button,
   ;    mouse_definitions::curr_data_1
   ; is set to 0. If it was the right mouse button, it is set to 1.
   ; The vertical dragging distance within the last tick is given in
   ;    mouse_definitions::curr_data_2
   ; in two's complement and single pixel precision. (horizontal dragging distance is not added yet)
   ; The component's updated state is subsequently read by the respective panel's write subroutine.
   .proc event_drag
      rts
   .endproc

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_EXAMPLE_ASM
