; Copyright 2023 Carl Georg Biermann

; This file implements a dynamic vector containing 40-bit values (5 bytes) based on doubly linked lists.
; These vectors are mainly intended to contain musical event data, but might serve other purposes,
; as well.
;
; As doubly linked lists, the vectors consist of chunks à 256 bytes located in banked RAM.
; The first four bytes of each chunk are dedicated to forward and backward pointers.
; The fifth byte contains the number of elements contained in the chunk.
; The sixth byte is reserved / left empty.
; All remaining 250 bytes contain up to 50 values à 40 bits / five bytes each.
;
; Empty chunks within the vector are not allowed, unless the vector is empty.
; In that case, the vector consists of a single empty chunk.
;
; Individual elements can be addressed via two different ways:
; * "Direct pointer": 3-byte pointer: B/H (2-byte pointer to a chunk) and the index inside the chunk. This is the addressing used by most of the functions.
;   The order of bytes is I,H,B
;   When communicating with registers, .A is index inside the chunk, .Y/.X is the B/H pointer (B is in .Y, H in .X)
; * "Vector+Index": 2-byte B/H pointer to first chunk and 2-byte global index in the entire vector
; Those two modes could be converted into each other.
; Please that of the upper 16-bit index, only 15 bits are supported. The most significant bit must be zero.
; Possibly, one part of the address will be implicitly given during some operations (e.g. by previous operations)
; As for the doubly linked list, a B value of zero indicates an invalid pointer.


; POTENTIAL OPTIMIZATIONS:
; ==============================================================================
; Score board for functions which are better off using B in .A vs. B in .Y
; B in .A: is_first_entry, is_last_entry, (get_next_entry, get_previous_entry)
; B in .Y:
; ==============================================================================
;
;
; We could set up the elements backwards within the chunks:
; The index within a chunk decreases while going to the next element, and also the "chunk size" decreases when more elements are added.
; The order in which the elements are stored is still lower end first within the chunk.
; Pro:
; * The possibly more-often used get_next_entry gets the efficiency advantage over get_previous_entry, as the bounds check for that is now just compare with zero vs. complicated banked RAM lookup.
; * The "zero elements" state becomes valid and means "full chunk". This makes it *slightly* easier to check whether a chunk is full.
; Con:
; * It's more complicated and less obvious, possibly less maintainable?
; * Not clear yet whether "get_next_entry" is really called more often than "get_previous_entry".

.ifndef ::DYNAMIC_MEMORY_VECTOR_40BIT_ASM
::DYNAMIC_MEMORY_VECTOR_40BIT_ASM = 1

.ifndef ::v40b_zp_pointer
   .pushseg
   .zeropage
::v40b_zp_pointer:
   .res 2
   .popseg
.endif

.ifndef ::v40b_zp_pointer_2
   .pushseg
   .zeropage
::v40b_zp_pointer_2:
   .res 2
   .popseg
.endif

; share our zp pointers with dll
::dll_zp_pointer = ::v40b_zp_pointer
::dll_zp_pointer_2 = ::v40b_zp_pointer_2
.include "doubly_linked_list.asm"

.scope v40b

.pushseg
.code

.include "../common/x16.asm"

; using the "saved" KERNAL registers for communication
value_0 = r6L
value_1 = r6H
value_2 = r7L
value_3 = r7H
value_4 = r8L

payload_offset = 6
entry_size = 5
max_entries_per_chunk = 50

.feature addrsize

zp_pointer = ::v40b_zp_pointer
.if (.addrsize(zp_pointer) = 2) .or (.addrsize(zp_pointer) = 0)
   .error "v40b_zp_pointer isn't a zeropage variable!"
.endif

zp_pointer_2 = ::v40b_zp_pointer_2
.if (.addrsize(zp_pointer_2) = 2) .or (.addrsize(zp_pointer_2) = 0)
   .error "v40b_zp_pointer_2 isn't a zeropage variable!"
.endif

.scope detail
temp_variable_a:
   .res 1
temp_variable_b:
   .res 1
temp_variable_c:
   .res 1
.endscope


; create a new vector
; returns the vector's address in .A/.X.
; Carry will be set when the operation failed due to full heap memory.
.proc new
   jsr dll::create_list
   bcs @end
   ; Carry flag will be retained through all following operations.
   ; depend on implementation of create_list: they set up zp_pointer and RAM BANK such that we can directly access the new element
   pha ; remember pointer's B
   ; create_list also sets up .Y to the fourth element
   iny
   lda #0
   sta (zp_pointer), y ; set vector's length to zero
   pla ; restore pointer's B
@end:
   rts
.endproc


; destroys a vector
; expects pointer to vector in .A/.X
; The pointer is invalid after this operation.
destroy = dll::destroy_list


; Clears all entries from a vector. (Untested!)
; expects pointer to vector in .A/.X
.proc clear
   ; get rid of excess chunks
   pha
   phx
   jsr dll::get_next_element
   jsr dll::destroy_list ; !! we depend on destroy_list only deleting list elements to the right and the one passed in, not any ones to the right
   plx
   pla
   ; set pointer to next list element to 0
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   lda #0
   sta (zp_pointer)
   ldy #1
   sta (zp_pointer),y
   ; set count of elements to zero
   ldy #4
   sta (zp_pointer),y
   rts
.endproc


; Writes values in a vector at given location
; Expects the pointer to a vector (B/H) in .A/.X
; Expects the values in value_0 through value_4
; If successful, carry is clear upon return.
; Carry will be set if the operation failed due to full heap.
.proc append_new_entry
   ; set up access to last element
   jsr dll::get_last_element
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   ; check if there's any space left
   ldy #4
   lda (zp_pointer), y
   cmp #max_entries_per_chunk
   bne @append_element
   ; need new chunk
   lda RAM_BANK
   jsr dll::append_new_element
   bcc :+ ; check if the element was successfully allocated
   rts
:  ; set up new chunk
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   ldy #4
   lda #0
   ; sta (zp_pointer), y ; not needed as we will write the new increased value to that location anyway
@append_element:
   ; expecting zp_pointer and RAM_BANK set up for access of target chunk, and .Y set up for access of the entry count
   ; expecting .A to contain current count of elements in the chunk
   inc
   sta (zp_pointer), y ; store new element count
   ; calculate offset
   dec
   sta zp_pointer_2
   asl
   asl
   adc zp_pointer_2
   adc #payload_offset
   tay
   ; store values
   lda value_0
   sta (zp_pointer), y
   iny
   lda value_1
   sta (zp_pointer), y
   iny
   lda value_2
   sta (zp_pointer), y
   iny
   lda value_3
   sta (zp_pointer), y
   iny
   lda value_4
   sta (zp_pointer), y
   clc
   rts
.endproc


; Returns the value in a vector at given location (convenience function, mostly for testing?)
; Expects the pointer to a valid entry in .A/.X/.Y
; Returns the values in value_0 through value_4
.proc read_entry
   ; calculate offset from index
   sta zp_pointer
   asl
   asl
   adc zp_pointer
   adc #payload_offset
   ; set up access
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   tay
   lda (zp_pointer), y
   sta value_0
   iny
   lda (zp_pointer), y
   sta value_1
   iny
   lda (zp_pointer), y
   sta value_2
   iny
   lda (zp_pointer), y
   sta value_3
   iny
   lda (zp_pointer), y
   sta value_4
   rts
.endproc


; Writes values in a vector at given location (convenience function, mostly for testing?)
; Expects the pointer to a valid entry in .A/.X/.Y
; Expects the values in value_0 through value_4
.proc write_entry
   ; calculate offset from index
   sta zp_pointer
   asl
   asl
   adc zp_pointer
   adc #payload_offset
   ; set up access
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   tay
   lda value_0
   sta (zp_pointer), y
   iny
   lda value_1
   sta (zp_pointer), y
   iny
   lda value_2
   sta (zp_pointer), y
   iny
   lda value_3
   sta (zp_pointer), y
   iny
   lda value_4
   sta (zp_pointer), y
   rts
.endproc


; Checks whether a vector is empty.
; Expects the vector's address (B/H) in .A/.X
; If vector is empty, carry is set. Otherwise it's clear.
; Preserves .A/.X
.proc is_empty
   ; as empty chunks are not allowed unless the vector is empty, we just need to look at the element count in the first chunk to know whether it's empty or not
   pha ; save B
   sta RAM_BANK
   stx zp_pointer+1
   lda #4
   sta zp_pointer
   lda (zp_pointer)
   clc
   bne :+
   sec
:  pla ; recall B
   rts
.endproc


; Sets the .A/.X/.Y pointer up to read the first entry of a vector
; Expects the pointer to the vector in .A/.X.
; Returns pointer to first element in .A/.X/.Y.
; If the first element exists, carry is clear. Carry is set when it doesn't exist.
.proc get_first_entry
   jsr is_empty
   tay
   lda #0
   rts
.endproc


; Checks if a given element is the last one of a vector.
; Expects the pointer to the element in .A/.X/.Y
; If it's the last element, carry is set. Otherwise clear.
; Preserves .A/.X/.Y
.proc is_last_entry
   pha
   phy
   tya
   jsr dll::is_last_element
   ply
   pla
   bcc @end ; if it's not the last chunk, it's not the last entry for sure (because empty chunks are not allowed)
   ; sty RAM_BANK ; already done by is_last_element
   ; stx zp_pointer+1 ; already done by is_last_element
   pha
   lda #4
   sta zp_pointer
   lda (zp_pointer) ; look up length of the list
   dec ; length = index of laste entry + 1 --> subtracting one to make it equal the last index
   sta zp_pointer
   pla
   cmp zp_pointer
   clc
   bne @end ; if they're not equal, the given element is not the last one
   sec
@end:
   rts
.endproc


; Checks if a given element is the last one of a vector.
; Expects the pointer to the element in .A/.X/.Y
; If it's the last element, carry is set. Otherwise clear.
; Preserves .A/.X/.Y
.proc is_first_entry
   cmp #0
   bne @not_first ; if entry index isn't zero, it can't be the first entry
   pha
   phy
   tya
   jsr dll::is_first_element
   ply
   pla
   rts
   ; carry is set by is_first_element if it's the first element in the DLL. As the index is zero, it must be the first entry.
@not_first:
   clc
   rts
.endproc


; Returns the pointer to the next entry.
; If the next entry does not exist, carry will be set; clear otherwise.
; Expects the pointer to a valid entry in .A/.X/.Y
; Returns the pointer to the next entry in .A/.X/.Y
; (.A/.X/.Y are not preserved when they already point to the last entry)
.proc get_next_entry
   ; check if it's the last entry in this block
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   ldy #4
   pha ; save index of current entry
   lda (zp_pointer), y ; read "chunk length"
   dec ; decrement chunk length, as index of last entry is one less than chunk length
   sta zp_pointer_2 ; store chunk length -1
   pla ; recall index of current entry
   cmp zp_pointer_2
   beq @next_chunk
   ; not the last entry within the chunk -> just increment 1
   inc
   ldy RAM_BANK ; recall B, which is still valid as we don't transition to the next chunk
   ; .X is still set to H
   clc
   rts
@next_chunk:
   ; the index of the next entry will be zero -> no need to remember current index
   lda RAM_BANK
   jsr dll::get_next_element
   cmp #0 ; if .A is equal to zero, carry will be set --> no need to set it explicitly
   beq @end ; NULL pointer?
   clc ; need to clear carry if next dll element is not NULL
   tay
   lda #0 ; set index to first in the new dll element
@end:
   rts
.endproc


; Returns the pointer to the previous entry.
; If the previous entry does not exist, carry will be set; clear otherwise.
; Expects the pointer to a valid entry in .A/.X/.Y
; Returns the pointer to the previous entry in .A/.X/.Y
; (.A/.X/.Y are not preserved when they already point to the first entry)
.proc get_previous_entry
   ; check if it's the first entry in this block
   cmp #0
   beq @previous_chunk
   ; not the first entry within the chunk -> just decrement 1
   dec
   clc
   rts
@previous_chunk:
   ; we can discard the entry index in .A now
   tya
   jsr dll::get_previous_element
   cmp #0 ; if .A is equal to zero, carry will be set --> no need to set it explicitly
   beq @end ; NULL pointer?
   ; not a NULL pointer --> need to find the last element in the current chunk
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   ldy #4
   lda (zp_pointer),y ; read chunk size
   dec ; index of last element is one less (note that we are relying on every chunk having a size of at least one)
   ldy RAM_BANK ; recall B
   clc
@end:
   rts
.endproc


; Inserts a value in a vector at given location (i.e. in front of the given entry)
; Expects the pointer to a valid entry in .A/.X/.Y
; Expects the values in value_0 through value_h
; When it fails due to full heap, exits with carry set. Otherwise carry will be clear upon exit.
.proc insert_entry
   ; First, we try to insert an element at the back of the current chunk.
   ; If that's not possible, we split the current chunk in two by moving half of the entries to a new chunk.
   ; The new element is then inserted in either of the two chunks, depending on its index.
   ; -------------
   ; Check if the chunk is full or not
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   sta detail::temp_variable_a ; store index of the entry
   ldy #4
   lda (zp_pointer), y ; read chunk length
   cmp #max_entries_per_chunk ; is it full?
   bne @can_fit_another_element

   ; chunk is full --> split it.
   lda RAM_BANK
   jsr dll::is_last_element
   pha
   phx
   bcc @insert_chunk
@append_chunk_at_end:
   ; it's the last element, so use append_new_element
   jsr dll::append_new_element
   bra @new_chunk_available
@insert_chunk:
   jsr dll::get_next_element
   jsr dll::insert_element_before
@new_chunk_available:
   plx
   pla
   bcc :+
   rts ; return early because of full heap (both append_new_element and insert_element_before set carry if the heap is full)
:  ; Now set up the new chunk.
   ; The current chunk contains 50 elements --> keep 25 entries in the first chunk and move 25 entries into the second chunk.
   @new_chunk_entry_count = max_entries_per_chunk / 2
   @old_chunk_entry_count = max_entries_per_chunk - @new_chunk_entry_count
   sta detail::temp_variable_b ; store B of source chunk
   stx zp_pointer+1
   stz zp_pointer
   jsr dll::get_next_element ; get target chunk's pointer
   stx zp_pointer_2+1
   stz zp_pointer_2
   tax ; store B of target chunk in .X
   ldy #(payload_offset+@old_chunk_entry_count*entry_size) ; index of first payload byte to be moved
   clc

@split_loop:
   lda detail::temp_variable_b
   sta RAM_BANK
   lda (zp_pointer), y  ;  ??? Don't we need to set up zp_pointer again (it was used by dll:: functions) ???
   pha ; store the value
   tya
   sbc #(@old_chunk_entry_count*entry_size-1) ; move offset left to write into the target chunk. Minus one as carry is clear.
   tay
   stx RAM_BANK ; target chunk's B
   pla ; recall the value
   sta (zp_pointer_2), y
   tya
   adc #(@old_chunk_entry_count*entry_size-1+1) ; move offset right to read from the source chunk. Minus one as carry is set. Plus one as we want to move on to the next byte of data.
   tay
   ; At the end of the data copy operation, the above ADC instruction will overflow (i.e. set carry)
   bcc @split_loop

   ldy #4
   lda #@new_chunk_entry_count
   sta (zp_pointer_2),y ; store chunk size in target chunk
   lda detail::temp_variable_b
   sta RAM_BANK
   lda #@old_chunk_entry_count
   sta (zp_pointer), y ; store chunk size in source chunk

   ; find out in which chunk the new element goes (old one or newly allocated one) and set up the pointer accordingly
   lda detail::temp_variable_a
   cmp #@old_chunk_entry_count ; compare .A with the lowest index that was moved into the new chunk
   bcc @element_goes_into_old_chunk
@element_goes_into_new_chunk:
   ; carry is set as per branch condition
   sbc #@old_chunk_entry_count ; calculate the index in the new chunk
   sta detail::temp_variable_a
   lda zp_pointer_2+1 ; read new chunk's H
   sta zp_pointer+1 ; set up zp_pointer to read from new chunk
   stx RAM_BANK ; new chunk's B
@element_goes_into_old_chunk:
   ; RAM_BANK and zp_pointer is already set to the old chunk from above's code
@can_fit_another_element:
   ; expecting zp_pointer and RAM bank to be set up for access to the chunk where the new element goes
   ; and we expect in that chunk to be enough space for a new element

   ; Increase the chunk's element count
   lda (zp_pointer), y ; .Y is still 4, from both branches above (with and without chunk split)
   inc
   sta (zp_pointer), y ; store new chunk size

   ; Make room for the new element by moving all existing elements over by one space.
   ; compute byte offset of the highest byte that needs to be moved: multiply by 5 and add offset of first payload byte
   dec ; The chunk size before insertion is the index of the last element after insertion ...
   dec ; ... but we want the index of the last chunk before insertion. (both can be optimized away with below ADC instruction)
   sta zp_pointer_2
   asl ; as the index cannot be higher than 49, carry will be clear in the next operations
   asl
   adc zp_pointer_2
   adc #(payload_offset+entry_size-1) ; we want the top byte of the last entry
   tay ; this will be the offset of the first byte we need to move
   ; Compute byte offset of lowest entry needing to be moved (same recipe)
   lda detail::temp_variable_a
   ; multiply by 5
   asl ; as the maximum number expected in .A is 49 (decimal), carry will be clear
   asl
   adc detail::temp_variable_a
   adc #(payload_offset-1) ; offset of the first payload byte that we don't want to copy anymore
   sta zp_pointer_2 ; store end location of copy operations

   sec
@move_loop:
   lda (zp_pointer), y
   tax ; store data byte in .X
   tya
   adc #(entry_size-1) ; minus one because carry is set, carry will be reset after this
   tay
   txa ; recall data byte from .X
   sta (zp_pointer), y
   tya
   sbc #(entry_size+1-1) ; move on to the next byte, depending on carry being already set, minus one because carry is reset
   tay
   cpy zp_pointer_2 ; carry will be set after this command, throughout the execution (.Y is always >= zp_pointer_2)
   bne @move_loop
@end_move_loop:
   iny
   ; .Y is now set up to write to the new element's position
   lda value_0
   sta (zp_pointer), y
   iny
   lda value_1
   sta (zp_pointer), y
   iny
   lda value_2
   sta (zp_pointer), y
   iny
   lda value_3
   sta (zp_pointer), y
   iny
   lda value_4
   sta (zp_pointer), y

   clc
   rts
.endproc



; Deletes a value from a vector at given location (i.e. in front of the given entry)
; Expects the pointer to a valid entry in .A/.X/.Y
; Does not change the vector before the target position, but the current entry might not be a valid one after deletion.
; If the vector is empty (after deletion), carry will be set. Clear otherwise.
.proc delete_entry
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   ldy #4
   sta zp_pointer_2 ; remember the index of the entry to be deleted
   lda (zp_pointer),y
   dec
   sta (zp_pointer),y
   beq @chunk_is_empty

   ; Move data inside the chunk
   ; compute start of copy operation
   lda zp_pointer_2
   asl
   asl
   adc zp_pointer_2
   adc #(payload_offset+entry_size) ; we start reading data one entry to the right
   pha ; index of the first byte we need to move

   ; compute end of copy operation
   lda (zp_pointer),y ; this was decreased previously, but that gives us the index of the last element (before deletion) anyway (number of elements - 1 is index of last element)
   sta zp_pointer_2
   asl
   asl
   adc zp_pointer_2
   adc #(payload_offset+entry_size) ; this is the first byte we do not want to copy anymore
   sta zp_pointer_2

   ply
@copy_loop:
   cpy zp_pointer_2
   beq @end
   ; read
   lda (zp_pointer),y
   tax
   ; move to previous entry
   tya
   sec ; could be optimized away
   sbc #entry_size
   tay
   ; write
   txa
   sta (zp_pointer),y
   ; move index up to the next byte to be moved
   tya
   clc ; could be optimized away
   adc #(entry_size+1)
   tay
   bra @copy_loop

@chunk_is_empty:
   ; check if the vector is empty --> in that case we don't delete the chunk
   lda RAM_BANK
   jsr is_empty
   bcc :+
   rts
:  ; delete the current element of the list
   jsr dll::delete_element
@end:
   clc
   rts
.endproc


; Converts an entry from the "vector+index" representation to "direct pointer" representation.
; Expects the pointer to the vector (B/H) in .A/.X.
; Expects the 16-bit index in value_0, value_1 (low, high).
; Returns the direct pointer to a valid entry in .A/.X/.Y.
; The index in value_0 and value_1 is NOT preserved.
; If the access is out of range, carry is set, otherwise clear.
.proc convert_vector_and_index_to_direct_pointer
   ; set up read access to vector
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   
   ; search for the correct chunk
@chunk_search:
   ldy #4
   lda value_0
   sec
   sbc (zp_pointer), y
   sta value_0
   bcs :+
   dec value_1
   bmi @end_of_chunk_search
:  ; continue on to the next chunk
   lda RAM_BANK
   ldx zp_pointer+1
   jsr dll::get_next_element ; could be optimized for speed by doing the transition "manually"
   cmp #0
   beq @out_of_range
   sta RAM_BANK
   stx zp_pointer+1
   bra @chunk_search

@out_of_range:
   sec
   rts

@end_of_chunk_search:
   ; we created an overflow in value_0. Need to add back what we subtracted to know the index into the chunk.
   ;lda value_0 ; - can be optimized away ... value is still in .A
   clc
   adc (zp_pointer), y ; that's the index into the chunk done.
   ldy RAM_BANK
   ldx zp_pointer+1
   clc
   rts
.endproc


; Converts an entry from "direct pointer" representation to the "vector+index" representation.
; Expects the direct pointer to a valid entry in .A/.X/.Y.
; Returns the pointer to the vector in value_0, value_1 (B/H).
; Returns the 16-bit index in value_0, value_1 (low, high).
.proc convert_direct_pointer_to_vector_and_index
   ; TODO
   rts
.endproc


; Defragments a vector, i.e. moves data inside a vector such that no chunk except the last one has empty space in it.
; Excess chunks are released.
; Expects the pointer to the vector in .A/.X (B/H).
.proc defragment
   ; TODO
   ; strategy: have two running pointers, one for reading (will move "faster") and one for writing (will fill every chunk).
   ; the reading pointer will be incremented according to "normal" rules,
   ; the writing pointer will be incremented until chunk is full.
   ; in the end, each chunk length is increased to 83 except the last one, and all unneeded chunks are released.
   rts
.endproc



.popseg
.endscope

.endif ; .ifndef ::DYNAMIC_MEMORY_VECTOR_40BIT_ASM
