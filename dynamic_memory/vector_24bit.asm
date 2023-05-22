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
; Individual elements can be addressed via two different ways:
; * 3-byte pointer: B/H (2-byte pointer to a chunk) and the index inside the chunk
; * 2-byte B/H pointer to first chunk and 2-byte global index in the entire vector
; Those two modes could be converted into each other.
; Possibly, one part of the address will be implicitly given during some operations (e.g. by previous operations)
;
; Basic operations are:
; * create new vector
; * destroy vector
; * is empty
; * get first entry
; * is last entry
; * is first entry
; * get next entry
; * get previous entry
; * read entry (?)
; * write entry (?)
; * insert entry
; * delete entry
; * defragment vector (release unnecessary chunks)
; * ???
;
; Other files might extend this application-specifically.


.ifndef ::v24b_zp_pointer
   .pushseg
   .zeropage
v24b_zp_pointer:
   .res 2
   .popseg
.endif

; ToDo: share any zeropage variables?
.include "doubly_linked_list.asm"

.scope v24b

zp_pointer = ::v24b_zp_pointer
.feature addrsize
.if (.addrsize(zp_pointer) = 2) .or (.addrsize(zp_pointer) = 0)
   .error "v24b_zp_pointer isn't a zeropage variable!"
.endif

.include "../common/x16.asm"

.pushseg
.code




.popseg
.endscope
