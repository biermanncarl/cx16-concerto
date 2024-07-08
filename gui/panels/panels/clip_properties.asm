; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM

::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM = 1

.include "../../gui_macros.asm"
.include "common.asm"

.scope clip_properties
    px = 64
    py = 1
    wd = 15
    hg = 22

    comps:
    .scope comps
        COMPONENT_DEFINITION listbox, track_select, px, py, 9, 14, A 0, 0, 255, 0
        COMPONENT_DEFINITION drag_edit, instrument_sel, px+11, py+17, 0, 0, 31, 0, 0 ; TODO make nicer (ideally with named instruments, and combobox or similar)
        COMPONENT_DEFINITION checkbox, monophonic, px, py+19, 12, 0
        COMPONENT_DEFINITION checkbox, drum_pad, px, py+21, 10, 0
        COMPONENT_DEFINITION button, track_name, px, py+14, 10, A panel_common::lb_track_name
        COMPONENT_LIST_END
    .endscope

    capts:
        .byte CCOLOR_CAPTION, px, py+17
        .word panel_common::lb_instrument
        .byte CCOLOR_CAPTION, px+2, py+19
        .word lb_mono
        .byte CCOLOR_CAPTION, px+2, py+21
        .word lb_drum
        .byte 0

    lb_mono: STR_FORMAT "monophonic"
    lb_drum: STR_FORMAT "drum pad"

    .proc draw
        lda song_engine::clips::clips_vector
        sta comps::track_select + components::listbox::data_members::string_pointer
        lda song_engine::clips::clips_vector+1
        sta comps::track_select + components::listbox::data_members::string_pointer+1
        rts
    .endproc

    .proc write
        lda mouse_variables::curr_component_id
        asl
        tax
        jmp (@jmp_tbl, x)
    @jmp_tbl:
        .word @track_select
        .word @instrument
        .word @mono
        .word @drum_pad
        .word @track_name
    @track_select:
    @instrument:
    @mono:
    @drum_pad:
        rts
    @track_name:
        ; set string pointer to clip name
        ; TODO
        lda song_engine::clips::clips_vector
        sta track_name_popup::string_address
        lda song_engine::clips::clips_vector+1
        sta track_name_popup::string_address+1
        ; TODO: factor out the GUI stack operation
        ldx panels__panels_stack_pointer
        lda #panels__ids__track_name_popup
        sta panels__panels_stack, x
        inc panels__panels_stack_pointer
        jsr gui_routines__draw_gui
        rts
    .endproc


    .proc refresh
        ; lda components::dnd::dragables::notes::temporal_zoom
        ; LDY_COMPONENT_MEMBER combobox, zoom_level_indicator, selected_entry
        ; sta comps, y
        rts
    .endproc

    keypress = panel_common::dummy_subroutine
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_CLIP_PROPERTIES_ASM
