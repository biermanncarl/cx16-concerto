; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE03.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_03_pitchbend.asm"



.code

   jmp start



; define a macro with the player address BEFORE including "concerto_synth/concerto_synth.asm"
concerto_playback_routine = my_custom_playback_routine

.include "../concerto_synth/concerto_synth.asm"

playback_ticks:
   .byte 0
playback_note:
   .byte 0

; You can do anything you want in this routine.
my_custom_playback_routine:
   lda playback_ticks
   beq @reset_loop
   cmp #255
   bne :+
   jsr play_note_1     ; play note if timer is 255
:  lda playback_ticks
   cmp #(255-32)
   bne :+
   jsr set_pitchslide_upwards   ; set pitchbend up if timer is 255-32
:  cmp #(255-96)
   bne :+
   jsr set_pitchslide_downwards  ; set pitchbend down if timer is 255-96
:  cmp #(255-192)
   bne :+
   jsr set_slide_position  ; set pitchbend position if timer is 255-192
:  dec playback_ticks
   rts
@reset_loop:
   ; reset timer. The higher this number, the slower the chromatic scale is played.
   lda #255
   sta playback_ticks
   rts

play_note_1:
   lda #60
   sta concerto_synth::note_pitch
   lda #0
   sta concerto_synth::note_channel
   lda #0
   sta concerto_synth::note_timbre
   lda #63 ; note volume
   jsr concerto_synth::play_note
   rts

set_pitchslide_upwards:
   ldx #0 ; channel
   ldy #0  ; coarse rate
   lda #20 ; fine rate
   stz concerto_synth::pitchslide_mode
   jsr concerto_synth::set_pitchslide_rate
   rts

set_pitchslide_downwards:
   ldx #0 ; channel
   ; because fine values are always positive, we have to add a negative "coarse" value to achieve a slow downwards slope
   ; E.g. we want the negative slope -0.1
   ; We achieve this by -0.1 = -1 + 0.9
   ldy #255 ; coarse = -1
   lda #(255-25) ; fine = +0.9.
   stz concerto_synth::pitchslide_mode
   jsr concerto_synth::set_pitchslide_rate
   rts

set_slide_position:
   ldx #0 ; channel
   lda #80 ; coarse position
   ldy #0 ; fine position
   jsr concerto_synth::set_pitchslide_position
   rts

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
