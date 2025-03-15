; Copyright 2023 Carl Georg Biermann

; This file implements a simple heap which manages chunks of 256 bytes in size (no more, no less).
; If bigger chunks are needed, they can be daisy-chained using linked lists.
; The heap resides in banked RAM and has configurable min and max RAM bank.
; "Pointers" to chunks are communicated in the following way:
; Two values are needed, called B and H.
; .A contains the RAM bank number B.
; .X contains the high byte of the 16-bit address in the 64k address space, called H.
; The low byte of the address is implicitly zero (chunks are always aligned to the 256-bytes grid).

; Note that this implementation CANNOT deal with 2 MB of high RAM. Only up to 504k is possible (63 RAM banks).

.ifndef ::DYNAMIC_MEMORY_HEAP_ASM
::DYNAMIC_MEMORY_HEAP_ASM = 1


; need a ZP pointer which can be used as temporary variable by the functions in this scope
.ifndef ::heap_zp_pointer
   .pushseg
   .zeropage
::heap_zp_pointer:
   .res 2
   .popseg
.endif

.scope heap

heap_zp_pointer = ::heap_zp_pointer

.feature addrsize
.if (.addrsize(heap_zp_pointer) = 2) .or (.addrsize(heap_zp_pointer) = 0)
   .error "heap_zp_pointer isn't a zeropage variable!"
.endif

.include "../common/x16.asm"

.pushseg
.code


; min and max ram page can be configured externally
.ifndef ::heap_min_ram_bank
   ::heap_min_ram_bank = 1 ; 0 is reserved for the KENRAL, so let's make 1 the default
.endif
.ifndef ::heap_max_ram_bank
   ::heap_max_ram_bank = 63 ; 512k configuration
.endif




.scope detail

; returns a bit shifted left by the given number of times
; .A input number
; .A return value
; uses .A and .X
.proc shift_bit
   tax
   lda #1
   cpx #0
@loop:
   beq @end
   asl
   dex
   bra @loop
@end:
   rts
.endproc


num_chunks = 32 * (::heap_max_ram_bank - ::heap_min_ram_bank + 1) ; one RAM bank has 32 chunks of 256 bytes (8k of memory)

; bit field indicating which chunks are used and which ones aren't. In the 512k configuration, this would be 252 bytes
reservations:
   .res num_chunks / 8, 0
; index of the next unused chunk. bit 7 of high byte being set indicates memory full
first_unused_chunk:
   .word 0

.endscope ; scope detail

; Allocates a chunk and returns the pointer to it in .A/.X (RAM page, high address)
; If successful, carry will be clear.
; If unsuccessful (no more chunks available), carry will be set.
.proc allocate_chunk
   local_byte = heap_zp_pointer
   ; check if memory is full
   lda detail::first_unused_chunk+1
   bpl :+
   sec ; signal memory full
   rts

:  ; first, determine high address and bank number from first_unused_chunk
   lda detail::first_unused_chunk
   ; lower five bits are relevant for the high address
   and #%00011111
   clc
   adc #>RAM_WIN
   pha ; first part of the pointer is result is done
   ; next, shift bits into the ram bank index
   lda detail::first_unused_chunk+1
   sta local_byte
   lda detail::first_unused_chunk
   asl
   rol local_byte
   asl
   rol local_byte
   asl
   lda local_byte
   rol
   clc
   adc #heap_min_ram_bank
   pha ; second part of the pointer is done.

   ; Now we have to reserve the current chunk
   ; determine index of the byte we need to look at
   lda detail::first_unused_chunk+1
   sta local_byte
   lda detail::first_unused_chunk
   lsr local_byte
   ror
   lsr local_byte
   ror
   lsr local_byte
   ror
   tay
   ; now create bit mask for the specific bit
   lda detail::first_unused_chunk
   and #%00000111
   jsr detail::shift_bit
   sta local_byte
   ; and set the bit
   ora detail::reservations, y
   sta detail::reservations, y

   ; Look for the next free chunk and advance first_unused_chunk. Literally doing linear search here... Nice and simple.
@shift_bit_loop: ; expecting the bit mask in local byte and the byte index in .Y
   lda local_byte ; recall bit mask
   asl
   bcc @skip_byte_advance ; if bit was pushed out, we have to do some extra steps
   iny ; advance to next byte
   rol ; push bit back in
@skip_byte_advance:
   sta local_byte ; save bit mask
   inc detail::first_unused_chunk
   bne :+
   inc detail::first_unused_chunk+1
:  lda detail::first_unused_chunk+1
   ; now we need to check for memory full...
   cmp #(detail::num_chunks / 256)
   bne @check_if_free ; this could be optimized, as the branch condition is assumed to be rare
   lda detail::first_unused_chunk
   cmp #(detail::num_chunks .mod 256)
   bne @check_if_free
   ; memory is full now (but we still allocated the last chunk, so can return successfully now)
   lda #$ff
   sta detail::first_unused_chunk+1
   bra @finish
@check_if_free:
   ; check if new position is free
   lda local_byte ; recall bit mask
   and detail::reservations, y
   bne @shift_bit_loop
   ; if we hit a zero, we can stop and have found the next free chunk

@finish:
   ; pop pointer to newly allocated chunk from the stack
   pla
   plx
   clc ; signal success
   rts
.endproc

; Releases a chunk.
; Expects the pointer to the chunk in .A/.X (RAM page, high address).
; Doesn't check if the chunk was actually being used previously,
; but in any case, the chunk will be available for allocation after this function call.
.proc release_chunk
   local_byte = heap_zp_pointer
   local_byte_2 = heap_zp_pointer+1
   ; calculate chunk index from pointer
   sec
   sbc #heap_min_ram_bank
   sta local_byte_2 ; store RAM bank
   txa
   sec
   sbc #>RAM_WIN ; now should be a number from 0 to 31 (5 bits)
   tax ; store away lower 5 bits
   lda #0
   lsr local_byte_2
   ror
   lsr local_byte_2
   ror
   lsr local_byte_2
   ror
   sta local_byte
   txa ; add in lower 5 bits
   ora local_byte
   sta local_byte

   ; check if index is lower than first_unused_chunk
   lda local_byte_2
   cmp detail::first_unused_chunk+1
   bcc @update_first_unused_chunk ; high byte is smaller -> total number is smaller for sure
   bne @endof_first_unused_chunk_update ; if they weren't equal and incoming byte isn't smaller, it must be higher -> certainly no candidate
   ; check low byte, as high bytes are equal
   lda local_byte
   cmp detail::first_unused_chunk
   bcs @endof_first_unused_chunk_update
@update_first_unused_chunk:
   lda local_byte
   sta detail::first_unused_chunk
   lda local_byte_2
   sta detail::first_unused_chunk+1
@endof_first_unused_chunk_update:

   ; now unset the reservation bit
   ; calculate the bit mask
   lda local_byte
   and #%00000111
   jsr detail::shift_bit
   tax ; store bit mask
   lda local_byte
   lsr local_byte_2
   ror
   lsr local_byte_2
   ror
   lsr local_byte_2
   ror
   tay
   txa ; recall bit mask
   eor #$FF ; invert bit mask
   and detail::reservations, y
   sta detail::reservations, y

   rts
.endproc




.popseg
.endscope

.endif ; .ifndef ::DYNAMIC_MEMORY_HEAP_ASM
