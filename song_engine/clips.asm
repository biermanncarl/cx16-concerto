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

