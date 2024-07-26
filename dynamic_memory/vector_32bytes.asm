; Copyright 2024 Carl Georg Biermann

; UNTESTED (no unit tests)

; This file is a layer on top of doubly linked list, providing more convenient access to the storage
; provided in doubly linked list.
; At the time of implementation, there are a few applications for this, all of which would require
; less than 32 bytes of storage per entry:
; * clip data, i.e. information about clip length, instrument, mono/poly, event vector etc.
; * file list in a file browser
; * list of instrument names
;
; At the time of writing, banked memory is not the main concern, but instead low memory.
; Therefore, an implementation is chosen which takes up as little as possible low memory,
; while providing good speed, while being wasteful of banked memory.
; If in the future, banked memory becomes more valuable, a more sophisticated implementation
; can be considered (e.g. a clone of v5b for the infrastructure with modifications to the data access).
; #optimize-for-memory-usage

; IMPORTANT
; The current implementation does not allow for an empty vector. Each valid vector contains at least one entry.
; Users must figure out how to deal with that.


.ifndef ::DYNAMIC_MEMORY_VECTOR_32BYTES_ASM
::DYNAMIC_MEMORY_VECTOR_32BYTES_ASM = 1

.include "doubly_linked_list.asm"

; If we limit this to 31 bytes instead of 32, we could have 8 entries inside one page, which would be nice.
; Right now, we only have one entry per page anyway...
.scope v32b
.pushseg
.code

; where does the data begin within a DLL element
data_offset = 4

.pushseg
.zeropage
; Pointer which is used to access entries of v32b vectors. The low byte is always data_offset, as being initialized by the "new" routine.
entrypointer: .res 2
entrypointer_h = entrypointer+1
.popseg


; returns pointer to new vector in .A/.X
.proc new
    lda #data_offset
    sta entrypointer ; nobody ever needs to touch that value again
    jmp dll::create_list
.endproc

; destroys a vector
; expects pointer to vector in .A/.X
; The pointer is invalid after this operation.
destroy = dll::destroy_list
clear = dll::clear_list
append_new_entry = dll::append_new_element
get_last_entry = dll::get_last_element
delete_entry = dll::delete_element
; etc. add as required



; Sets up RAM_BANK and entrypointer such that (entrypointer),y addressing will result in the first
; entry being accessed, starting from y=0.
; Expects pointer to vector in .A/.X
.proc accessEntry
    sta RAM_BANK
    stx entrypointer_h
    ; low byte of entrypointer is already set by "new".
    rts
.endproc

; Sets up RAM_BANK and entrypointer such that (entrypointer),y addressing will result in the last
; entry being accessed, starting from y=0.
; Expects pointer to vector in .A/.X
.proc accessLastEntry
    jsr dll::get_last_element
    sta RAM_BANK
    stx entrypointer_h
    ; low byte of entrypointer is already set by "new".
    rts
.endproc

; Can be called after access to another entry of the vector has been established (e.g. accessEntry).
; If the next entry doesn't exist, carry will be set upon return, clear otherwise.
.proc accessNextEntry
    lda RAM_BANK
    ldx entrypointer_h
    jsr dll::get_next_element
    sta RAM_BANK
    stx entrypointer_h
    cmp #0
    ; carry is always set because every number from 0-255 is >= 0
    beq :+
    clc
:   rts
.endproc

; Can be called after access to another entry of the vector has been established (e.g. accessLastEntry).
; If the previous entry doesn't exist, carry will be set upon return, clear otherwise.
.proc accessPreviousEntry
    lda RAM_BANK
    ldx entrypointer_h
    jsr dll::get_previous_element
    sta RAM_BANK
    stx entrypointer_h
    cmp #0
    ; carry is always set because every number from 0-255 is >= 0
    beq :+
    clc
:   rts
.endproc

; Can be called after access to another entry of the vector has been established (e.g. accessEntry).
.proc isFirstEntry
    lda RAM_BANK
    ldx entrypointer_h
    jsr dll::is_first_element
    rts
.endproc

; Can be called after access to another entry of the vector has been established (e.g. accessEntry).
.proc isLastEntry
    lda RAM_BANK
    ldx entrypointer_h
    jsr dll::is_last_element
    rts
.endproc

; This function interprets the content of the v32b as a zero-terminated string and inserts a character
; at a given position.
; accessEntry or similar have to be called first.
; .A : the character to be inserted
; .Y : the position inside the string where to insert.
.proc insertCharacter
    sty @target_position+1 ; self-modifying code
    pha

    ; find end of string
    dey
@find_end_loop:
    iny
    lda (entrypointer),y
    bne @find_end_loop

@insert_loop:
    lda (entrypointer),y
    iny
    sta (entrypointer),y
    dey
@target_position:
    cpy #0 ; the actual character position is put in place of the #0 by self-modifying code
    beq @insert_loop_end
    dey
    bra @insert_loop
@insert_loop_end:
    pla
    sta (entrypointer),y
    rts
.endproc

.popseg
.endscope

.endif ; .ifndef ::DYNAMIC_MEMORY_VECTOR_32BYTES_ASM
