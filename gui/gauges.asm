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
    ; playback time indicator
    lda song_engine::multitrack_player::detail::active
    lda song_engine::multitrack_player::detail::time_stamp
    lda song_engine::multitrack_player::detail::time_stamp+1
    lda concerto_gui::components::dnd::dragables::notes::detail::event_edit_pos_x
    ; first sprite
    lda #vram_assets::sprite_index_playback_marker_1
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    ; second sprite
    lda #vram_assets::sprite_index_playback_marker_2
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    ; third sprite
    lda #vram_assets::sprite_index_playback_marker_3
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    ; fourth sprite
    lda #vram_assets::sprite_index_playback_marker_4
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    ; fifth sprite
    lda #vram_assets::sprite_index_playback_marker_5
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    ; sixth sprite
    lda #vram_assets::sprite_index_playback_marker_6
    ldy #6
    jsr concerto_gui::guiutils::setupSpriteAccess
    lda #12
    sta VERA_data0
    rts
.endproc


.endscope
