; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_GUI_REQUESTS_ASM

::GUI_GUI_REQUESTS_ASM = 1

.scope gui_requests
   ; Set to nonzero value to request a complete redraw of the GUI.
   ; The redraw is done after event handling (mouse and keyboard) is finished within a tick.
   request_gui_redraw: .byte 0

   ; Set to nonzero value to request an update of GUI components (data transfer: underlying data -> GUI components).
   ; This is mainly intended for situations when the underlying data on several panels has changed, or it is not
   ; possible to call a panel's refresh routine directly.
   ; This refresh only acts on currently active panels!
   ; A refresh also includes a complete redraw.
   ; The refresh is done after event handling (mouse and keyboard) is finished within a tick.
   request_gui_refresh: .byte 0

   ; Set to nonzero value to request the digestion of current GUI values (data transfer: GUI components -> underlying data).
   ; This request must only be set by event handlers of components (like buttons, arrowed edits etc.) and should only be set
   ; when a value in the GUI has changed which needs to be transferred from the GUI to the underlying data.
   ; This flag is checked and cleared during the GUI's event handling.
   request_component_write: .byte 0
.endscope

.endif ; .ifndef ::GUI_GUI_REQUESTS_ASM
