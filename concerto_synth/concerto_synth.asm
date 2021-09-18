; Copyright 2021 Carl Georg Biermann


;*****************************************************************************;
; Software: CONCERTO                                                          ;
; Platform: Commander X16 (Emulator R38)                                      ;
; Compiler: CC65                                                              ;
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




; Include this file to be able to use the Concerto synth engine.

; For more information, see readme.md.

; You can employ your own playback routine within each call of the interrupt service routine
; via setting this following (compile time) vector to point to the starting address of
; your own routine before including concerto_synth.asm.
; Example:
;
;    concerto_playback_routine = my_playback_routine
;    .include "concerto_synth/concerto_synth.asm"
;
;    my_playback_routine:
;       ...
;       rts

.scope concerto_synth

.include "x16.asm"
.include "ym2151.asm"
.include "pitch_data.asm"
.include "synth_macros.asm"
.include "timbres.asm"
.include "voices.asm"
.include "synth_tick.asm"
.include "my_isr.asm"
; This just provides some macros which can be used by the host app. Doesn't do anything on its own:
.include "presets.asm"

; Interface parameters
note_channel = r0L
note_timbre  = r0H
note_pitch   = r1L
note_volume  = r1H
pitchslide_position_fine = r2L
pitchslide_position_note = r2H
pitchslide_rate_fine = r3L
pitchslide_rate_note = r3H
; Interface read-only
; These bytes store the number of available voices on the PSG and the FM chip.
; They are exposed to enable e.g. visual feedback how many voices are free
; by the host application.
free_psg_voices = voices::Oscmap::nfo
free_fm_voices = voices::FMmap::nfv

; concerto_synth::initialize
; subroutine to initialize the synth engine
; PARAMETERS: none
; AFFECTS: A, X, Y
initialize:
   jsr timbres::init_timbres
   jsr voices::init_voices
   rts

; concerto_synth::activate_synth
; subroutine to activate the synth engine (i.e. install the interrupt service routine)
; PARAMETERS: none
; AFFECTS: A, X, Y
activate_synth = my_isr::launch_isr

; concerto_synth::deactivate_synth
; subroutine to deactivate the synth engine (i.e. stop voices and uninstall the interrupt service routine)
; PARAMETERS: none
; AFFECTS: A, X, Y
deactivate_synth:
   jsr voices::panic
   jsr my_isr::shutdown_isr ; not the other way round? would be safer ...
   rts

; concerto_synth::play_note
; Plays a note on the given channel. Replaces any other note being played previously on that channel.
; The new note does not get played if there aren't enough voices available at the VERA or the YM2151.
; PARAMETERS: 
;              channel number: r0L
;              note timbre:    r0H
;              note pitch:     r1L
;              note volume:    r1H
; AFFECTS: A, X, Y
; CAUTION: When calling this routine from outside the concerto_playback_routine (e.g. from the program's main loop)
;          you have to ensure that the interrupt flag is set during the subroutine call.
;          Otherwise, the ISR can interfere with this subroutine and cause corruption.
;          Example usage:
;
;             PHP
;             SEI
;             JSR concerto_synth::play_note
;             PLP
play_note = voices::play_note

; concerto_synth::release_note
; Triggers the release phase of the note on a given channel. Even does it if the channel is inactive, but that shouldn't have an effect.
; PARAMETERS:  channel number: r0L
; AFFECTS: A, X, Y
release_note = voices::release_note

; concerto_synth::stop_note
; Immediately turns off the given channel.
; PARAMETERS:  channel number: r0L
; AFFECTS: A, X, Y
; CAUTION: When calling this routine from outside the concerto_playback_routine (e.g. from the program's main loop)
;          you have to ensure that the interrupt flag is set during the subroutine call.
;          Otherwise, the ISR can interfere with this subroutine and cause corruption.
;          Example usage:
;
;             PHP
;             SEI
;             JSR concerto_synth::stop_note
;             PLP
stop_note = voices::stop_note

; concerto_synth::panic
; Immediately turns off all channels, all VERA PSG voices and FM voices.
; PARAMETERS:  none
; AFFECTS: A, X, Y
panic = voices::panic

; concerto_synth::set_pitchslide_position
; Sets the current pitch for the pitch slide on a given channel.
; If pitch slide had been inactive previously, it gets activated and the slide rate is set to zero.
; If coarse position is set to 255, the pitch of the played note is assumed, instead.
; PARAMETERS:  
;              channel number:  r0L
;              position coarse: r2H
;              position fine:   r2L
; AFFECTS: A, X
set_pitchslide_position = voices::set_pitchslide_position

; concerto_synth::set_pitchslide_rate
; Sets the rate for the pitch slide on a given channel.
; If the pitch slide had been inactive previously, it gets activated and is started at the note's current pitch.
; PARAMETERS:  
;              channel number: r0L
;              rate coarse:    r3H
;              rate fine:      r3L
; AFFECTS: A, X
set_pitchslide_rate = voices::set_pitchslide_rate

; concerto_synth::dump_timbres
; Dumps the entirety of timbre data as a byte stream to CHROUT.
; Use this to save all timbre data to an already opened file.
; The number of bytes emitted by this function is always the same (within one version of Concerto).
; PARAMETERS: none
; AFFECTS: A, X, Y
dump_timbres = timbres::dump_to_chrout

; concerto_synth::restore_timbres
; Loads the entire timbre data as a byte stream from CHRIN.
; Use this to load all timbre data from an already opened file.
; The number of bytes consumed by this function is always the same (within one version of Concerto).
; PARAMETERS: none
; AFFECTS: A, X, Y
; RETURNS: 1 in A if successfully loaded
;          0 in A if an error occurred (e.g. wrong data header)
restore_timbres = timbres::restore_from_chrin



; default dummy playback routine being called in the isr
; can be replaced by setting the macro "concerto_playback_routine" to the starting address of a custom playback routine
default_playback:
   rts

.ifndef concerto_playback_routine
   concerto_playback_routine = default_playback
.endif

.endscope