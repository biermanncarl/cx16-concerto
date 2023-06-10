; Copyright 2021 Carl Georg Biermann


; main loop ... wait until "Q" is pressed.
mainloop:

   ; GUI update
   jsr concerto_gui::gui_tick

   ; print out help messages
   ;DISPLAY_LABEL lb_play_notes,     29, 54
   ;DISPLAY_LABEL lb_toggle_octaves, 29, 56
   ;DISPLAY_LABEL lb_release_note,   29, 58

   ; keyboard polling

   jsr GETIN      ; get charakter from keyboard
   cmp #65        ; check if pressed "A"
   bne @skip_a
   jmp @keyboard_a
@skip_a:
   cmp #87        ; check if pressed "W"
   bne @skip_w
   jmp @keyboard_w
@skip_w:
   cmp #83        ; check if pressed "S"
   bne @skip_s
   jmp @keyboard_s
@skip_s:
   cmp #69        ; check if pressed "E"
   bne @skip_e
   jmp @keyboard_e
@skip_e:
   cmp #68        ; check if pressed "D"
   bne @skip_d
   jmp @keyboard_d
@skip_d:
   cmp #70        ; check if pressed "F"
   bne @skip_f
   jmp @keyboard_f
@skip_f:
   cmp #84        ; check if pressed "T"
   bne @skip_t
   jmp @keyboard_t
@skip_t:
   cmp #71        ; check if pressed "G"
   bne @skip_g
   jmp @keyboard_g
@skip_g:
   cmp #89        ; check if pressed "Y"
   bne @skip_y
   jmp @keyboard_y
@skip_y:
   cmp #72        ; check if pressed "H"
   bne @skip_h
   jmp @keyboard_h
@skip_h:
   cmp #85        ; check if pressed "U"
   bne @skip_u
   jmp @keyboard_u
@skip_u:
   cmp #74        ; check if pressed "J"
   bne @skip_j
   jmp @keyboard_j
@skip_j:
   cmp #75        ; check if pressed "K"
   bne @skip_k
   jmp @keyboard_k
@skip_k:
   cmp #79        ; check if pressed "O"
   bne @skip_o
   jmp @keyboard_o
@skip_o:
   cmp #76        ; check if pressed "L"
   bne @skip_l
   jmp @keyboard_l
@skip_l:
   cmp #32        ; check if pressed "SPACE"
   bne @skip_space
   jmp @keyboard_space
@skip_space:
   cmp #90        ; check if pressed "Z"
   bne @skip_z
   jmp @keyboard_z
@skip_z:
   cmp #88        ; check if pressed "X"
   bne @skip_x
   jmp @keyboard_x
@skip_x:
   cmp #81        ; exit if pressed "Q"
   bne @end_keychecks
   jmp exit
@end_keychecks:
   jmp end_mainloop

@keyboard_a:
   lda #0
   jmp play_note
@keyboard_w:
   lda #1
   jmp play_note
@keyboard_s:
   lda #2
   jmp play_note
@keyboard_e:
   lda #3
   jmp play_note
@keyboard_d:
   lda #4
   jmp play_note
@keyboard_f:
   lda #5
   jmp play_note
@keyboard_t:
   lda #6
   jmp play_note
@keyboard_g:
   lda #7
   jmp play_note
@keyboard_y:
   lda #8
   jmp play_note
@keyboard_h:
   lda #9
   jmp play_note
@keyboard_u:
   lda #10
   jmp play_note
@keyboard_j:
   lda #11
   jmp play_note
@keyboard_k:
   lda #12
   jmp play_note
@keyboard_o:
   lda #13
   jmp play_note
@keyboard_l:
   lda #14
   jmp play_note
@keyboard_space:
   ldx #0
   stx concerto_synth::note_channel
   jsr concerto_synth::release_note
   jmp end_mainloop
@keyboard_z:
   lda Octave
   beq end_mainloop
   sec
   sbc #12
   sta Octave
   jmp end_mainloop
@keyboard_x:
   lda Octave
   cmp #108
   beq end_mainloop
   clc
   adc #12
   sta Octave
   jmp end_mainloop


play_note:

   ; determine MIDI note
   sta Note
   lda Octave
   clc
   adc Note

   ; play note
   sta concerto_synth::note_pitch
   ;lda #MAX_VOLUME
   lda concerto_gui::Timbre
   sta concerto_synth::note_timbre
   lda #0
   sta concerto_synth::note_channel
   lda concerto_gui::play_volume
   jsr concerto_synth::play_note

end_mainloop:

   jmp mainloop

; data
lb_play_notes:     STR_FORMAT "a, w, s, ... play notes"
lb_toggle_octaves: STR_FORMAT "z, x         toggle octaves"
lb_release_note:   STR_FORMAT "space        release note"


exit: