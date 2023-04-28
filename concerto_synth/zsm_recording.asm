; Copyright 2022 Carl Georg Biermann

; This file provides routines and memory needed for recording Zsound data.

; ToDo
; * start recording
;    * initializes memory & variables
;    * opens a file where the data can be written to
;    * writes header data into file
;    * assume all zeros for "current" buffer (? what forces first writes into any location ?)
; * write PSG
;    * accepts address/value pair for PSG
;    * stores it into a temporary buffer
;    * forwards the data to the VERA
; * write YM2151
;    * accepts address/value pair for YM2151
;    * writes it into temporary buffer
;    * forwards data to YM2151
; * flush tick
;    * compares currently set values with previously set values
;    * filters out redundant writes
;    * handles exceptions to this, such as KON register of the YM2151
;    * flush command values to "back buffers"
;    * write
; * stop recording
;    * close file
;    * any further cleanup needed
; * maybe a recording to BRAM is needed and data is written to the file in the end

; Known limitations of recording routines:
; * FM channel bit mask only considers key-on and key-off events
; * supports only up to 70 PSG operations and 250 FM operations per tick
; * filters out only direct duplicates (e.g. A-B-A within the same tick is not filtered out, even though it's equivalent to just A)

; variables / buffers needed
; 
; * command buffer for PSG
; * command buffer for YM2151
; * back buffer for YM2151
; * back buffer for VERA
; * file stuff
; * 

.scope zsm_recording

zsm_version = 1 ; Do not change! This file only implements version 1.

.pushseg
.zeropage
zp_pointer: ; this can be pointed to any location in the zeropage, where a 16 bit variable can be safely used by the recorder
   .res 2
.popseg


; Start a recording
; .A tick rate low
; .X tick rate high
; .Y ram bank (where recording data should be stored)
.proc init
   ; initialize variables
   sta tick_rate
   stx tick_rate+1
   sty start_bank
   sty current_bank
   lda #$10
   sta current_low_address
   lda #>RAM_WIN
   sta current_low_address+1

   ; sweep over "reset area"
   ldx #(reset_area_end-reset_area_begin)
@reset_loop:
   dex
   stz reset_area_begin, x
   bne @reset_loop

   ; fill in some members of the ZSM header
   lda RAM_BANK
   pha
   lda start_bank
   sta RAM_BANK
   ; magic header
   lda #$7A
   sta RAM_WIN+0
   lda #$6D
   sta RAM_WIN+1
   ; version
   lda #zsm_version
   sta RAM_WIN+2
   ; Loop point: default offset is $10, can be changed
   lda #$10
   sta RAM_WIN+3
   stz RAM_WIN+4
   stz RAM_WIN+5
   ; PCM offset: ignore
   ; FM channel mask: fill in at the end
   ; PSG channel mask: fill in at the end
   ; Tick rate
   lda tick_rate
   sta RAM_WIN+12
   lda tick_rate+1
   sta RAM_WIN+13
   ; reserved bytes: set to zero
   stz RAM_WIN+14
   stz RAM_WIN+15
   pla
   sta RAM_BANK

   ; start recording
   lda #$01
   sta recorder_active

   rts
.endproc


; Issue a command to a PSG register
; .A register number
; .X value
; discards .A, .X, .Y
.proc psg_write
   ldy recorder_active
   bne :+
   rts
:  phx
   pha
   ; check if register hasn't been initialized yet
   ldx #<psg_init_markers
   ldy #>psg_init_markers
   jsr test_and_set_bit
   beq @prep_write
   ; it has been initialized already. 
   ; check if the same value is already in the mirror
   plx ; pop in "wrong" order to swap .A and .X
   pla
   cmp psg_mirror, x
   bne @do_write
   rts
@prep_write:
   plx ; pop in "wrong" order to swap .A and .X
   pla
@do_write:
   ; now .A contains value, .X contains register number
   ; write value into mirror
   sta psg_mirror, x
   ; put command into buffer
   ldy psg_num_pairs
   sta psg_data_buffer, y
   txa
   sta psg_address_buffer, y
   inc psg_num_pairs
   ; mark channel as used
   lsr
   lsr
   ldx #<psg_channel_mask
   ldy #>psg_channel_mask
   jsr set_bit
   rts
.endproc


; Issue a command to a register in the YM2151
; .A register number
; .X value
; discards .A and .Y
; preserves .X
.proc fm_write
   ldy recorder_active
   bne :+
   rts
:
   ; ToDo
   ; check if it's a write to $19
      ; mapping $19->$1A
   pha
   phx
   cmp #$08 ; is it a key-on or key-off event?
   bne :+

   ; it's a key-on or key-off event
   ; -> determine channel number (lower three bits of .X) to set channel bit mask
   txa
   and #%00000111
   ldx #<fm_channel_mask
   ldy #>fm_channel_mask
   jsr set_bit
   plx
   pla
   bra @write_to_buffer ; we don't filter key-on or key-off events

:  ; not a key-on or key-off event
   ; TODO: handle $19 (LFO modulation depth)
   ; check if register hasn't been initialized yet
   ldx #<fm_init_markers
   ldy #>fm_init_markers
   jsr test_and_set_bit ; has the register already been written to?
   beq @prep_write_to_buffer ; if not, we want to output the byte

   ; check mirror
   pla ; pull in "wrong order" to facilitate lookup in the fm_mirror
   ply
   ;.byte $db
   cmp fm_mirror, y
   bne :+ ; if they're equal, we can skip this operation
   rts
:  sta fm_mirror, y
   ; swap registers back
   tax
   tya
   bra @write_to_buffer

@prep_write_to_buffer:
   plx
   pla

@write_to_buffer:
   ldy fm_num_pairs
   sta fm_address_buffer, y
   txa
   sta fm_data_buffer, y
   inc fm_num_pairs

   rts
.endproc


; Tick routine
; ============
; Flushes all commands of the current tick to the
; output buffer and inserts waiting commands if needed
.proc tick
   ; ToDo
   ; waiting logic
      ; increase pending_ticks
      ; check if 255
      ; check if psg commands exist
      ; check if fm commands exist
      ; then write a wait command
   ; flush fm buffer
   ; flush psg buffer
   lda recorder_active
   bne :+
   rts
:
   ; prepare buffer write operations
   lda RAM_BANK
   pha
   lda current_bank
   sta RAM_BANK
   lda current_low_address
   sta zp_pointer
   lda current_low_address+1
   sta zp_pointer+1

   ; write one waiting tick (TODO: accumulate ticks when possible)
   lda #$81
   jsr write_byte


   ; flush FM buffer
   ; ===============
   ; The ZSOUND signal byte that tells how many FM reg/val pairs will come next allows up to 63 pairs being written at once.
   lda fm_num_pairs ; keeps track of how many pairs are remaining
   ldx #0 ; In this section, .X is used as the contiguous "pair index".
@fm_flush_outer_loop: ; the outer loop is necessary to split the stream of data into segments of at most 63 reg/val pairs
   ; expecting current "pair index" in .X, and fm_num_pairs in .A
   cmp #64 ; see if we have more pairs than we can flush in one go
   bcc :+ ; branch if we have 63 or less pairs left

   ; here we have 64 or more pairs left - do 63 of them
   sbc #63 ; carry for subtraction is already set as per branching condition
   sta fm_num_pairs
   lda #$7f
   jsr write_byte ; emit ZSOUND fm signal byte to write 63 FM pairs
   ldy #63 ; set loop counter
   bra @fm_flush_inner_loop

:  ; here we have 63 or less pairs left, which means we'll finish after the next inner loop
   cmp #0
   beq @fm_flush_outer_end
   tay ; set loop counter
   ora #%01000000 ; set bit 6 to indicate that we are writing FM data.
   jsr write_byte ; emit ZSOUND fm signal byte
   stz fm_num_pairs ; we will write all remaining pairs in this iteration

@fm_flush_inner_loop:
   ; in the inner loop, .Y is the loop counter, which is guaranteed to be at least 1 during the first iteration
   lda fm_address_buffer, x
   jsr write_byte
   lda fm_data_buffer, x
   jsr write_byte
   inx
   dey
   bne @fm_flush_inner_loop

@fm_flush_inner_end:
   ; are we done yet with fm data?
   lda fm_num_pairs
   bne @fm_flush_outer_loop

@fm_flush_outer_end:


   ; flush PSG buffer
   ; ================
   ldx #0
@psg_flush_loop:
   cpx psg_num_pairs
   beq @psg_flush_end
   lda psg_address_buffer, x
   jsr write_byte
   lda psg_data_buffer, x
   jsr write_byte
   inx
   bra @psg_flush_loop
@psg_flush_end:
   stz psg_num_pairs


   ; save the tip of the output
   lda zp_pointer
   sta current_low_address
   lda zp_pointer+1
   sta current_low_address+1
   lda RAM_BANK
   sta current_bank
   ; restore RAM bank
   pla
   sta RAM_BANK
   rts

   ; Assumes value in .A
   ; discards .A
   ; preserves .X and .Y
   .proc write_byte
      sta (zp_pointer)
      jsr advance_buffer_address
      rts
   .endproc
.endproc


.proc end
   lda RAM_BANK
   pha

   ; finish up emitting bytes
   jsr tick
   stz recorder_active

   ; write channel masks into buffer
   lda start_bank
   sta RAM_BANK
   lda fm_channel_mask
   sta RAM_WIN+9
   lda psg_channel_mask
   sta RAM_WIN+10
   lda psg_channel_mask+1
   sta RAM_WIN+11

   ; write buffer to a file
   ; =====================
   ; OPEN THE OUTPUT FILE
   lda #command_string_length
   ldx #<command_string
   ldy #>command_string
   jsr SETNAM ; set file name
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #1 ; secondary command address, I really don't understand this.
   jsr SETLFS
   ; open - open the logical file
   jsr OPEN
   ; chkout - open a logical file for output
   ldx #1 ; logical file to be used
   jsr CHKOUT

   ; emit data into file
   stz zp_pointer
   lda #>RAM_WIN
   sta zp_pointer+1
@loop:
   lda (zp_pointer)
   jsr CHROUT
   jsr advance_buffer_address
   ; check if end of data is reached
   lda current_bank
   cmp RAM_BANK
   bne @loop
   lda zp_pointer+1
   cmp current_low_address+1
   bne @loop
   lda zp_pointer
   cmp current_low_address
   bne @loop

   ; emit EOF signal
   lda #$80
   jsr CHROUT

   ; close the file
   lda #1
   jsr CLOSE
   jsr CLRCHN

   pla
   sta RAM_BANK
   rts
.endproc







; accepts byte in .A and writes it to output
; The macro is intended to allow for easy switching between direct file writes and writing to BRAM before writing to a file.
.macro CONCERTO_ZSM_WRITE_BYTE
   pha
   phx
   phy
   jsr CHROUT
   ply
   plx
   pla
.endmacro




start_recording:
   ; initialize mirrors
   ; YM2151
   ldx #<fm_mirror_size ; its 256, so it will actually be zero
:  dex
   stz fm_mirror,x
   bne :-
   ; PSG
   ldx #psg_mirror_size
:  dex
   stz psg_mirror,x
   bne :-

   stz pending_ticks

   ; OPEN THE OUTPUT FILE
   lda #command_string_length
   ldx #<command_string
   ldy #>command_string
   jsr SETNAM ; set file name
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #1 ; secondary command address, I really don't understand this.
   jsr SETLFS
   ; open - open the logical file
   jsr OPEN
   ; chkout - open a logical file for output
   ldx #1 ; logical file to be used
   jsr CHKOUT

   ; *** the file is now ready for input ***

   ; WRITE HEADER
   ldx #0
@header_loop:
   lda header_data,x
   phx
   CONCERTO_ZSM_WRITE_BYTE
   plx
   inx
   cpx #header_length
   bne @header_loop

   ; temporary: write test data
   ;jsr write_test_data

   rts




stop_recording:
   lda #1
   jsr CLOSE
   jsr CLRCHN




write_test_data:
   ldx #0
@test_loop:
   lda music_test_data,x
   phx
   CONCERTO_ZSM_WRITE_BYTE
   plx
   inx
   cpx #music_test_data_length
   bne @test_loop
   rts



; record data for the PSG
; this is not the final output but will be run through the filter stage to get rid of unnecessary writes
; data in .A, number of PSG register in .X
write_psg_data:
   php
   pha
   phx
   phy

   ; check if a write operation is necessary
   cmp psg_mirror, x
   beq @end ; no operation necessary if the value in mirror is already the same

   pha
   jsr write_waiting_ticks ; write out any pending waiting ticks before writing PSG data
   pla

   ; store new value in mirror
   sta psg_mirror, x
   ; write data to output
   pha
   txa
   CONCERTO_ZSM_WRITE_BYTE
   pla
   CONCERTO_ZSM_WRITE_BYTE

@end:
   ply
   plx
   pla
   plp
   rts



; record data for the YM2151
; this is not the final output but will be run through the filter stage to get rid of unnecessary writes
; data in .Y, address in .A
write_fm_data:
   php
   pha
   phx
   phy

   ; first, find out whether the write operation is a key-on or key-off operation because those will be treated differently.
   cmp #$08 ; this is the key-on operation
   beq @register_instruction
   ; it wasn't a key-on or key-off instruction. check whether the data write is redundant
   tax
   tya
   cmp fm_mirror,x
   bne @pre_register_instruction
@end:
   ply
   plx
   pla
   plp
   rts

@pre_register_instruction:
   sta fm_mirror,x ; store in mirror
   tay
   txa
@register_instruction:
   ldx fm_num_pairs
   sta fm_address_buffer, x
   tya
   sta fm_data_buffer, x
   inc fm_num_pairs
   bra @end


; Must be called at the end of every tick during recording.
end_tick:
   ; do YM2151 writes
   ldx #0 ; data index
   ldy #0 ; how many register values can be written before the next "FM write" ZSM command.
@fm_loop_start:
   ; all writes done?
   cpx fm_num_pairs
   beq @fm_loop_end

   jsr write_waiting_ticks ; write out any pending waiting ticks before writing YM2151 data

   ; do we need a new "FM write" command?
   cpy #0
   bne @skip_write_command
   ; When execution continues here, we do need it. how many register-value pairs? Depends on how many are left to do and the maximum of 63.
   txa ; current index
   eor #$FF ; negate (invert bits, add one)
   inc
   clc
   adc fm_num_pairs ; add total number of writes. the result is the remaining number of writes.
   cmp #63 ; smaller than maximum allowed?
   bcc @use_number_directly
   lda #63 ; use maximum allowed
@use_number_directly:
   tay ; we can do so many writes now
   ora #%01000000 ; this will result in a ZSM "FM write" command
   CONCERTO_ZSM_WRITE_BYTE
@skip_write_command:
   ; now do a register write
   lda fm_address_buffer,x
   CONCERTO_ZSM_WRITE_BYTE
   lda fm_data_buffer,x
   CONCERTO_ZSM_WRITE_BYTE
   inx
   dey
   bra @fm_loop_start
@fm_loop_end:
   stz fm_num_pairs

   ; wait for one tick
   inc pending_ticks
   bpl :+
   ; we have 128 ticks. write 127, keep 1
   dec pending_ticks
   jsr write_waiting_ticks
   inc pending_ticks
:  rts




; checks how many ticks we have been waiting since the last ZSM command and outputs them
; We can guarantee that this function is never called with 128 or more ticks, so we don't need any logic to check for that.
write_waiting_ticks:
   lda pending_ticks
   beq @end ; none are needed?
   ora #%10000000
   CONCERTO_ZSM_WRITE_BYTE
   stz pending_ticks
@end:
   rts


; returns a bit shifted left by the given number of times
; .A input number
; .A return value
; uses .A and .X
.proc shift_bit
   tax
   lda #1
   clc
   cpx #0
@loop:
   beq @end
   asl
   dex
   bra @loop
@end:
   rts
.endproc


; REMOVE? REMOVE? REMOVE?
; tests if a certain bit is set in a packed bit field
; .A index
; .X low address
; .Y high address
; return: zero flag is reset if bit was set
.proc test_bit
   stx zp_pointer ; store address in scrap register on ZP
   sty zp_pointer+1 ; for indirect bit field access
   tax ; keep copy of the index in .X
   lsr ; extract the byte index
   lsr
   lsr
   tay
   lda (zp_pointer), y ; read byte from bit field
   sta zp_pointer ; and save it in scrap register
   txa ; recall the copy of the index
   and #%00000111 ; generate bit mask
   jsr shift_bit
   and zp_pointer ; compare bit mask with bit field
   rts
.endproc


; tests and sets a certain bit in a packed bit field
; .A index
; .X low address
; .Y high address
; return: zero flag is reset if bit was set
.proc test_and_set_bit
   ;.byte $db
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


; and advances zp_pointer and RAM bank
.proc advance_buffer_address
   sta (zp_pointer)
   inc zp_pointer
   beq @page_cross
   rts
@page_cross:
   lda zp_pointer+1
   inc
   cmp #>ROM_WIN
   bcs @bank_cross
   sta zp_pointer+1
   rts
@bank_cross:
   lda #>RAM_WIN
   sta zp_pointer+1
   inc RAM_BANK
   rts
.endproc


; internal variables
; ==================
recorder_active:
   .byte 0 ; activates or deactivates the recording, allows "bypass mode" of the recording instructions

start_bank:
   .byte 0 ; the ram bank given by the user, which is the first bank that can be used by our code

current_low_address:
   .word 0 ; the address where the next byte can be written to
current_bank:
   .byte 0 ; the ram bank where the next byte can be written to

tick_rate:
   .word 0


; mirrors mirror the data stored on the respective chips as reference for comparison
psg_mirror_size = 64
psg_mirror:
   .res psg_mirror_size

fm_mirror_size = 256
fm_mirror:
   .res fm_mirror_size

; buffer for PSG instructions
psg_maximum_buffer_length = 70 ; greater than 64 just incase there are redundant write operations
psg_address_buffer:
   .res psg_maximum_buffer_length
psg_data_buffer:
   .res psg_maximum_buffer_length

; buffer for FM instructions
fm_maximum_buffer_length = 250
fm_address_buffer:
   .res fm_maximum_buffer_length
fm_data_buffer:
   .res fm_maximum_buffer_length



; >>>>>>> RESET AREA BEGIN
; These are variables which have to be initialized with zero
; Clumping them together in memory allows for eays initialization.
reset_area_begin:

pending_ticks:
   .byte 0 ; how many ticks have passed since the last byte has been written

psg_channel_mask:
   .word 0
fm_channel_mask:
   .byte 0

; number of instructions that have been sent
psg_num_pairs:
   .byte 0
fm_num_pairs:
   .byte 0

; init markers: save whether a byte has been written to already or not
psg_init_markers:
   .res psg_mirror_size / 8
fm_init_markers:
   .res fm_mirror_size / 8

; <<<<<<< RESET AREA END
reset_area_end:




command_string:
; @ symbol (Petscii 64): save and replace existing file
; 0: use drive mechanism zero attached to that drive controller ...
; filename
; ,s,w : open sequential file for writing operation
;.byte 64,"0:test.zsm,s,w"
;.byte "../test.zsm,s,w"
.byte 64,"0:test.zsm,s,w"
@end_command_string:
command_string_length = @end_command_string - command_string


header_data:
   .byte $7A, $6D ; magic sequence "zm"
   .byte 1 ; ZSM version number
   .byte 0, 0, 0 ; loop point, zero is no loop
   .byte 0, 0, 0 ; PCM offset, zero is no PCM
   .byte $FF ; FM channel bit mask, use all channels
   .byte $FF, $FF ; PSG channel bit mask, use all channels
   .byte 127, 0 ; Tick rate, Concerto uses 127.17 Hz, 127 is close enough
   .byte 0, 0 ; Reserved for future use. Set to zero.
@header_data_end:
header_length = @header_data_end - header_data


music_test_data:
   .byte $00 ; write following byte into PSG register 0
   .byte $00 ; lo frequency
   .byte $01 ; write following byte into PSG register 1
   .byte $10 ; hi frequency
   .byte $02 ; write following byte into PSG register 2
   .byte $FF ; L/R enabled, max volume
   .byte $03 ; write following byte into PSG register 3
   .byte 64 ; sawtooth
   .byte $FF ; delay 127 ticks
   .byte $01 ; write following byte into PSG register 1
   .byte $20 ; hi frequency
   .byte $FF ; delay 127 ticks
   ;.byte $80 ; end of stream

@music_test_data_end:
music_test_data_length = @music_test_data_end - music_test_data

.endscope ; zsm_recording
