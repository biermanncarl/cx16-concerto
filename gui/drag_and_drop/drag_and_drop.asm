; Copyright 2023 Carl Georg Biermann

; In this file, common code for different drag&drop use cases is implemented and the use-case specific code
; is connected up with the common code.

; The basic idea is that there are several types of dragable objects. Each of them can have exactly one list
; of dragable items (objects). The code in this file operates on these lists.

; * think about how to generalize different dynamic drag&drop use cases
;   * use cases:
;     * notes in clips
;     * effects
;     * clips in arrangement
;   * common things:
;     * drag & drop (D&D) in horizontal direction
;     * variable number of items
;     * "crowded" areas possible, with more items than can be resolved with current zoom level
;     * operations like deletion, copy&paste
;   * differences:
;     * height of hitbox (clips in arrangement might be chunkier)
;     * degrees of freedom (user selectable Y coordinate in clips and arrangement, software controlled Y coordinate for effects)
;     * resize not available for effects
;   * Which code could be shared?
;     * D&D object list: add objects with on-screen x/y position, horizontal size (3 bytes) and 2-byte identifier (uses 40bit vectors) --> limits total number of objects in a D&D environment to 64k (it's fine!)
;     * D&D object type identifier: global variable which will be set before D&D common functions are called
;     * type id serves as index into non-common functions (jump table)
;     * mouse-over detection (type dependent vertical size), returns object id (16-bit id)
;     * D&D operations: must be based on callbacks / jump tables
;       * constraints can be imposed by object type
;       * callbacks get "requested drag distance (x/y)", figure out the actual drag distance, update their internal items (e.g. move notes about), and 
;     * multi-selection can also be handled commonly! (drawing frames or shift-clicking to select multiple items, moving multiple items about)
;     * NOT: (L/R)click, delete, copy, cut, resize, (paste?): based on callbacks / jump-tables
;   * Code that cannot be shared:
;     * object list creation
;     * visualization
;     * updating of underlying data
;     * click events
;     * drag events
;     * resize events
;     * delete events
;     * create events
;
; How selections are handled
; --------------------------
; Several objects can be selected/unselected and the selected objects can be moved / manipulated in a group.
; There are three different ideas 
; * A bit field stores for each event in a clip whether it is selected or not
; * There is a separate vector of selected events. When events are selected, they get removed from the original clip and inserted into a "selected clip" (and vice versa for unselection)
; * There is a separate vector of selected events. When events are selected, a reference to the original vector is placed in that vector of selected events.
;
; After a considerable amount of studying the pros and cons of each option, I have decided to go with the second option (move selected events into separate vector).
; While each option has distinct advantages and disadvantages, I think what is on paper a disadvantage of the second method, can more easily be worked around
; than the disadvantages of the other methods.
; The big advantage of this method is the efficiency of moving and otherwise operating on the entire selection.
; When the selection is moved in time, this can be simply done by adding or subtracting from the time stamps of each event. The relative order of
; the events within the selection does not change.
; In contrast, for the other two approaches, the relative order of selected and unselected events can change, so that the
; whole vector of events needs to be re-sorted every time the selection is moved in the time-axis. And not only that: the vector that
; contains the information about which events are selected and which aren't becomes outdated and has to be updated every time!
; Of course, selecting and unselecting items is more costly with my method, compared to the other two. Essentially it's the cost
; of cut and paste, which can involve moving lots of events around. Especially the bit-field method is much more efficient in this particular aspect:
; find the correct bit and flip it -- done!
; However, I think that efficient motion in time outweighs the inefficient selection / unselection process, simply because
; you are expected to be moving events in time much more often than you are selecting/unselecting them. A single drag & drop operation consists of
; a single selection, many small move operations (which might appear to the human as a single operation, but it is divided into many small steps for the machine),
; and a single unselect operation.
;
; One annoyance with my method is that there is no single source of truth. As part of the events may be located in another clip, drawing and playback
; routines have to take events from both clips into account. This can be done with an abstraction which basically figures out which of the two clips contains the
; next event (one at a time) by comparing time stamps and event types.
;
; Last but not least, my approach, while it necessitates some extra implementation, on the other hand, has the potential to reuse large portions of its
; code by making heavy use of cut&paste operations which we need anyway. Also, the other two approaches need implementations of entirely new data structures,
; while my approach basically operates on a bunch of "virtual clips" / clipboards, which we need anyway.
;
; Some more thoughts on how to implement my method:
; As for each event type, selection and unselection requires different actions, the drag&drop code cannot do the bulk work of selecting/unselecting on its own.
; It will call the specific d&d type's routines for that purpose.
; For example, whenever a note is (un)selected, the corresponding note-off needs to be (un)selected, too.
; However, the d&d code must still know which events are selected and which ones aren't, to figure out things like "if an unselected event is dragged, all selected
; events become unselected first and then the selected event is moved (unless Ctrl is held down, in which case it gets added to the selection)" or "if a selected event is dragged, the entire selection
; is moved".
; For this purpose, the highest bit in the object id is reserved to mark its selection status.
; This is also needed in the communication with the respective type's routines, as they rely on correct commands being issued (the code may crash if we 
; try to unselect an event which hasn't been selected previously).
; 


; Note that not all events that have an id have their own hitbox (note-offs)


.include "../dynamic_memory/vector_40bit.asm"

.scope dnd ; drag'n'drop

.include "notes.asm"
.include "effects.asm"
.include "clips.asm"

; API variables and values
; ========================
; This variable must be set to the desired type of objects before any function call from this scope. (Move to zeropage?)
active_type:
   .res 1

num_types = 3
notes_type = 0
effects_type = 1
clips_type = 2

; variables to communicate objects which are stored in the object lists
object_pos_x = v40b::value_0 ; on-screen-position in multiples of 4 pixels
object_pos_y = v40b::value_1 ; on-screen-position in multiples of 4 pixels
object_width = v40b::value_2 ; on-screen width in multiples of 4 pixels (height is implied by active_type)
object_id_l = v40b::value_3 ; identifier (low)
object_id_h = v40b::value_4 ; identifier (high)

.include "lookup_tables.asm"

.scope detail
; addresses to vectors of objects which can be dragged (B/H)
object_vector_b:
   .res num_types
object_vector_h:
   .res num_types

.proc load_object_list
   ldy active_type
   lda detail::object_vector_h, y
   tax
   lda detail::object_vector_b, y
   rts
.endproc

; Move these to zeropage?
temp_variable_a:
   .res 1
temp_variable_b:
   .res 1
.endscope


; This function sets up some things before drag and drop features can be used.
.proc initialize
   ldy #(num_types-1)
@init_loop:
   phy
   ; create object vectors
   jsr v40b::new
   ply
   sta detail::object_vector_b, y
   txa
   sta detail::object_vector_h, y
   dey
   cpy #255
   bne @init_loop
   rts
.endproc


; Remove all objects from an onject list
.proc clear_objects
   jsr detail::load_object_list
   jsr v40b::clear
   rts
.endproc


; Add an object to a list
; Expects object data in the API variables.
; If successful, carry is clear. Carry is set when the operation failed due to full heap.
.proc add_object
   jsr detail::load_object_list
   jsr v40b::append_new_entry
   rts
.endproc


; Checks if the mouse is currently over an object.
; Expects mouse position in .A/.X (x position in multiples of 4 pixel, y position in multiples of 4 pixel)
; Carry will be set if no match was found. If a match was found, carry is clear.
; Returns the id of the object in .A/.X (low/high).
.proc mouse_over
   sta temp_variable_a
   stx temp_variable_b
   jsr detail::load_object_list
   jsr v40b::get_first_entry
   bcs @end
@loop:
   pha
   phx
   phy
   jsr v40b::read_entry
   ; Check Y coordinate
   lda temp_variable_b
   cmp object_pos_y ; carry will be set if mouse is at the height or below the object
   bcc @continue
   ; Now check if mouse is at the height or above the object. For that we subtract the object height from the mouse coordinate and then compare
   ldy active_type
   sbc object_heights, y ; carry is already set
   dec ; subtract one more than the object height
   cmp object_pos_y ; carry will be clear if mose is above "one line below" the object (that is, in other words, on the object or above it)
   bcs @continue
   ; Check X coordinate (same formulas as above)
   sta temp_variable_a
   cmp object_pos_x
   bcc @continue
   sbc object_width
   dec
   cmp object_pos_x
   bcs @continue
   ; We got a hit!
   ply ; tidy up the stack
   plx
   pla
   lda object_id_l ; load the return value
   ldx object_id_h
   ; clc ; Carry needs to be cleared to signal success. (carry is already cleared as per branching condition above)
   rts

@continue:
   ply
   plx
   pla
   jsr v40b::get_next_entry
   bcc @loop
   ; sec ; No success - need to set carry to signal "no success". Luckily, carry is already set as per branching condition.

@end:
   rts
.endproc


.endscope
