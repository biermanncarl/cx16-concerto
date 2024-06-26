; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_ENGINE_SONG_ENGINE_ASM
::SONG_ENGINE_SONG_ENGINE_ASM = 1

.include "../dynamic_memory/vector_5bytes.asm"
.include "../common/x16.asm"

concerto_playback_routine = song_engine__simple_player__player_tick
.include "../synth_engine/concerto_synth.asm"

.scope song_engine

.include "timing.asm"
.include "events.asm"
.include "event_selection.asm"
.include "simple_player.asm"
.include "clips.asm"

.endscope


; "backward definition"
song_engine__simple_player__player_tick = song_engine::simple_player::player_tick

.endif ; .ifndef SONG_ENGINE_SONG_ENGINE_ASM
