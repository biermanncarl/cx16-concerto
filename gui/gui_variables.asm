; Copyright 2021-2023 Carl Georg Biermann


.ifndef ::GUI_GUI_VARIABLES_ASM
::GUI_GUI_VARIABLES_ASM = 1

.scope gui_variables
   ; (INACTIVE)
   ; Set to nonzero value to request an update of GUI components (data transfer: underlying data -> GUI components).
   ; This is mainly intended for situations when the underlying data on several panels has changed, or it is not
   ; possible to call a panel's refresh routine directly.
   ; This refresh only acts on currently active panels!
   ; A refresh also includes a complete redraw.
   ; The refresh is done after event handling (mouse and keyboard) is finished within a tick.
   ; request_gui_refresh: .byte 0

   ; Set to nonzero value to request the digestion of current GUI values (data transfer: GUI components -> underlying data).
   ; This request must only be set by event handlers of components (like buttons, arrowed edits etc.) and should only be set
   ; when a value in the GUI has changed which needs to be transferred from the GUI to the underlying data.
   ; This flag is checked and cleared during the GUI's event handling.
   request_component_write: .byte 0

   ; Set to nonzero value to request a redraw of the components.
   ; The redraw is done after event handling (mouse and keyboard) is finished within a tick.
   request_components_redraw: .byte 0

   request_program_exit: .byte 0

   ; Which instrument is currently viewed in the synth page.
   current_synth_instrument: .byte 0


   ; These are variables located at the zero page.
   ; The abbreviations stand for "my zero page word B" or "my zero page byte D" and so on
   ; Each variable serves several purposes, depending on the context.
   .pushseg
      .zeropage

      ; my zero page words (main program)
      mzpwa:   .word 0
      mzpwd:   .word 0
      mzpwe:   .word 0   ; this is used mainly as a pointer for string and sprite operations
      mzpbh:   .byte 0

      ; The user interface also uses the "shared" zero page variables from the synth,
      ; which are safe to use in the main program
      mzpbe = concerto_synth::mzpbe
      mzpbf = concerto_synth::mzpbf
   .popseg
.endscope

.endif ; .ifndef ::GUI_GUI_VARIABLES_ASM
