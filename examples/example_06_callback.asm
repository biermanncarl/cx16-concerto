; Copyright 2022 Carl Georg Biermann


; Compile with: cl65 -t cx16 -o EXAMPLE06.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_06_callback.asm"


.code

   jmp start

; When including concerto_player, we do not need to include concerto_synth separately,
; since concerto_player includes it for us.
.include "../simple_player/concerto_player.asm"

CURSOR_LEFT = $9D
CLEAR = $93
CHROUT = $FFD2
GETIN  = $FFE4

; custom callback routine
my_callback:
   ; argument comes in .A
   ; just print it out
   jsr CHROUT
   rts

start:
   ; clear screen
   lda #CLEAR
   jsr CHROUT

   ; initialize concerto
   jsr concerto_synth::initialize

   ; register custom callback
   lda #<my_callback
   sta concerto_player::callback_vector
   lda #>my_callback
   sta concerto_player::callback_vector+1

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
   jsr GETIN
   beq mainloop

   jsr concerto_synth::deactivate_synth

   rts



; DATA

KICKNOTE = 60
BASSNOTE = 35
TIME = 26

hardcoded_song_data: ; this works just as well as an externally loaded song
   ; first bar
   .byte $D0, " " ; callback
   .byte $D0, "h" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, "y" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, "s" ; callback
   .byte $D0, "t" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, "v" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, "h" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, "y" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, "s" ; callback
   .byte $D0, "t" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, "v" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0

   ; second bar
   .byte $D0, "c" ; callback
   .byte $D0, "o" ; callback
   .byte $D0, "m" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, "h" ; callback
   .byte $D0, "o" ; callback
   .byte $D0, "m" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, "c" ; callback
   .byte $D0, "o" ; callback
   .byte $D0, "m" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0
   .byte $D0, "h" ; callback
   .byte $D0, "o" ; callback
   .byte $D0, "m" ; callback
   .byte $D0, "e" ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, KICKNOTE, 63
   .byte $50, 220, 254, 0 ; pitch slope
   .byte $00, TIME, 0
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, " " ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $D0, CURSOR_LEFT ; callback
   .byte $10, 0, BASSNOTE, 63
   .byte $70, 240, 0 ; volume slope
   .byte $00, TIME, 0

   .byte $F0 ; end of song


