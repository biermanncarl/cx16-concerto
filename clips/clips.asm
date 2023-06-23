; Copyright 2023 Carl Georg Biermann

; This file implements functionality related to clips.
; Clips might become a central building block in the music maker software.

; The idea is that clips are assigned one instrument, which can be played either in mono or polyphonic mode.
; Effects apply to the whole clip, i.e. to all active notes playing.
; Voices from the Concerto engine are dynamically allocated and released when playing back a clip.

; A clip has the following properties:
; * Instrument id
; * Mono/poly selector
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

; As the voices are dynamically allocated, events don't target any channel.
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



; Playing back a clip
; ===================
; There need to be several steps per tick:
; * process note-offs and hard note-offs
; * process note-ons
; * process effects
; First, all note-offs of all clips are processed, so that all freed up voices can be reused immediately, possibly by other clips.
; Then, all note-ons and effects of all clips are processed.
; The effects must come last as otherwise, there would not be a way to immediately start a note with an effect applied to it.
; (And conversely, there is no point in applying an effect to a note that is going to be dead within the same tick, anyway.)
;
; Editing routines must take care that events within a tick are stored in this exact order (note-off, note-on, effects)
; That way, the first step can simply process events until a non-note-off event is encountered.
;
; The maximum possible polyphony is 16, the hard limit placed by the Concerto engine.
; For each Concerto channel, we store which clip player is using it. That way, when a note-off event is received,
; it needs to search for channels with the same player id, and among those for channels that have the correct pitch set.
; --> this is tedious for finding notes! (imagine hard note-offs or effects that need to be applied to all notes in a clip!)
;
; Store active voices in a 16 byte array ! per playing clip ? --> lots of RAM used just for this
;
; Note length vs. note-off
; * note length would facilitate "set and forget" playing of notes (player software will handle note-off after countdown, independent of clip/track that initiated it)
; * note length might need some additional infrastructure, but could be slightly more CPU efficient at note-offs
;


; Drawing a clip
; ==============
; The visualization needs to keep hold of the following variables:
; * Start time of the window, relative to the clip start in ticks
; * Starting pitch
; * Zoom state (only in time direction)
; We'll do a very crude approach to drawing: simply start looking at events from the start of the clip.
; Have a permanently updated buffer of active notes (for collision detection when click/drag events occur).
; As soon as parsing the clip data hits starting time, we begin drawing events (effects and active notes).
;
; How to "bin" events into grid positions?
; * Nearest neighbor (?) (add half of grid size, discard lest significant part)
; * Draw left to right (time axis), column by column
; * Drawing one column:
;   * buffer for each row in current column (basically one byte per row), which determines what to draw there:
;     * no note --> draw background
;     * note-on --> draw petscii 111 (if we want extra character for note-off, that would be petscii 112)
;     * held note (note-on in earlier column) --> draw petscii 183
;     * short note (less than one column long) --> draw normal note-on (but distinction is important for internal processing)
;     * multiple events, note-on was last --> draw petscii 166 (?)
;     * multiple events, note-off was last --> draw petscii 124 (?)
;     * alternative visualization: tomxp's mockup
; * at beginning of drawing routine, initialize all rows' cells to "empty"
; * first phase of parsing (up to left border of screen)
;   * just toggle note on/off for each row, depending on note-on and note-off events received
;   * as soon as a "wait" event reaches or crosses beginning of frame, transition to second phase of parsing
; * second phase of parsing (actual drawing)
;   * need to maintain a timer "column time" (ticks passed in the parsed data since the start of the column)
;   * REPEAT until all columns are covered
;     * WHILE column time is bigger than column width
;       * subtract column width from column time
;       * draw one column with current row states (note states)
;       * update note states when necessary (turn multiple events/short notes into either empty or note-on, depending on which was seen last, turn note-ons into hold)
;     * WHILE column time is smaller than column width
;       * process incoming events
;         * disregard off-screen note-ons and note-offs
;         * update row/note states that are on-screen
;           * note on into empty cell -> note-on
;           * note-off into held note -> empty (can be overwritten by another note-on. this is fine)
;           * note-off into note-on -> short note
;           * note-on into short note -> multiple events, last on
;           * note-off into multiple events -> multiple events, last off
;         * for wait events: add wait length to column time
;
; Note length vs. note-off
; * note-length facilitates direct drawing of notes (no need to wait for note-off) (separate handling of cramped environments will be more difficult, though)
;


; Visualization of Velocity
; =========================
; Options:
; * knobs on sticks (ala Ableton Live) -> difficult with precision, difficult in text mode
; * spin/drag edits -> harder to grasp visually, easier in text
; Problem: positioning in dense environments
; * pop-up spin edit on click or key-press?
; * visualization: color-coding of velocity (brighter means lower velocity, ala Ableton Live)
; 
;
;



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




; Editing a clip
; ==============
; Simple:
; * insert and delete events at time stamps
; * move single events around
; Advanced:
; * arbitrary selection
; * drag and drop
; * moving events around (pitch - easy, time - difficult)
; * cut/copy and paste
;
; We need to work with intermediate buffers to manage all of this
; Maybe can be broken up in "Simple" operations with a virtual "clipboard"
;
; Click detection strategies
; --------------------------
; * build a dynamic list of clickable objects (on-screen position, size, pointer to event) during visualization
;   * advantageous for effects, whose on-screen position does not directly follow from the event data (or does it?)
;     --> depending on how we visualize effects, this might be the only viable option
;   * all selectable events are considered size-1 vertically and variable size horizontally
; * parse event stream when a click happens
;   * only need to search for note-ons and note-offs on respective pitch
;
; Highlighting / Selection
; ------------------------
; * Maintain two lists:
;   * one ordered bit mask, which has one bit per event, on or off
;     --> efficiently interpretable during event drawing (important!)
;   * unordered "vector"/list of 24-bit pointers to events that have been selected
;     --> efficiently interpretable during insertion / deletion
;     * is it needed, though?
;       * it's possible to infer pointers efficiently from index (at least for moderately sized lists)
; * Note-offs are automatically (un)selected with note-ons (no way for the user to select/unselect them manually)
;
; Operations on selections
; ------------------------
; * All operations are reduced to elementary (single event) cut/paste and move operations, merge and split wait events
; * Events are cut into virtual clipboard (preserving their relative timing)
; * Inserted at new time
; * Perhaps later (only if necessary): exceptions for compact selections (contiguous block of events), which can be moved simply by increasing/decreasing wait tick counts
; * maybe "insert" and "delete" clipboard algorithms could be improved/made more efficient by not moving the same events over and over for every item being inserted or deleted...
;
; Drag & Drop
; -----------
; * There's a few variables in place for drag/drop.
;   * Kind of operation
;     * note length
;     * note / selection drag (if previously unselected, selects, and drags at the same time)
;     * selection box (drawing a box to select multiple notes / events)
;     * event drag
;     * spin/drag edit drag
;   * depending on which kind of operation: relevant starting coordinates, current position (or just relative motion)
;



; Key technologies
; ================
; * dynamically positionable spin/drag edits
; * 40-bit vector
;   * insert & delete
;   * efficient search
;   * zero-terminated (high byte zero suffices)
;   * defrag function
;




; Clips data concept
; ==================
; * 40 bits per event
; * 16 bits time stamp
; * 8 bits event type
; * 16 bits data
; * we should leave room for possible new event types implemented in the future (especially effects)
; * proposal:
;   * Soft note-off: 0 (pitch 8 bits)
;   * Hard note-off (affects all channels): 2 (no data)
;   * Note-on: 4 (pitch 8 bits, velocity 6 bits)
;   * Effects: 16 upwards
;     * Set pitchbend-pos: 16
;     * Set pitchbend-rate: 17
;     * etc...


