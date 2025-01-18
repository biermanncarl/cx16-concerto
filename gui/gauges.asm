; Copyright 2025 Carl Georg Biermann

; The various gauges
; What I intend to do ...
; * playback time indicator
; * number of Concerto voices used
; * number of VERA oscillators used
; * number of FM voices used
; * overload indicator(s)
; * FM LFO clash
; * memory usage


.scope gauges

.proc tick
    ; can use gui_variables zeropage stuff, e.g. concerto_gui::gui_variables::mzpwa
    playback_marker_pos = concerto_gui::gui_variables::mzpwa

    ; playback time indicator
    lda concerto_gui::panels::global_navigation::active_tab
    bne :+
    lda song_engine::multitrack_player::detail::active
    bne :++
:   jmp @deactivate_playback_marker
:   lda song_engine::multitrack_player::detail::time_stamp
    sec
    sbc concerto_gui::components::dnd::dragables::notes::window_time_stamp
    tax
    lda song_engine::multitrack_player::detail::time_stamp+1
    sbc concerto_gui::components::dnd::dragables::notes::window_time_stamp+1
    bcc @deactivate_playback_marker
    ; zoom level
    ldy concerto_gui::components::dnd::dragables::notes::temporal_zoom
    beq @single_ticks
    @normal_zoom_level:
        jsr song_engine::timing::disassemble_time_stamp
        stx playback_marker_pos
        sta playback_marker_pos+1
        lda #3
        sec
        sbc concerto_gui::components::dnd::dragables::notes::temporal_zoom
        tay
        @leftshift_loop:
            bmi @leftshift_loop_end
            asl playback_marker_pos
            rol playback_marker_pos+1
            bcs @deactivate_playback_marker
            dey
            bra @leftshift_loop
        @leftshift_loop_end:
        ; add event_edit_pos_x offset
        lda playback_marker_pos
        clc
        adc #<(8*concerto_gui::components::dnd::dragables::notes::detail::event_edit_pos_x)
        sta playback_marker_pos
        lda playback_marker_pos+1
        adc #>(8*concerto_gui::components::dnd::dragables::notes::detail::event_edit_pos_x)
        @x_border = 8 * (concerto_gui::components::dnd::dragables::notes::detail::event_edit_pos_x + concerto_gui::components::dnd::dragables::notes::detail::event_edit_width)
        sta playback_marker_pos+1
        cmp #>@x_border
        bcc @update_playback_marker
        bne @deactivate_playback_marker
        ; high byte equal to border, need to check low byte
        lda playback_marker_pos
        cmp #<@x_border
        bcs @deactivate_playback_marker
        bra @update_playback_marker
    @single_ticks:
        cmp #0
        bne @deactivate_playback_marker
        txa
        cmp #concerto_gui::components::dnd::dragables::notes::detail::event_edit_width
        bcs @deactivate_playback_marker
        adc #concerto_gui::components::dnd::dragables::notes::detail::event_edit_pos_x
        stz playback_marker_pos+1
        asl
        rol playback_marker_pos+1
        asl
        rol playback_marker_pos+1
        asl
        rol playback_marker_pos+1
        sta playback_marker_pos
@update_playback_marker:
    ldx #6 ; number of marker sprites
    @sprite_loop:
        txa
        clc
        adc #(vram_assets::sprite_index_playback_marker_1-1)
        ldy #2
        jsr concerto_gui::guiutils::setupSpriteAccess
        lda playback_marker_pos
        sta VERA_data0
        lda playback_marker_pos+1
        sta VERA_data0
        lda VERA_data0 ; skip Y position
        lda VERA_data0
        lda #12 ; activate sprites
        sta VERA_data0
        dex
        bne @sprite_loop
    bra @playback_marker_done

@deactivate_playback_marker:
    ldx #6 ; number of marker sprites
    @deactivate_sprites_loop:
        txa
        clc
        adc #(vram_assets::sprite_index_playback_marker_1-1)
        ldy #6
        jsr concerto_gui::guiutils::setupSpriteAccess
        stz VERA_data0 ; deactivate sprites
        dex
        bne @deactivate_sprites_loop        

@playback_marker_done:
    rts
.endproc


.endscope
