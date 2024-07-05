; Copyright 2023-2024 Carl Georg Biermann

.ifndef ::SONG_DATA_EVENTS_ASM
::SONG_DATA_EVENTS_ASM = 1

.include "../dynamic_memory/vector_5bytes.asm"

.scope events
    ; define the event types
    event_type_note_off = 0
    event_type_hard_off = 2 ; stops all notes within the clip immediately
    event_type_note_on  = 4
    event_type_invalid = 255 ; enables invalidating events without deleting just yet to retain addresses of subsequent events
    ; TODO: effects 8 and above

    ; Data member meaning of 40bit values in note data
    event_time_stamp_l = v5b::value_0
    event_time_stamp_h = v5b::value_1
    event_type = v5b::value_2
    event_data_1 = v5b::value_3
    event_data_2 = v5b::value_4

    ; aliases for specific event types
    note_pitch = event_data_1 ; for note-on and note-off events
    note_velocity = event_data_2 ; for note-on
.endscope

.endif ; .ifndef ::SONG_DATA_EVENTS_ASM
