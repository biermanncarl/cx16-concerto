; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_ENGINE_ASM
::SONG_ENGINE_SONG_ENGINE_ASM = 1

.include "../dynamic_memory/vector_5bytes.asm"
.include "../dynamic_memory/vector_32bytes.asm"
.include "../common/x16.asm"

concerto_playback_routine = song_engine__simple_player__playerTick
.include "../synth_engine/concerto_synth.asm"

.define MAX_TRACKS 16

.scope song_engine

; Vectors of currently processed events on the GUI (defined here so that the player can see them, too)
.pushseg
.zeropage
unselected_events_vector:
   .res 2
selected_events_vector:
   .res 2
.popseg

.include "timing.asm"
.include "events.asm"
.include "event_selection.asm"
.include "clips.asm"
.include "simple_player.asm"

change_song_tempo = timing::recalculate_rhythm_values ; TODO: actually recalculate ALL time stamps (lossy for sub-1/32 values)

.endscope


; "backward definition"
song_engine__simple_player__playerTick = song_engine::simple_player::playerTick

.endif ; .ifndef SONG_ENGINE_SONG_ENGINE_ASM
