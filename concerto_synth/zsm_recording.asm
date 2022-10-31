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

; variables / buffers needed
; 
; * command buffer for PSG
; * command buffer for YM2151
; * back buffer for YM2151
; * back buffer for VERA
; * file stuff
; * 

.scope zsm_recording


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
   ldx #<ym2151_mirror_size ; its 256, so it will actually be zero
:  dex
   stz ym2151_mirror,x
   bne :-
   ; PSG
   ldx #psg_mirror_size
:  dex
   stz psg_mirror,x
   bne :-

   stz wait_pending_ticks

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
write_ym2151_data:
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
   cmp ym2151_mirror,x
   bne @pre_register_instruction
@end:
   ply
   plx
   pla
   plp
   rts

@pre_register_instruction:
   sta ym2151_mirror,x ; store in mirror
   tay
   txa
@register_instruction:
   ldx ym2151_num_writes
   sta ym2151_address_buffer, x
   tya
   sta ym2151_data_buffer, x
   inc ym2151_num_writes
   bra @end


; Must be called at the end of every tick during recording.
end_tick:
   ; do YM2151 writes
   ldx #0 ; data index
   ldy #0 ; how many register values can be written before the next "FM write" ZSM command.
@ym2151_loop_start:
   ; all writes done?
   cpx ym2151_num_writes
   beq @ym2151_loop_end

   jsr write_waiting_ticks ; write out any pending waiting ticks before writing YM2151 data

   ; do we need a new "FM write" command?
   cpy #0
   bne @skip_write_command
   ; When execution continues here, we do need it. how many register-value pairs? Depends on how many are left to do and the maximum of 63.
   txa ; current index
   eor #$FF ; negate (invert bits, add one)
   inc
   clc
   adc ym2151_num_writes ; add total number of writes. the result is the remaining number of writes.
   cmp #63 ; smaller than maximum allowed?
   bcc @use_number_directly
   lda #63 ; use maximum allowed
@use_number_directly:
   tay ; we can do so many writes now
   ora #%01000000 ; this will result in a ZSM "FM write" command
   CONCERTO_ZSM_WRITE_BYTE
@skip_write_command:
   ; now do a register write
   lda ym2151_address_buffer,x
   CONCERTO_ZSM_WRITE_BYTE
   lda ym2151_data_buffer,x
   CONCERTO_ZSM_WRITE_BYTE
   inx
   dey
   bra @ym2151_loop_start
@ym2151_loop_end:
   stz ym2151_num_writes

   ; wait for one tick
   inc wait_pending_ticks
   bpl :+
   ; we have 128 ticks. write 127, keep 1
   dec wait_pending_ticks
   jsr write_waiting_ticks
   inc wait_pending_ticks
:  rts




; checks how many ticks we have been waiting since the last ZSM command and outputs them
; We can guarantee that this function is never called with 128 or more ticks, so we don't need any logic to check for that.
write_waiting_ticks:
   lda wait_pending_ticks
   beq @end ; none are needed?
   ora #%10000000
   CONCERTO_ZSM_WRITE_BYTE
   stz wait_pending_ticks
@end:
   rts





; *** DATA ***

wait_pending_ticks:
   .byte 0

; mirrors mirror the data stored on the respective chips as reference for comparison
psg_mirror_size = 64
psg_mirror:
   .res psg_mirror_size

ym2151_mirror_size = 256
ym2151_mirror:
   .res ym2151_mirror_size

; number of instructions that are being sent to the ym2151
ym2151_num_writes:
   .byte 0
; actual instructions
ym2151_maximum_buffer_length = 250 ; definitely doesn't need to be 256 or higher
ym2151_address_buffer:
   .res ym2151_maximum_buffer_length
ym2151_data_buffer:
   .res ym2151_maximum_buffer_length

command_string:
; @ symbol (Petscii 64): save and replace existing file
; 0: use drive mechanism zero attached to that drive controller ...
; filename
; ,s,w : open sequential file for writing operation
;.byte 64,"0:test.zsm,s,w"
;.byte "../test.zsm,s,w"
.byte "test.zsm,s,w"
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
