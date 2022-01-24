; Copyright 2021 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE01.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_01_hello_world_concerto.asm"


.zeropage
.include "concerto_synth/synth_zeropage.asm"


.code
; BASIC stub to start program
; "10 SYS2061"
;.org $0801
;.byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00
;.org $080D

   jmp start

.include "concerto_synth/concerto_synth.asm"

start:
   jsr concerto_synth::initialize
   jsr concerto_synth::activate_synth


   ; play a note
   lda #60
   sta concerto_synth::note_pitch
   lda #0
   sta concerto_synth::note_channel
   lda #0
   sta concerto_synth::note_timbre
   lda #63 ; note volume
   jsr concerto_synth::play_note

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth
   rts
