; Copyright 2023 Carl Georg Biermann

; This file implements a doubly linked lists (DLLs), consisting of chunks of 256 bytes size.
; The first four bytes of each element are used for the forward- and backward referencing pointers,
; and the other 252 bytes are payload.
; This file does NOT implement routines to manage the content of the chunks in a DLL.

; The structure of the header in each element is as follows
;
; |      0      |      1      |       2       |       3       |  other 252 bytes
; |-------------|-------------|---------------|---------------|-------------------
; | Successor B | Successor H | Predecessor B | Predecessor H |     Payload ...
;
; Where B and H are the two parts of the pointer to the successor and predecessor, respectively.
; As RAM bank 0 is used by the KERNAL, and thus not usable, we consider B=0 a null pointer.
; The first element in a list has no predecessor, hence its pointer to the predecessor must
; be NULL. Similarly, the pointer to the successor of the last element must be NULL.
;
; (Note that a B/H pair can be considered NULL even if H is non-zero.)


.scope dll

.pushseg
.zeropage
zp_pointer:
   .res 2
zp_pointer_2:
   .res 2
.popseg
; zp_pointer is shared with heap.asm.
.include "heap.asm"

.pushseg
.code

.scope detail
temp_variable_a:
   .res 2
.endscope


; Creates the first element of a new list.
; Returns the pointer (B/H) to the first and only element in .A/.X
.proc create_list
   ; basically allocate a new chunk and set predecessor and successor to NULL
   jsr heap::allocate_chunk
   pha
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer
   lda #0
   sta (zp_pointer)
   ldy #1
   sta (zp_pointer), y
   iny
   sta (zp_pointer), y
   iny
   sta (zp_pointer), y
   pla
   rts
.endproc

; Destroys a list.
; Expects pointer (B/H) to an element in .A/.X
; Responsibility of setting any remaining pointers to the first element to NULL is upon the user.
.proc destroy_list
@loop:
   ; end of list?
   cmp #0
   beq @end
   ; need to get pointer to next element before releasing current one
   pha
   phx
   jsr get_next_element
   sta zp_pointer_2
   stx zp_pointer_2+1
   plx
   pla
   ; release current element and point.A/.X to the next element
   jsr heap::release_chunk
   lda zp_pointer_2
   ldx zp_pointer_2+1
   bra @loop
@end:
   rts
.endproc



; Expects (non-NULL) pointer (B/H) to an element in .A/.X
; Returns pointer to the next element in .A/.X (may be a NULL-pointer)
.proc get_next_element
   sta RAM_BANK ; NOT backing up RAM bank here
   stz zp_pointer
   stx zp_pointer+1
   ldy #1
   lda (zp_pointer), y
   tax
   lda (zp_pointer)
   rts
.endproc

; Expects (non-NULL) pointer (B/H) to an element in .A/.X
; Returns pointer to the next element in .A/.X (may be a NULL-pointer)
.proc get_previous_element
   sta RAM_BANK ; NOT backing up RAM bank here
   stz zp_pointer
   stx zp_pointer+1
   ldy #3
   lda (zp_pointer), y
   tax
   dey
   lda (zp_pointer), y
   rts
.endproc



; Expects (non-NULL) pointer (B/H) to an element in .A/.X
; Upon return, the carry flag is set if it is the last element
; The pointer is preserved.
.proc is_last_element
   pha
   phx
   jsr get_next_element
   cmp #0
   clc
   bne :+
   sec
:  plx
   pla
   rts
.endproc

; Expects (non-NULL) pointer (B/H) to an element in .A/.X
; Upon return, the carry flag is set if it is the first element
; The pointer is preserved.
.proc is_first_element
   pha
   phx
   jsr get_previous_element
   cmp #0
   clc
   bne :+
   sec
:  plx
   pla
   rts
.endproc


; Inserts a new element in front of the given element.
; The given element can be any element of a list.
; Expects pointer (B/H) to an element in .A/.X
; Returns the pointer to the new element in .A/.X
.proc insert_element_before
   ;
   ; We have a list as follows:                               .A/.X
   ;                                                            |
   ;                                                            V
   ;            +---------+               +---------+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +---------+
   ;
   ; And we want to insert a new Element V between U and W:
   ;
   ;            +---------+               +---------+      +=========+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |ELEMENT V| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +=========+      +---------+
   ;
   ; Note that Element U could be NULL if Element W is the first one in the list.

   ; Back up pointer to Element U by reading W's predecessor
   sta RAM_BANK
   stx zp_pointer_2
   stz zp_pointer_2+1
   lda (zp_pointer_2)
   sta detail::temp_variable_a ; store U.B
   ldy #1
   lda (zp_pointer_2),y
   sta detail::temp_variable_a+1 ; store U.H

   ; Now allocate V and link it bidirectionally with W
   jsr heap::allocate_chunk
   pha ; save V.B
   stx zp_pointer+1 ; save V.H
   stz zp_pointer
   ldy #3
   txa
   sta (zp_pointer_2),y ; store V.H in W's predecessor
   pla ; recall V.B
   dey
   sta (zp_pointer_2),y ; store V.B in W's predecessor

   ; Now switch to V and initialize its pointers
   tax ; and save V.B during bank switch
   lda RAM_BANK ; this is W.B
   stx RAM_BANK
   sta (zp_pointer) ; store W.B in V's successor
   ldy #1
   lda zp_pointer_2
   sta (zp_pointer),y ; store W.H in V's successor
   iny
   lda detail::temp_variable_a ; copy U.B to V's predecessor
   sta (zp_pointer),y
   iny
   lda detail::temp_variable_a+1 ; copy U.H to V's predecessor
   sta (zp_pointer),y

   ; check if U is NULL
   lda detail::temp_variable_a
   beq @null_end
   ldx RAM_BANK ; store V.B during bank switch
   sta RAM_BANK
   lda detail::temp_variable_a+1
   sta zp_pointer_2+1 ; don't need to zero out the low byte of the pointer, that was done earlier
   txa ; recall V.B
   sta (zp_pointer_2) ; store V.B in U's successor
   ldy #1
   lda zp_pointer+1 ; recall V.H
   sta (zp_pointer_2),y ; store V.H in U's successor
   tax ; V.H into .X for function output
   lda (zp_pointer_2) ; V.B into .A for function output
   rts

@null_end:
   lda RAM_BANK ; load V.B for function output
   ldx zp_pointer+1 ; load V.H for function output
   rts
.endproc


; Inserts a new element at the end of the list.
; The given element can be any element of a list.
; Expects pointer (B/H) to an element in .A/.X
.proc append_new_element
   ; first: find the last element of the list
@find_end_loop:
   jsr is_last_element
   bcs @find_end_loop_done
   jsr get_next_element
   bra @find_end_loop
@find_end_loop_done:

   sta RAM_BANK ; set up for writing to the (currently) last element
   stx zp_pointer_2+1
   stz zp_pointer_2

   jsr heap::allocate_chunk ; allocate new last element
   stx zp_pointer+1 ; store H of old chunk
   stz zp_pointer
   ;tax ; store B of old chunk away in .X

   ; write new pointer to previously-last element
   sta (zp_pointer_2) ; write B of new last element
   pha
   txa
   ldy #1
   sta (zp_pointer_2), y ; write H of new last element
   pla

   ; write pointer to new last element
   ldx RAM_BANK ; load B of old element
   sta RAM_BANK
   iny
   txa
   sta (zp_pointer), y ; store B of old last element
   iny
   lda zp_pointer_2+1
   sta (zp_pointer), y ; store H of old last element
   ; now set successor of new last element to NULL
   lda #0
   sta (zp_pointer)
   ldy #1
   sta (zp_pointer),y

   rts
.endproc







; Deletes an element from a list. (Also the first one?)
; Expects pointer to an element in .A/.X
; Returns pointer to new element in .A/.X
.proc delete_element
   ; TODO
   rts
.endproc




; ===================
; OBSOLETE FUNCTIONS
; ===================

; Expects pointer (B/H) in .A/.X
; Upon return, the zero flag is set if it is a null pointer
; The pointer is preserved.
.macro IS_NULL_PTR_ZEROFLAG
   .local @end
   cmp #0
   bne @end
   cpx #0
@end:
.endmacro

; Expects pointer (B/H) in .A/.X
; Upon return, the carry flag is set if it is a null pointer
; The pointer is preserved.
.proc is_null_ptr
   cmp #0
   bne @not_null
   cpx #0
   bne @not_null
   sec
   rts
@not_null:
   clc
   rts
.endproc

; TODO: I think we only need add_element_before to be able to deal with adding in front of the first element, and append_new_element at the end of the list
; But I'll keep this function for now for learning and testing ....
; Inserts a new element after the given element.
; The given element can be any element of a list except the last one.
; Expects pointer (B/H) to an element in .A/.X
.proc insert_element_after
   ; oof ... this routine turned out a real mess

   ; set pointer to given element
   sta RAM_BANK
   stx zp_pointer_2+1
   stz zp_pointer_2
   ; remember the original successor of it
   lda (zp_pointer_2)
   sta detail::temp_variable_a
   ldy #1
   lda (zp_pointer_2),y
   sta detail::temp_variable_a+1

   jsr heap::allocate_chunk ; pointer to new element is in .A/.X
   sta zp_pointer ; just temporary storage, will move to RAM_BANK later and set to zero
   stx zp_pointer+1

   ; register new element as successor of the given element
   sta (zp_pointer_2)
   ldy #1
   txa
   sta (zp_pointer_2),y

   ; register given element as predecessor of new element
   ldx RAM_BANK ; that's part of the given element, the other half is still stored in zp_pointer_2
   lda zp_pointer
   sta RAM_BANK
   stz zp_pointer
   txa ; RAM_BANK of original pointer
   ldy #2
   sta (zp_pointer),y
   iny
   lda zp_pointer_2+1
   sta (zp_pointer),y

   ; Make original successor of given element the successor of the new element
   ldy #3
   lda detail::temp_variable_a+1
   sta (zp_pointer),y
   dey
   lda detail::temp_variable_a
   sta (zp_pointer),y

   ; check if original successor of given element was NULL
   ; .A already loaded from previous section
   ldx detail::temp_variable_a+1
   IS_NULL_PTR_ZEROFLAG
   beq @end

   ; register the new element as predecessor of successor
   ldx RAM_BANK
   sta RAM_BANK ; .A still loaded ...

   ; unfinished!

@end:
   rts
.endproc




.popseg
.endscope
