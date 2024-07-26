; Copyright 2024 Carl Georg Biermann

.ifndef ::GUI_PANELS_PANELS_SONG_TEMPO_POPUP_ASM
::GUI_PANELS_PANELS_SONG_TEMPO_POPUP_ASM = 1

.include "common.asm"
.include "../../file_browsing.asm"

.scope song_tempo_popup
    ; popup blocks the whole screen, therefore this panel is "fullscreen" (for click detection)
    px = 0
    py = 0
    wd = 80
    hg = 60
    ; where the actual popup appears
        box_width = 18
        box_height = 14
        box_x = (80 - box_width) / 2
        box_y = (60 - box_height) / 2
    comps:
    .scope comps
        COMPONENT_DEFINITION button, ok, 41, box_y + box_height - 3, 6, A panel_common::lb_ok
        COMPONENT_DEFINITION button, cancel, 33, box_y + box_height - 3, 6, A panel_common::lb_cancel
        COMPONENT_DEFINITION drag_edit, ticks_first_eighth, 40+4, box_y+4, %00000000, 8, 127, 12, 0
        COMPONENT_DEFINITION drag_edit, ticks_second_eighth, 40+4, box_y+6, %00000000, 8, 127, 12, 0
        COMPONENT_DEFINITION drag_edit, beats_per_bar, 40+4, box_y+9, %00000000, 2, 16, 4, 0
        COMPONENT_LIST_END
    .endscope
    capts:
        .byte 16*COLOR_BACKGROUND+1, 40-5, box_y
        .word lb_song_tempo
        .byte 16*COLOR_BACKGROUND+1, 40+2, box_y+2
        .word lb_ticks
        .byte 16*COLOR_BACKGROUND+1, 40-7, box_y+4
        .word lb_first
        .byte 16*COLOR_BACKGROUND+1, 40-7, box_y+6
        .word lb_second
        .byte 16*COLOR_BACKGROUND+1, 40-7, box_y+9
        .word lb_beats
        .byte 0
    ; data specific to the panel
    lb_song_tempo: STR_FORMAT "song tempo"
    lb_beats: STR_FORMAT "beats/bar"
    lb_ticks: STR_FORMAT "ticks"
    lb_first: STR_FORMAT "1st 1/8"
    lb_second: STR_FORMAT "2nd 1/8"

    .proc clearArea
        lda #box_x-1
        sta guiutils::draw_x
        lda #box_y-1
        sta guiutils::draw_y
        lda #box_width+2
        sta guiutils::draw_width
        lda #box_height+2
        sta guiutils::draw_height
        lda #(16*COLOR_BACKGROUND)
        sta guiutils::color
        jsr guiutils::clear_rectangle
        rts
    .endproc

    .proc draw
        ; #optimize-for-size because this is pretty much the same code as for the file save/load popups but with different parameters
        inc kbd_variables::musical_keyboard_bypass
        jsr clearArea
        lda #box_x
        sta guiutils::draw_x
        lda #box_y
        sta guiutils::draw_y
        lda #box_width
        sta guiutils::draw_width
        lda #box_height
        sta guiutils::draw_height
        stz guiutils::draw_data1
        jsr guiutils::draw_frame

        ; update values in the GUI
        lda song_engine::timing::beats_per_bar
        STA_COMPONENT_MEMBER_ADDRESS drag_edit, beats_per_bar, coarse_value
        lda song_engine::timing::first_eighth_ticks
        STA_COMPONENT_MEMBER_ADDRESS drag_edit, ticks_first_eighth, coarse_value
        lda song_engine::timing::second_eighth_ticks
        STA_COMPONENT_MEMBER_ADDRESS drag_edit, ticks_second_eighth, coarse_value
        rts
    .endproc

    .proc write
        lda mouse_variables::curr_component_id
        asl
        tax
        jmp (@jmp_tbl, x)
    @jmp_tbl:
        .word button_ok
        .word button_cancel
        .word panel_common::dummy_subroutine ; drag edit: update when closing popup
        .word panel_common::dummy_subroutine ; drag edit: update when closing popup
        .word panel_common::dummy_subroutine ; drag edit: update when closing popup
    button_ok:
        jsr song_engine::multitrack_player::stopPlayback
        LDA_COMPONENT_MEMBER_ADDRESS drag_edit, beats_per_bar, coarse_value
        sta song_engine::timing::beats_per_bar
        LDA_COMPONENT_MEMBER_ADDRESS drag_edit, ticks_first_eighth, coarse_value
        sta song_engine::timing::first_eighth_ticks
        LDA_COMPONENT_MEMBER_ADDRESS drag_edit, ticks_second_eighth, coarse_value
        sta song_engine::timing::second_eighth_ticks
        jsr song_engine::change_song_tempo

        ; fall through to button_cancel, which closes the popup
    button_cancel:
        ; close popup
        jsr clearArea
        dec panels_stack_pointer
        jsr gui_routines__draw_gui
        rts
    .endproc

    refresh = panel_common::dummy_subroutine

    .proc keypress
        lda kbd_variables::current_key
        stz kbd_variables::current_key
        cmp #13 ; enter
        beq write::button_ok
        cmp #$1B ; escape
        beq write::button_cancel
        rts
    .endproc
.endscope

.endif ; .ifndef ::GUI_PANELS_PANELS_SONG_TEMPO_POPUP_ASM
