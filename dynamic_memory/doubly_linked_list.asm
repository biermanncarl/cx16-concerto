; Copyright 2023 Carl Georg Biermann

; This file implements a doubly linked lists (DLLs), consisting of chunks of 256 bytes size.
; The first four bytes of each element are used for the forward- and backward referencing pointers,
; and the other 252 bytes are payload.
; This file does NOT implement routines to manage the content of the chunks in a DLL (with the
; exception of the delete_element function, which might move data around).

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

.ifndef ::DYNAMIC_MEMORY_DOUBLY_LINKED_LIST_ASM
::DYNAMIC_MEMORY_DOUBLY_LINKED_LIST_ASM = 1

; need a ZP pointer which can be used as temporary variable by the functions in this file
.ifndef ::dll_zp_pointer
   .pushseg
   .zeropage
::dll_zp_pointer:
   .res 2
   .popseg
.endif

.ifndef ::dll_zp_pointer_2
   .pushseg
   .zeropage
::dll_zp_pointer_2:
   .res 2
   .popseg
.endif

; share first zp pointer with heap.asm
; heap routines use zp_pointer, so we have to code in such a way that we don't rely on zp_pointer during heap calls
::heap_zp_pointer = ::dll_zp_pointer
.include "heap.asm"


.scope dll

.pushseg
.code

zp_pointer = ::dll_zp_pointer
zp_pointer_2 = ::dll_zp_pointer_2
.feature addrsize
.if (.addrsize(zp_pointer) = 2) .or (.addrsize(zp_pointer) = 0)
   .error "dll_zp_pointer isn't a zeropage variable!"
.endif
.if (.addrsize(zp_pointer_2) = 2) .or (.addrsize(zp_pointer_2) = 0)
   .error "dll_zp_pointer_2 isn't a zeropage variable!"
.endif


.scope detail
temp_variable_a:
   .res 2

   ; Expects the source element in .A/.X
   ; expects the target element in (zp_pointer) (B/H)
   .proc copyElement
      ; setup source
      stx zp_pointer_2+1
      stz zp_pointer_2
      tax
      ; setup target
      lda zp_pointer
      sta RAM_BANK
      stz zp_pointer
      ; fall through to copyElementInternal
   .endproc

   ; ^^ needs to sit right below copyElement
   ; Expects (zp_pointer) and RAM_BANK to be set up for accessing the TARGET block.
   ; Expects (zp_pointer_2) and .X (the ram bank) to be set up for accessing the SOURCE block.
   ; Preserves .X, RAM_BANK and the zero page pointers
   .proc copyElementInternal
      ldy #4 ; start with payload
   @copy_loop:
      lda RAM_BANK ; remember V.B
      stx RAM_BANK ; set up W.B
      tax ; remember V.B
      lda (zp_pointer_2), y ; load byte from Element W
      pha
      lda RAM_BANK ; remember W.B
      stx RAM_BANK ; set up V.B
      tax ; remember W.B
      pla
      sta (zp_pointer), y ; write byte to Element V
      iny
      bne @copy_loop
      rts
   .endproc
.endscope

copyElement = detail::copyElement

; Creates the first element of a new list.
; Returns the pointer (B/H) to the first and only element in .A/.X
; When it fails due to full heap, exits with carry set. Otherwise carry will be clear upon exit.
.proc create_list
   ; basically allocate a new chunk and set predecessor and successor to NULL
   jsr heap::allocate_chunk
   bcs @end ; check if allocation was successful
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
   ; clc not necessary. allocate_chunk has reset carry, and none of the other instructions affects carry!
@end:
   rts
.endproc


; Destroys a list.
; Expects pointer (B/H) to an element in .A/.X. May be NULL.
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


; Reduces the length of the list to 1 element, preserving the original pointer to the list.
; Expects pointer (B/H) to an element in .A/.X
.proc clear_list
   ; get rid of excess chunks
   pha
   phx
   jsr dll::get_next_element
   jsr dll::destroy_list ; !! we depend on destroy_list only deleting list elements to the right and the one passed in, not any ones to the left
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
; Returns pointer to the last element .A/.X (never NULL)
.proc get_last_element
@loop:
   jsr is_last_element
   bcs @end_loop
   jsr get_next_element
   bra @loop
@end_loop:
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
; When it fails due to full heap, exits with carry set. Otherwise carry will be clear upon exit.
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

   ; Set up access to Element W
   sta RAM_BANK
   stx zp_pointer_2+1
   stz zp_pointer_2
   ; Back up pointer to Element U by reading W's predecessor
   ldy #2
   lda (zp_pointer_2),y
   sta detail::temp_variable_a ; store U.B
   iny
   lda (zp_pointer_2),y
   sta detail::temp_variable_a+1 ; store U.H

   ; Now allocate V and link it bidirectionally with W
   jsr heap::allocate_chunk
   bcc :+ ; check if the chunk was successfully allocated
   rts
:  pha ; save V.B
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
   lda zp_pointer_2+1 ; recall W.H
   sta (zp_pointer),y ; store W.H in V's successor
   iny
   lda detail::temp_variable_a ; copy U.B to V's predecessor
   sta (zp_pointer),y
   iny
   lda detail::temp_variable_a+1 ; copy U.H to V's predecessor
   sta (zp_pointer),y

   ; check if U is NULL
   clc ; clear carry to signal success (note that none of the below instructions affect carry)
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
; When it fails due to full heap, exits with carry set. Otherwise carry will be clear upon exit.
; If successful, returns the pointer to the new element.
.proc append_new_element
   jsr get_last_element

   sta RAM_BANK ; set up for writing to the (currently) last element
   stx zp_pointer_2+1
   stz zp_pointer_2

   jsr heap::allocate_chunk ; allocate new last element, zp_pointer_2 is preserved
   bcc :+ ; check if the chunk was successfully allocated
   rts
:  stx zp_pointer+1 ; store H of new chunk
   stz zp_pointer

   ; write new pointer to previously-last element
   sta (zp_pointer_2) ; write B of new last element
   pha ; remember new B
   txa
   ldy #1
   sta (zp_pointer_2), y ; write H of new last element
   pla ; recall new B

   ; write pointer to new last element
   ldx RAM_BANK ; load B of old element
   sta RAM_BANK ; swap in the new B
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

   ; load pointer to new element
   lda RAM_BANK
   ldx zp_pointer+1
   ; clc ; to signal success is not necessary, as allocate_chunk reset carry and none of the operations in between affect it.
   rts
.endproc


; Deletes any element from a list.
; Expects pointer to an element in .A/.X
; If the given element is the only element in the list, carry will be set and the element will not be deleted
; in order to not invalidate pointers to the list.
; If the first element is deleted, the content of the second element will be moved into the first element,
; and the second element will be deleted instead, in order to not invalidate pointers to the list.
.proc delete_element
   ;
   ; We have a list as follows:                               .A/.X
   ;                                                            |
   ;                                                            V
   ;            +---------+               +---------+      +=========+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |ELEMENT V| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +=========+      +---------+
   ;
   ; And we want to delete Element V and link U and W:
   ;
   ;            +---------+               +---------+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +---------+
   ;
   ; Note that both Element U and Element W could be NULL.

   ; Agenda
   ; - set up reading from V
   ; - collect pointers to U and W from it
   ; - if U is NULL:
   ;   - copy content of W to V (if W is not NULL, otherwise handle empty list case)
   ;   - delete W (recursively)
   ;   - return (or just JMP to self --> no additional stack usage and no additional RTS)
   ; - release V
   ; - if W was not NULL: store U in W's predecessor-pointer
   ; - store W in U's successor-pointer

   ; set up reading from V
   sta RAM_BANK ; store V.B
   stx zp_pointer+1 ; store V.H
   stz zp_pointer

   ; collect pointers
   lda (zp_pointer)
   sta zp_pointer_2 ; store W.B
   ldy #1
   lda (zp_pointer),y
   sta zp_pointer_2+1 ; store W.H
   iny
   lda (zp_pointer),y
   beq @delete_first_element
   sta detail::temp_variable_a ; store U.B
   iny
   lda (zp_pointer),y
   sta detail::temp_variable_a+1 ; store U.H

   ; release V
   lda RAM_BANK ; recall V.B
   ldx zp_pointer+1 ; recall V.H
   jsr heap::release_chunk

   ; point W to U
   lda zp_pointer_2 ; recall W.B
   sta RAM_BANK ; store W.B
   beq @end_w ; skip if W is NULL
   stz zp_pointer_2
   ldy #2
   lda detail::temp_variable_a
   sta (zp_pointer_2),y ; store U.B
   iny
   lda detail::temp_variable_a+1
   sta (zp_pointer_2),y ; store U.H
@end_w:

   ; point U to W
   ldx RAM_BANK ; recall W.B
   lda detail::temp_variable_a
   sta RAM_BANK
   lda detail::temp_variable_a+1
   sta zp_pointer+1
   stz zp_pointer
   txa
   sta (zp_pointer) ; store W.B
   ldy #1
   lda zp_pointer_2+1
   sta (zp_pointer),y ; store W.H
@end_u:
   clc
   rts

@delete_first_element:
   ; check if it's the last element, as well.
   ldx zp_pointer_2 ; recall W.B
   beq @only_one_element
@not_last_element:
   ; copy content of Element W to Element V
   stz zp_pointer_2
   jsr detail::copyElementInternal

   ; Now that we copied the content of Element W to Element V, we can delete Element W.
   txa ; recall W.B
   ldx zp_pointer_2+1 ; recall W.H
   bra delete_element ; we can call this function recursively because W is guaranteed to not be the first element, so we won't happen to do the same recursive call again.

@only_one_element:
   ; if it's the last element, we can just return
   sec
   rts
.endproc



.if 0
; Deletes any element from a list. *Slightly* optimized but much less readable version.
; Expects pointer to an element in .A/.X
; Returns pointer to the succeeding element of the deleted one (possibly NULL)
.proc delete_element_optimized
   ;
   ; We have a list as follows:                               .A/.X
   ;                                                            |
   ;                                                            V
   ;            +---------+               +---------+      +=========+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |ELEMENT V| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +=========+      +---------+
   ;
   ; And we want to delete Element V and link U and W:
   ;
   ;            +---------+               +---------+      +---------+
   ; Anchor --> |Element A| <--> ... <--> |Element U| <--> |Element W| <--> ...
   ;            +---------+               +---------+      +---------+
   ;
   ; Note that both Element U and Element W could be NULL.

   ; Agenda
   ; - set up reading from V
   ; - if W was not NULL: store U in W's predecessor
   ; - if U was not NULL: store W in U's successor ; this time, no need to read from V, as we already have U and W
   ; - release V
   ; - load W in .A/.X for output

   ; set up reading from V
   pha ; store pointer to V for later
   phx
   sta RAM_BANK
   stx zp_pointer+1
   stz zp_pointer

   ; get pointers to W and U from V
   lda (zp_pointer) ; read W.B
   tax ; store W.B away
   ldy #1
   lda (zp_pointer),y ; read W.H
   sta zp_pointer_2+1
   stz zp_pointer_2
   iny
   lda (zp_pointer),y ; read U.B and push to stack
   pha
   iny
   lda (zp_pointer),y ; read U.H -- now we don't need the zp_pointer to V anymore
   sta zp_pointer+1
   stx RAM_BANK ; setup access to W
   pla ; recall U.B - make stack independent of branching ahead

   ; link W to U
   ; .A contains U.B and .X contains W.B
   cpx #0 ; is W NULL?
   beq @end_link_w
   dey ; set .Y to 2
   pha ; remember U.B
   sta (zp_pointer_2),y ; write U.B
   iny
   lda zp_pointer+1 ; load U.H
   sta (zp_pointer_2),y ; write U.H
   pla ; recall U.B
@end_link_w:

   ; link U to W
   ; .A contains U.B and .X contains W.B
   cmp #0
   beq @end_link_u
   sta RAM_BANK ; set up access to U
   txa ; recall W.B
   sta (zp_pointer) ; store W.B in U
   ldy #1
   lda zp_pointer_2+1 ; load W.H
   sta (zp_pointer),y ; store W.H in U
@end_link_u:

   ; now we have W.B in .X and W.H in zp_pointer_2+1
   ; store W.B in zp_pointer_2
   stx zp_pointer_2

   ; release V
   plx
   pla
   jsr heap::release_chunk

   ; load pointer to W into .A/.X
   lda zp_pointer_2
   ldx zp_pointer_2+1

   rts
.endproc
.endif

.popseg
.endscope

.endif ; .ifndef ::DYNAMIC_MEMORY_DOUBLY_LINKED_LIST_ASM
