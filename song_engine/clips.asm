; Copyright 2023-2024 Carl Georg Biermann

; This file implements functionality related to clips.
; Clips might become a central building block in the music maker software.

; The idea is that clips are assigned one instrument, which can be played either in mono or polyphonic mode.
; Effects apply to the whole clip, i.e. to all active notes playing.
; Voices from the Concerto engine are dynamically allocated and released when playing back a clip.

; A clip has the following properties:
; * Instrument id
; * Drum pad bool (either separate bool or special instrument id)
; * Mono/poly selector (affects voice pooling during playback)
; * Length in ticks
; * Starting time in ticks
; * End time in ticks
; * Loop length (0 for off)
; * (Color for visualization)
; * last visualization position (incl. zoom)
; * open or closed end (let note releases bleed across end of the clip?)
; approx. 16 bytes

; Furthermore, a clip contains a variable amount of music events data.
; These events are stored in a simple linear fashion comprised of
; * note-on
; * note-off
; * effects

; As the notes are dynamically allocated, events don't target any particular voice number.
; Note-on and note-off events target a certain pitch as in MIDI, and all other
; events are global to the clip.

; We will go 5 bytes per event, evenly spaced to facilitate backwards search.
; Each event holds the time stamp (16 bits), an event type (8 bits) and additional data (16 bits).

; Times are stored in 16-bit manner. 65535 ticks at 127 Hz is more than eight minutes,
; which is plenty to work with and a reasonable limitation for chiptune.


; Clip data layout:
; The header is stored separately from data stream.
; This has several advantages:
; * backwards search in stream data is simplified (no need to have extra logic to check if we're running into header data)
; * it simplifies browsing clips when there's a collection of clips (as in an arrangement)

; Drum pads
; Clips can be selected to operate as "drum pads". The basic idea is to make several instruments accessible from a single clip
; in a convenient way, so that drums can be programmed within a single clip.
; A certain range of instruments (e.g. 16 to 31) are accessible for drum pad clips.
; When a note in a drum pad clip is played, the lower nibble of the pitch is interpreted as the instrument
; (e.g. add 16 to arrive at the 16 "drum pad instruments"). The note is played at a certain predefined pitch
; (somewhere in the center of the MIDI pitch range). The high nibble is then added to that pitch
; so that the pitch of the sound can be slightly changed by playing in different repetitions of the 16 instruments.
; Of course, instruments accessible from the drum pad can still be used as normal instruments.
; It would be nice to add a visualization to the synth section showing up when one edits a instrument which can be
; played from the drum pad. (E.g. a green "DRUM PAD" lighting up below the instrument selector).




; Visualization of effects
; ========================
; Problem: effects can have multiple data fields
; * pop-up for extra data
; * data fields in rows
; * dedicated effects editing area on the screen (clicking just selects it)
; Problem: there is no limit on the number of effects --> difficult to display
; * two or three rows of effects
; * first come first served (effects can take up more width than 1 --> while rendering need variable per row of effects that shows where is blocked)
; * effects that don't fit go off-screen
; * there's an indicator showing when that happens (and where)
; * need custom characters (triangle to the top ^ for effects and triangle to the bottom v for "lost effect" indicator)
;
; Order of effects matters! (imagine set pitch + pitch bend)
;
; Possible character representations
; * vibrato set: 168 + 95
; * vibrato ramp: 168 + 47
; * vibrato ramp with limit: 168 + 117
; * volume ramp: inverted 169
; * pitch slide: 110 + 172 + 165 ?  (oder 126 pi for "pitch")
; * pitch set: 126 + 95


.ifndef ::SONG_ENGINE_CLIPS_ASM
::SONG_ENGINE_CLIPS_ASM = 1

.scope clips

clips_vector:
    .word 0
number_of_clips:
    .byte 0 ; potentially word in the future
max_number_of_clips = MAX_TRACKS ; for now, as long as we don't have arrangement view

; active clip/track in edit view, put here for variable visibility reasons
active_clip_id:
    .byte 0

clip_name_max_length = 9
clip_data_size = 30 ; want to keep it at 30 even though we use v32b (32 bytes) because v32b might be reduced to 31 bytes (or lower?) in the future

.struct clip_data
    ; we keep the clip name in the beginning so that this clip data format is compatible with listbox
    clip_name     .byte 10 ; account for the terminating zero byte
    event_ptr     .word ; pointer to v5b vector containing the event data in the clip
    instrument_id .byte
    monophonic    .byte
    drum_pad      .byte ; could this be merged with instrument id?
    .res 15 ; reserve some space for future data members
.endstruct
; size checks
.if .sizeof(clip_data) <> clip_data_size
    .error "clip_data has wrong size!"
.endif
.if .sizeof(clip_data::clip_name) <> (clip_name_max_length + 1)
    .error "clip_name has wrong size!"
.endif


; Initializes a clip with default values.
; Prior to this, v32b::accessEntry or similar has to be called.
.proc initializeClip
    ; create the events vector
    lda RAM_BANK
    pha
    jsr v5b::new
    pla
    sta RAM_BANK
    ldy #clip_data::event_ptr
    sta (v32b::entrypointer), y
    iny
    txa
    sta (v32b::entrypointer), y
    ; fall through to initializeClipName
.endproc
; Sets a clip's name to the default.
; Prior to this, v32b::accessEntry or similar has to be called.
.proc initializeClipName
    ldy #clip_data_size-1
@loop:
    lda #0
    cpy #7 ; length of default name, must be shorter than max
    bcs :+
    lda default_name, y
:   sta (v32b::entrypointer), y
    dey
    bpl @loop
    rts
default_name:
    .byte "unnamed"
.endproc


; Creates the clips_vector with a default clip
.proc initialize
    jsr v32b::new
    sta clips_vector
    stx clips_vector+1
    jsr v32b::accessEntry
    jsr initializeClip
    lda #1
    sta number_of_clips
    rts
.endproc


; Adds a clip if the maximum number of clips isn't reached yet.
.proc addClip
    lda number_of_clips
    cmp #max_number_of_clips
    bcs :+
    lda clips_vector
    ldx clips_vector+1
    jsr v32b::append_new_entry ; returns pointer to new entry in .A/.X
    jsr v32b::accessEntry
    jsr initializeClip
    inc number_of_clips
:   rts
.endproc


; expects index of clip in .Y
.proc accessClip
    lda clips_vector
    ldx clips_vector+1
    jsr dll::getElementByIndex
    jsr v32b::accessEntry
    rts
.endproc

; expects index of clip in .Y
; Returns vector in .A/.X
.proc getClipEventVector
    jsr accessClip
    ldy #clip_data::event_ptr+1
    lda (v32b::entrypointer), y
    tax
    dey
    lda (v32b::entrypointer), y
    rts
.endproc

; Expects that access to the clip has already been established.
; Returns vector in .A/.X
getCurrentEventVector = getClipEventVector+3


; Deletes all clip data and events data.
.proc clearClips
    ; destroy all event vectors
    ldy number_of_clips
@clips_loop:
    dey
    phy
    jsr getClipEventVector
    jsr v5b::destroy
    ply
    beq @clips_loop_exit
    bra @clips_loop
@clips_loop_exit:

    ; destroy all clips except one
    lda clips_vector
    ldx clips_vector+1
    jsr v32b::clear
    lda #1
    sta number_of_clips

    ; initialize one clip
    ldy #0
    jsr accessClip
    jsr initializeClip

    stz active_clip_id
    rts
.endproc

; Sends data of a clip to CHROUT.
; Expects clip id in .Y
.proc saveClipToFile
    jsr accessClip

    ; write header data
    ; Note that it doesn't make sense to save the pointer to the event vector.
    ; But for the sake of simplicity, we'll save it anyway.
    ldy #0
@header_loop:
    phy
    lda (v32b::entrypointer), y
    jsr CHROUT
    ply
    iny
    cpy #clip_data_size
    bne @header_loop

    ; save event data
    jsr getCurrentEventVector
    jsr v5b::get_first_entry
    bcs @finish_events
@events_loop:
    pha
    phx
    phy
    jsr v5b::read_entry
    jsr v5b::writeEntryToCHROUT
    ply
    plx
    pla
    jsr v5b::get_next_entry
    bcc @events_loop
@finish_events:
    lda #events::event_type_invalid
    sta events::event_type
    jsr v5b::writeEntryToCHROUT

    rts
.endproc

; Reads data of a clip from CHRIN
; Expects clip id in .Y
.proc readClipFromFile
    jsr accessClip
    ; backup event vector
    jsr getCurrentEventVector
    sta event_vector
    stx event_vector+1

    ; load header data
    ; Note that it doesn't make sense to read the pointer to the event vector.
    ; But for the sake of simplicity, we'll read it anyway and restore it afterwards.
    ldy #0
@header_loop:
    phy
    jsr CHRIN
    ply
    sta (v32b::entrypointer), y
    iny
    cpy #clip_data_size
    bne @header_loop

    ; overwrite event vector
    ldy #clip_data::event_ptr
    lda event_vector
    sta (v32b::entrypointer), y
    iny
    lda event_vector+1
    sta (v32b::entrypointer), y

    ; load event data
@events_loop:
    jsr v5b::readEntryFromCHRIN
    lda events::event_type
    cmp #events::event_type_invalid
    beq @events_loop_end
    lda event_vector
    ldx event_vector+1
    jsr v5b::append_new_entry
    bra @events_loop
@events_loop_end:

    rts

event_vector:
    .word 0
.endproc

.endscope

.endif ; .ifndef SONG_ENGINE_CLIPS_ASM
