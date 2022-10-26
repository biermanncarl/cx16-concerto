; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE01.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_01_hello_world_concerto.asm"



.code
   jmp start

concerto_enable_zsound_recording = 1
.include "concerto_synth/concerto_synth.asm"

start:
   jsr concerto_synth::initialize
   jsr concerto_synth::activate_synth

   jsr concerto_synth::zsm_recording::start_recording

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

   jsr concerto_synth::zsm_recording::stop_recording

   jsr concerto_synth::deactivate_synth
   rts
