; Copyright 2021 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE04.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_04_player.asm"


.zeropage
.include "concerto_synth/synth_zeropage.asm"


.code

   jmp start

.include "concerto_player/concerto_player.asm"
.include "concerto_synth/x16.asm" ; get general X16 macros


; Thanks to Squall_FF8 for providing this macro!
.macro LOADFILE FileName, NameLen, Address
   LDA #NameLen
   LDX #<FileName
   LDY #>FileName
   JSR SETNAM

   LDA #1
   LDX #HOST_DEVICE
   LDY #0
   JSR SETLFS

   LDA #0
   LDX #<Address
   LDY #>Address
   JSR LOAD
.endmacro 


start:
   jsr concerto_synth::initialize

   ; load timbre data
   lda #17 ; string length
   ; set file name (command)
   ldx #(<timbre_file_command)
   ldy #(>timbre_file_command)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #0 ; secondary command address, I really don't understand this.
   jsr SETLFS
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file
   ; chkin - open a logical file for input
   ldx #1 ; logical file to be used
   jsr CHKIN
   ; load data
   jsr concerto_synth::restore_timbres
@close_file:
   ; close file
   lda #1
   jsr CLOSE
   jsr CLRCHN


   ; load song data
   lda #8 ; string length
   ; set file name (command)
   ldx #(<song_file_command)
   ldy #(>song_file_command)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #0 ; secondary command address, I really don't understand this.
   jsr SETLFS
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file_2
   ; chkin - open a logical file for input
   ldx #1 ; logical file to be used
   jsr CHKIN
   ; load data
   lda #<external_song_data
   sta r0L
   lda #>external_song_data
   sta r0H
   ldy #0
@read_loop:
   jsr CHRIN
   ldy #0
   sta (r0L), y
   jsr READST ; check for EOF
   and #64
   bne @close_file_2
   ; advance pointer
   lda r0L
   clc
   adc #1
   sta r0L
   lda r0H
   adc #0
   sta r0H
   bra @read_loop
@close_file_2:
   ; close file
   lda #1
   jsr CLOSE
   jsr CLRCHN
   .byte $db

   ; play song
   lda #1
   sta concerto_player::repeat ; enable repeat
   ldx #<external_song_data ; set song address
   ldy #>external_song_data
   ; or alternatively:
   ;ldx #<hardcoded_song_data
   ;ldy #>hardcoded_song_data
   jsr concerto_player::play_track

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth

   rts

; DATA

timbre_file_command:
   .byte "0:song02.cob,s,r" ; 17 characters long
song_file_command:
   .byte "song.bin" ; 8 characters long

BASENOTE = 53
TIME = 14


hardcoded_song_data: ; this works just as well as an externally loaded song
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $12, 24, BASENOTE, 63 ; clap
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $12, 24, BASENOTE, 63 ; clap
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $20 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $12, 24, BASENOTE, 63 ; clap
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $20 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 10, BASENOTE, 63 ; bass
   .byte $11, 20, BASENOTE, 63 ; kick
   .byte $12, 24, BASENOTE, 63 ; clap
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $20 ; bass
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $F0 ; end of song

external_song_data:

.export external_song_data

