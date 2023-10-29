; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_COMPONENTS_ASM

::GUI_COMPONENTS_COMPONENTS_ASM = 1

.scope components
   .include "../../common/utility_macros.asm"

   .ifdef ::concerto_full_daw
      .include "configs/full_daw_gui.asm"
   .else
      .include "configs/only_synth_gui.asm"
   .endif

   ; Give each component type an id
   .scope ids
      ID_GENERATOR 0, ALL_COMPONENT_SCOPES
      no_component = 255
   .endscope

   ; Define an array which holds the data size of each component type
   .macro COMPONENT_SIZES s1, PARAMETER_LIST
      .ifblank s1
         .exitmacro
      .endif
      .byte .sizeof(s1::data_members) ; allocate one byte which holds the size of the component
      COMPONENT_SIZES PARAMETER_LIST
   .endmacro
   component_sizes: COMPONENT_SIZES ALL_COMPONENT_SCOPES

   ; Method lookup tables
   jump_table_draw: SCOPE_MEMBER_WORD_FIELD draw, ALL_COMPONENT_SCOPES
   jump_table_check_mouse: SCOPE_MEMBER_WORD_FIELD check_mouse, ALL_COMPONENT_SCOPES
   jump_table_event_click: SCOPE_MEMBER_WORD_FIELD event_click, ALL_COMPONENT_SCOPES
   jump_table_event_drag: SCOPE_MEMBER_WORD_FIELD event_drag, ALL_COMPONENT_SCOPES

.endscope

.endif ; .ifndef ::GUI_COMPONENTS_COMPONENTS_ASM
