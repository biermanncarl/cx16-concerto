; Copyright 2023 Carl Georg Biermann

; This file implements a simple heap which manages chunks of 256 bytes in size (no more, no less).
; If bigger chunks are needed, they can be daisy-chained using linked lists.
; The heap resides in banked RAM and has configurable min and max RAM bank.
; "Pointers" to chunks are communicated in the following way:
; .A contains the RAM bank number.
; .X contains the high byte of the 16-bit address in the 64k address space.
; The low byte of the address is implicitly zero (chunks are always aligned to the 256-bytes grid).

.scope heap

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

; need a ZP pointer which can be used as temporary variable by the functions in this scope
; TODO: check if we actually need this!
.ifndef zp_pointer
   .pushseg
   .zeropage
zp_pointer:
   .res 2
   .popseg
.elseif zp_pointer >= 256
   .error "zp_pointer must be on the zero page!"
.endif

num_chunks = 32 * (::heap_max_ram_bank - ::heap_min_ram_bank + 1) ; one RAM bank has 32 chunks of 256 bytes (8k of memory)

; bit field indicating which chunks are used and which ones aren't. In the 512k configuration, this would be 252 bytes
reservations:
   .res num_chunks / 8, 0
; index of the next unused chunk. bit 7 of high byte being set indicates memory full
first_unused_chunk:
   .word 0


; Allocates a chunk and returns the pointer to it in .A/.X (RAM page, high address)
; If successful, carry will be clear.
; If unsuccessful (no more chunks available), carry will be set.
.proc allocate_chunk
   local_byte = zp_pointer
   ; check if memory is full
   lda first_unused_chunk+1
   bpl :+
   sec ; signal memory full
   rts

:  ; first, determine high address and bank number from first_unused_chunk
   lda first_unused_chunk
   ; lower five bits are relevant for the high address
   and #%00011111
   clc
   adc #>RAM_WIN
   pha ; first part of the pointer is result is done
   ; next, shift bits into the ram bank index
   lda first_unused_chunk+1
   sta local_byte
   lda first_unused_chunk
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
   lda first_unused_chunk+1
   sta local_byte
   lda first_unused_chunk
   lsr local_byte
   ror
   lsr local_byte
   ror
   lsr local_byte
   ror
   tay
   ; now create bit mask for the specific bit
   lda first_unused_chunk
   and #%00000111
   jsr shift_bit
   sta local_byte
   ; and set the bit
   ora reservations, y
   sta reservations, y

   ; Look for the next free chunk and advance first_unused_chunk. Literally doing linear search here... Nice and simple.
@shift_bit_loop: ; expecting the bit mask in local byte and the byte index in .Y
   lda local_byte ; recall bit mask
   asl
   bcc @skip_byte_advance ; if bit was pushed out, we have to do some extra steps
   iny ; advance to next byte
   rol ; push bit back in
@skip_byte_advance:
   sta local_byte ; save bit mask
   inc first_unused_chunk
   lda first_unused_chunk+1
   adc #0
   sta first_unused_chunk+1
   ; now we need to check for memory full...
   cmp #(num_chunks / 256)
   bne @check_if_free ; this could be optimized, as the branch condition is assumed to be rare
   lda first_unused_chunk
   cmp #(num_chunks .mod 256)
   bne @check_if_free
   ; memory is full now (but we still allocated the last chunk, so can return successfully now)
   lda #$ff
   sta first_unused_chunk+1
   bra @finish
@check_if_free:
   ; check if new position is free
   lda local_byte ; recall bit mask
   and reservations, y
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
   ; TODO
   ; unset the reservation
   ; if necessary, move first_unused_chunk backwards
   rts
.endproc





; ============================
; COPY-PASTE FROM ZSM RECORDER
; ============================

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


; tests and sets a certain bit in a packed bit field
; .A index
; .X low address
; .Y high address
; return: zero flag is reset if bit was set
.proc test_and_set_bit
   stx zp_pointer ; store address in scrap register on ZP
   sty zp_pointer+1 ; for indirect bit field access
   tay ; keep copy of the index in .Y
   and #%00000111 ; get the position of the bit inside a byte
   jsr shift_bit ; create bit mask accordingly
   tax ; store bit mask in .X
   tya ; recall the copy of the index
   lsr ; get the byte index
   lsr
   lsr
   tay
   txa ; recall the bit mask
   and (zp_pointer), y ; test bit
   php
   txa ; recall the bit mask again
   ora (zp_pointer), y ; set bit
   sta (zp_pointer), y ; write back
   plp
   rts
.endproc


; sets a certain bit in a packed bit field
; .A index
; .X low address
; .Y high address
.proc set_bit
   stx zp_pointer ; store address in scrap register on ZP
   sty zp_pointer+1 ; for indirect bit field access
   tay ; keep copy of the index in .Y
   and #%00000111 ; create bit mask
   jsr shift_bit
   tax ; store bit mask in .X
   tya ; recall the copy of the index
   lsr ; get the byte index
   lsr
   lsr
   tay
   txa ; recall the bit mask
   ora (zp_pointer), y ; set bit
   sta (zp_pointer), y ; write back
   rts
.endproc


.popseg
.endscope
