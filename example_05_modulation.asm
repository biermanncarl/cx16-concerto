; Copyright 2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE05.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_05_modulation.asm"


.zeropage
.include "concerto_synth/synth_zeropage.asm"


.code

   jmp start

; When including concerto_player, we do not need to include concerto_synth separately,
; since concerto_player includes it for us.
.include "concerto_player/concerto_player.asm"



start:
   ; initialize concerto
   jsr concerto_synth::initialize

   ; play song
   lda #1
   sta concerto_player::repeat ; enable repeat
   ; song address
   ldx #<hardcoded_song_data
   ldy #>hardcoded_song_data
   ; start playing
   jsr concerto_player::play_track

   ; and wait until key is pressed
mainloop:
   jsr $FFE4 ; GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth

   rts



; DATA

BASENOTE = 57
TIME = 19

hardcoded_song_data: ; this works just as well as an externally loaded song
   ; first bar
   .byte $10, 0, BASENOTE, 63
   .byte $70, 220, 0 ; set volume downward slope
   .byte $00, TIME-3, 0
   .byte $70, 36, 63 ; set volume upward slope
   .byte $00, TIME+3, 0
   .byte $60, 0 ; set volume to zero
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+8, 63
   .byte $90, 5, 20 ; activate vibrato ramp
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $80, 0 ; deactivate vibrato
   .byte $10, 0, BASENOTE+9, 63
   .byte $00, TIME, 0
   .byte $70, 200, 0 ; fade note out quickly

   ; second bar
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+12, 53
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+7, 63
   .byte $40, 0, BASENOTE+4 ; start slide below target note
   .byte $50, 60, 0, 1 ; and set slide rate upwards (mode 1 means the slide stops at the note actually playing)
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+5, 63
   .byte $00, TIME, 0
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+2, 63
   .byte $00, TIME, 0
   .byte $50, 170, 255, 0 ; set unbounded downward slide
   .byte $00, TIME, 0
   .byte $F0 ; end of song


