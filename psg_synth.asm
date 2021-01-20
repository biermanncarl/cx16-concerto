;*****************************************************************************;
; Program: CONCERTO                                                           ;
; Platform: Commander X16 (Emulator R38)                                      ;
; Compiler: CC65                                                              ;
; Compile with: cl65 -t cx16 -o PSGSYNTH.PRG psg_synth.asm -C cx16-asm.cfg    ;
; Author: Carl Georg Biermann                                                 ;
; Dedication:                                                                 ;
;                                                                             ;
;                  Sing joyfully to the Lord, you righteous;                  ;
;                 it is fitting for the upright to praise him.                ;
;                       Praise the Lord with the harp;                        ;
;                 make music to him on the ten-stringed lyre.                 ;
;                          Sing to him a new song;                            ;
;                    play skillfully, and shout for joy.                      ;
;                 For the word of the Lord is right and true;                 ;
;                       he is faithful in all he does.                        ;
;                                                                             ;
;                            Psalm 33 Verses 1-4                              ;
;                                                                             ;
;*****************************************************************************;

.include "x16.asm"

.zeropage
.include "zeropage.asm"

.segment "CODE"
; BASIC stub to start program
; "10 SYS2061"
.org $0801
.byte $0B, $08, $0A, $00, $9E, $32, $30, $36, $31, $00, $00, $00

; And here is address 2061 = $080D, which is called by BASIC.
.org $080D

   jmp start

; variables/macros
.include "global_definitions.asm"
.include "utility_macros.asm"
.include "synth_macros.asm"
.include "loops.asm"
; sub modules
.include "timbres.asm"
.include "voices.asm"
.include "synth_engine.asm"
.include "player.asm"
.include "my_isr.asm"
.include "guiutils.asm"
.include "gui.asm"
.include "mouse.asm"
.include "presets.asm"

start:

   ; initialization
   ; *******************************

   ; set ROM bank to 0 (from 4, the BASIC ROM)
   stz ROM_BANK

   ; initialize timbres
   ; first load defaults
   jsr timbres::init_timbres
   ; then load custom ones
   PRESET_ONE_OSC_PATCH 0
   PRESET_BRIGHT_PLUCK 1
   PRESET_KEY_1 2
   PRESET_KICK_DRUM_3 3
   PRESET_SNARE_DRUM_5 4
   PRESET_FAT_PLUCK 5
   PRESET_TAMBOURINE 6
   PRESET_KEY_2 7
   PRESET_GUITAR_1 8

   jsr voices::init_voices
   jsr gui::load_synth_gui
   jsr mouse::mouse_init
   jsr my_isr::launch_isr

   ; main loop
   ; *******************************
.include "mainloop.asm"


   ; cleanup code
   ; *******************************
   jsr voices::panic
   jsr my_isr::shutdown_isr

   ; hide mouse pointer
   lda #0
   ldx #0
   jsr MOUSE_CONFIG

   ; restore BASIC ROM page
   lda #4
   sta ROM_BANK

   rts            ; return to BASIC

.segment "RODATA"
.include "pitch_data.asm"
