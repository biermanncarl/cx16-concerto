; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE04.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_04_player.asm"


.code

   jmp start

; When including concerto_player, we do not need to include concerto_synth separately,
; since concerto_player includes it for us.
concerto_enable_zsound_recording = 1
.include "concerto_player/concerto_player.asm"



start:
   ; initialize concerto
   jsr concerto_synth::initialize

   jsr concerto_synth::zsm_recording::start_recording

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

   jsr concerto_synth::zsm_recording::stop_recording

   jsr concerto_synth::deactivate_synth

   rts



; DATA

BASENOTE = 53
TIME = 22

hardcoded_song_data: ; this works just as well as an externally loaded song
   ; first bar
   .byte $10, 0, BASENOTE, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+7, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+12, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+7, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+7, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+12, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+7, 63
   .byte $00, TIME, 0

   ; second bar
   .byte $10, 0, BASENOTE+3, 63
   .byte $11, 0, BASENOTE+19, 63
   .byte $12, 0, BASENOTE+15, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+10, 63
   .byte $11, 0, BASENOTE+19, 63
   .byte $12, 0, BASENOTE+15, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+15, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+2, 63
   .byte $11, 0, BASENOTE+17, 63
   .byte $12, 0, BASENOTE+14, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+10, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+14, 63
   .byte $11, 0, BASENOTE+17, 63
   .byte $12, 0, BASENOTE+14, 63
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+15, 63
   .byte $21 ; note-off
   .byte $22 ; note-off
   .byte $00, TIME, 0
   .byte $10, 0, BASENOTE+14, 63
   .byte $00, TIME, 0
   .byte $F0 ; end of song


