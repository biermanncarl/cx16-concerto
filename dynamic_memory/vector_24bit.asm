; Copyright 2023 Carl Georg Biermann

; This file implements a dynamic vector containing 24-bit values based on doubly linked lists.
; These vectors are mainly intended to contain musical event data, but might serve other purposes,
; as well.
;
; As doubly linked lists, the vectors consist of chunks à 256 bytes located in banked RAM.
; The first four bytes of each chunk are dedicated to forward and backward pointers.
; The fifth byte contains the number of elements contained in the chunk.
; The sixth byte is reserved / left empty.
; All remaining 249 bytes contain up to 83 values à 24 bits / three bytes each.
;
; Empty chunks within the vector are not allowed, unless the vector is empty.
; In that case, the vector consists of a single empty chunk.
;
; Individual elements can be addressed via two different ways:
; * 3-byte pointer: B/H (2-byte pointer to a chunk) and the index inside the chunk. This is the addressing used by most of the functions. (.A is index inside the chunk, .Y/.X is the B/H pointer)
; * 2-byte B/H pointer to first chunk and 2-byte global index in the entire vector
; Those two modes could be converted into each other.
; Possibly, one part of the address will be implicitly given during some operations (e.g. by previous operations)
;
;
; Basic operations are:
; * create new vector
; * destroy vector
; * is empty
; * get first entry
; * is last entry
; * is first entry
; * get next entry
; * get previous entry (on average cheaper than get_next_entry because most of the time, no actual lookup is required!)
; * read entry (?)
; * write entry (?)
; * insert entry
; * delete entry
; * push_back
; * defragment vector (fill every chunk to the maximum size, release unnecessary chunks)
; * move entries from one vector to another (?)
; * ???
;
; Other files might extend this application-specifically.


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


.ifndef ::v24b_zp_pointer
   .pushseg
   .zeropage
v24b_zp_pointer:
   .res 2
   .popseg
.endif

.ifndef ::v24b_zp_pointer_2
   .pushseg
   .zeropage
v24b_zp_pointer_2:
   .res 2
   .popseg
.endif

; share our zp pointers with dll
::dll_zp_pointer = ::v24b_zp_pointer
::dll_zp_pointer_2 = ::v24b_zp_pointer_2
.include "doubly_linked_list.asm"

.scope v24b

.pushseg
.code

.include "../common/x16.asm"

; using the "saved" KERNAL registers for communication
value_l = r6L
value_m = r6H
value_h = r7L

.feature addrsize

zp_pointer = ::v24b_zp_pointer
.if (.addrsize(zp_pointer) = 2) .or (.addrsize(zp_pointer) = 0)
   .error "v24b_zp_pointer isn't a zeropage variable!"
.endif

zp_pointer_2 = ::v24b_zp_pointer_2
.if (.addrsize(zp_pointer_2) = 2) .or (.addrsize(zp_pointer_2) = 0)
   .error "v24b_zp_pointer_2 isn't a zeropage variable!"
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


; Writes values in a vector at given location
; Expects the pointer to a vector (B/H) in .A/.X
; Expects the L/M/H values in value_l / value_m / value_h
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
   cmp #83
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
   adc zp_pointer_2
   adc #6
   tay
   ; store values
   lda value_l
   sta (zp_pointer), y
   iny
   lda value_m
   sta (zp_pointer), y
   iny
   lda value_h
   sta (zp_pointer), y
   clc
   rts
.endproc


; Returns the value in a vector at given location (convenience function, mostly for testing?)
; Expects the pointer to a valid entry in .A/.X/.Y
; Returns the L/M/H values in value_l / value_m / value_h
.proc read_entry
   ; calculate offset from index
   sta zp_pointer
   asl
   adc zp_pointer
   adc #6
   ; set up access
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   tay
   lda (zp_pointer), y
   sta value_l
   iny
   lda (zp_pointer), y
   sta value_m
   iny
   lda (zp_pointer), y
   sta value_h
   rts
.endproc


; Writes values in a vector at given location (convenience function, mostly for testing?)
; Expects the pointer to a valid entry in .A/.X/.Y
; Expects the L/M/H values in value_l / value_m / value_h
.proc write_entry
   ; calculate offset from index
   sta zp_pointer
   asl
   adc zp_pointer
   adc #6
   ; set up access
   sty RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   tay
   lda value_l
   sta (zp_pointer), y
   iny
   lda value_m
   sta (zp_pointer), y
   iny
   lda value_h
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
; Expects the L/M/H values in value_l / value_m / value_h
; When it fails due to full heap, exits with carry set. Otherwise carry will be clear upon exit.
; Does not change the vector before the target position.
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
   cmp #83 ; is it full?
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
   ; The current chunk contains 83 elements --> keep 42 entries in the first chunk and move 41 entries into the second chunk.
   sta detail::temp_variable_b ; store B of source chunk
   stx zp_pointer+1
   stz zp_pointer
   jsr dll::get_next_element ; get target chunk's pointer
   stx zp_pointer_2+1
   stz zp_pointer_2
   tax ; store B of target chunk in .X
   ldy #(6+42*3) ; index of first payload byte to be moved
   clc
   ; The loop below could handle groups of 3 bytes at once in each iteration (--> partially unrolled). But as this loop is expected to be executed rarely, we optimize for code size.
@split_loop:
   lda detail::temp_variable_b
   sta RAM_BANK
   lda (zp_pointer), y  ;  ??? Don't we need to set up zp_pointer again (it was used by dll:: functions) ???
   pha ; store the value
   tya
   sbc #(41*3-1) ; move offset left to write into the target chunk. Minus one as carry is clear.
   tay
   stx RAM_BANK ; target chunk's B
   pla ; recall the value
   sta (zp_pointer_2), y
   tya
   adc #(41*3-1+1) ; move offset right to read from the source chunk. Minus one as carry is set. Plus one as we want to move on to the next byte of data.
   tay
   ; At the end of the data copy operation, the above ADC instruction will overflow (i.e. set carry)
   bcc @split_loop

   ldy #4
   lda #41
   sta (zp_pointer_2),y ; store chunk size in target chunk
   lda detail::temp_variable_b
   sta RAM_BANK
   lda #42
   sta (zp_pointer), y ; store chunk size in source chunk

   ; find out in which chunk the new element goes (old one or newly allocated one) and set up the pointer accordingly
   lda detail::temp_variable_a
   cmp #43 ; 43 is the lowest index that was moved into the new chunk
   bcc @element_goes_into_old_chunk
@element_goes_into_new_chunk:
   ; carry is set as per branch condition
   sbc #42 ; calculate the index in the new chunk
   sta detail::temp_variable_a
   lda zp_pointer_2+1 ; read new chunk's H
   sta zp_pointer+1 ; set up zp_pointer to read from new chunk
   stx RAM_BANK ; new chunk's B
@element_goes_into_old_chunk:
   ; RAM_BANK and zp_pointer is already set to the old chunk from above's code
@can_fit_another_element:
   ; expecting zp_pointer and RAM bank to be set up for access to the chunk where the new element goes (and we expect in that chunk to be enough space for a new element)
   ; furthermore, expecting the index where the new element will be inserted in temp_variable_a

   ; Increase the chunk's element count
   lda (zp_pointer), y ; .Y is still 4, from both branches above (with and without chunk split)
   tax ; remember how many elements are currently in the chunk
   inc
   sta (zp_pointer), y

   ; Make room for the new element by moving all existing elements over by one space.
   ; compute byte offset of highest data byte needing to be moved: multiply by 3 and add offset of first payload byte
   stx zp_pointer_2
   txa
   asl ; as the index cannot be higher than 82, carry will be clear in the next operations
   adc zp_pointer_2
   adc #6
   tay ; this will be the first byte we need to move
   ; compute byte offset of lowest data byte needing to be moved (same recipe)
   lda detail::temp_variable_a
   tax ; remember the original index
   ; multiply by 3
   asl ; as the maximum number expected in .A is 82 (decimal), carry will be clear
   adc detail::temp_variable_a
   adc #6 ; offset of first payload byte
   sta zp_pointer_2 ; store byte offset of lowest data byte to be moved

@move_loop:
   cpy zp_pointer_2
   beq @end_move_loop
   dey
   lda (zp_pointer), y
   iny
   sta (zp_pointer), y
   dey
   bra @move_loop
@end_move_loop:
   ; .Y is now set up to write to the new element's position
   lda value_l
   sta (zp_pointer), y
   iny
   lda value_m
   sta (zp_pointer), y
   iny
   lda value_h
   sta (zp_pointer), y

   clc
   rts
.endproc



.popseg
.endscope
