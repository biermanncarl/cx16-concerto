; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE02.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_02_playback.asm"



.code

   jmp start



; define a macro with the player address BEFORE including "../synth_engine/concerto_synth.asm"
concerto_playback_routine = my_custom_playback_routine

.include "../synth_engine/concerto_synth.asm"

; You can do anything you want in this routine.
; Here we have set up an example that plays a chromatic scale
; with two notes which are 3 semi tones apart.
my_custom_playback_routine:
   ; every time playback_ticks is 0 we play a note
   lda playback_ticks
   beq @trigger_note
   dec playback_ticks
   rts
@trigger_note:
   ; reset timer. The higher this number, the slower the chromatic scale is played.
   lda #30
   sta playback_ticks
   ; now play the note
   lda playback_note
   sta concerto_synth::note_pitch
   lda #0
   sta concerto_synth::note_channel
   lda #0
   sta concerto_synth::note_timbre
   lda #63 ; note volume
   jsr concerto_synth::play_note
   ; and play another note at another channel
   lda playback_note
   clc
   adc #3
   sta concerto_synth::note_pitch
   lda #1
   sta concerto_synth::note_channel
   lda #63 ; note volume
   jsr concerto_synth::play_note
   ; increase pitch
   inc playback_note
   rts

playback_ticks:
   .byte 0
playback_note:
   .byte 0

start:
   ; initialize player variables
   lda #0
   sta playback_ticks
   lda #48
   sta playback_note

   jsr concerto_synth::initialize
   jsr concerto_synth::activate_synth

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth

   rts
