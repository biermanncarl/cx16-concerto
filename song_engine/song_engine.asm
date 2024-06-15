; Copyright 2024 Carl Georg Biermann

.ifndef ::SONG_DATA_SONG_DATA_ASM
::SONG_DATA_SONG_DATA_ASM = 1

.include "../dynamic_memory/vector_40bit.asm"
.include "../common/x16.asm"

.scope song_engine

.include "timing.asm"
.include "events.asm"
.include "event_selection.asm"
.include "clips.asm"

.endscope

.endif ; .ifndef SONG_DATA_SONG_DATA_ASM
