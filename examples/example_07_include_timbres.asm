; Copyright 2021-2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE04.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_04_player.asm"


.code

   jmp start

; Configure instrument inclusion
concerto_use_instruments_from_file = 1
.define CONCERTO_INSTRUMENTS_PATH "FACTORY.COB"

; When including concerto_player, we do not need to include concerto_synth separately,
; since concerto_player includes it for us.
.include "../simple_player/concerto_player.asm"



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

BASENOTE = 41
TIME = 22
BASS_INSTRUMENT = 0
BASS_VOLUME = 55
LEAD_INSTRUMENT = 9
LEAD_VOLUME = 63
KICK_INSTRUMENT = 20
SNARE_INSTRUMENT = 21

hardcoded_song_data: ; this works just as well as an externally loaded song
   ; first bar
   .byte $10, BASS_INSTRUMENT, BASENOTE, BASS_VOLUME
   .byte $18, KICK_INSTRUMENT, 0, 63
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+7, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+12, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+7, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE, BASS_VOLUME
   .byte $18, SNARE_INSTRUMENT, 0, 63
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+7, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+12, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+7, BASS_VOLUME
   .byte $18, KICK_INSTRUMENT, 0, 63
   .byte $00, TIME, 0

   ; second bar
   .byte $10, BASS_INSTRUMENT, BASENOTE+3, BASS_VOLUME
   .byte $18, KICK_INSTRUMENT, 0, 63
   .byte $11, LEAD_INSTRUMENT, BASENOTE+19, LEAD_VOLUME
   .byte $12, LEAD_INSTRUMENT, BASENOTE+15, LEAD_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+10, BASS_VOLUME
   .byte $11, LEAD_INSTRUMENT, BASENOTE+19, LEAD_VOLUME
   .byte $12, LEAD_INSTRUMENT, BASENOTE+15, LEAD_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+15, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+2, BASS_VOLUME
   .byte $11, LEAD_INSTRUMENT, BASENOTE+17, LEAD_VOLUME
   .byte $12, LEAD_INSTRUMENT, BASENOTE+14, LEAD_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+10, BASS_VOLUME
   .byte $18, SNARE_INSTRUMENT, 0, 63
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+14, BASS_VOLUME
   .byte $11, LEAD_INSTRUMENT, BASENOTE+17, LEAD_VOLUME
   .byte $12, LEAD_INSTRUMENT, BASENOTE+14, LEAD_VOLUME
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+15, BASS_VOLUME
   .byte $21 ; note-off
   .byte $22 ; note-off
   .byte $00, TIME, 0
   .byte $10, BASS_INSTRUMENT, BASENOTE+14, BASS_VOLUME
   .byte $00, TIME, 0
   .byte $F0 ; end of song


