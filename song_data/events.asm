; Copyright 2023 Carl Georg Biermann

.ifndef SONG_DATA_EVENTS_ASM
SONG_DATA_EVENTS_ASM = 1

.scope events
    ; define the event types
    event_type_note_off = 0
    event_type_hard_off = 2 ; stops all notes within the clip immediately
    event_type_note_on  = 4
    ; TODO: effects 8 and above
.endscope

.endif ; .ifndef SONG_DATA_EVENTS_ASM
