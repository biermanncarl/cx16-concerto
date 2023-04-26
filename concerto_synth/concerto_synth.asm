; Copyright 2021-2022 Carl Georg Biermann


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



; Loading of timbre data at compile time
; ======================================
; Two definitions need to be made in order to use an existing timbre bank (*.COB) file at compile time.
; The first one, concerto_use_timbres_from_file, needs to be set in order to communicate
; to the assembler THAT an external file is being used.
; The second one, CONCERTO_TIMBRES_PATH, is set to the file name containing the timbre data.
; Both definitions need to be made before the inclusion of this file (concerto_synth.asm).
; Example:
;
;    concerto_use_timbres_from_file = 1
;    .define CONCERTO_TIMBRES_PATH "FACTORY.COB"
;    .include "concerto_synth.asm"

; Enabling the Zsound recorder
; ============================
; Concerto's output can be recorded into Zsound data. (https://github.com/ZeroByteOrg/zsound)
; As this comes with a runtime and memory overhead, it must be enabled via a compiler variable.
; Before including this file, set the variable, for example as follows:
;
;    concerto_enable_zsound_recorder = 1
;    .include "concerto_synth.asm"
;

; Selecting the timing source
; ===========================
; Either the AFLOW interrupt or the VIA1 can be used as timing source.
; Using AFLOW blocks the usage of PCM audio, while the VIA1 option uses a timer of the VIA1 chip.
; Before including this file, set concerto_clock_select either to 1 for AFLOW or to 2 for the VIA1 option,
; for example:
;
;    concerto_clock_select = 1
;    .include "concerto_synth.asm"
;
; By default, the VIA1 option is used. (If in doubt, check isr.asm)

.pushseg
.code

.scope concerto_synth

.include "x16.asm"
.include "ym2151.asm"
.include "synth_zeropage.asm"
.include "pitch_data.asm"
.include "vibrato_lut.asm"
.include "synth_macros.asm"
.ifdef ::concerto_enable_zsound_recording
   .include "zsm_recording.asm"
.endif
.include "timbres.asm"
.include "voices.asm"
.include "synth_tick.asm"
.include "isr.asm"
.include "scale5.asm"
; This just provides some macros which can be used by the host app. Doesn't do anything on its own:
.include "presets.asm"

; Concerto API registers
creg0 = mzpba
creg1 = mzpbf
creg2 = mzpbg

; Interface parameters
note_channel = creg0
note_timbre  = creg1
note_pitch   = creg2
pitchslide_mode = creg1
; Interface read-only
; These bytes store the number of currently available voices on the PSG and the FM chip.
; They are exposed to enable e.g. visual feedback how many voices are free
; by the host application.
free_psg_voices = voices::Oscmap::nfo
free_fm_voices = voices::FMmap::nfv

; concerto_synth::initialize
; subroutine to initialize the synth engine
; PARAMETERS: none
; AFFECTS: .A, .X, .Y
initialize:
.ifndef concerto_use_timbres_from_file
   jsr timbres::init_timbres
.endif
   jsr voices::init_voices
   rts

; concerto_synth::activate_synth
; subroutine to activate the synth engine (i.e. install the interrupt service routine)
; PARAMETERS: none
; AFFECTS: .A, .X, .Y
activate_synth = isr::launch_isr

; concerto_synth::deactivate_synth
; subroutine to deactivate the synth engine (i.e. stop voices and uninstall the interrupt service routine)
; PARAMETERS: none
; AFFECTS: .A, .X, .Y
deactivate_synth:
   jsr voices::panic
   jsr isr::shutdown_isr ; not the other way round? would be safer ...
   rts

; concerto_synth::play_note
; Plays a note on the given channel. Replaces any other note being played previously on that channel.
; The new note does not get played if there aren't enough voices available at the VERA or the YM2151.
; PARAMETERS: 
;              channel number: note_channel
;              note timbre:    note_timbre
;              note pitch:     note_pitch
;              note volume:    .A
; AFFECTS: .A, .X, .Y
play_note = voices::play_note

; concerto_synth::release_note
; Triggers the release phase of the note on a given channel. Even does it if the channel is inactive, but that shouldn't have an effect.
; PARAMETERS:  channel number: note_channel
; AFFECTS: .A, .X, .Y
release_note = voices::release_note

; concerto_synth::stop_note
; Immediately turns off the given channel.
; PARAMETERS:  channel number: note_channel
; AFFECTS: .A, .X, .Y
stop_note = voices::stop_note

; concerto_synth::panic
; Immediately turns off all channels, all VERA PSG voices and FM voices.
; PARAMETERS:  none
; AFFECTS: .A, .X, .Y
panic = voices::panic

; concerto_synth::set_pitchslide_position
; Sets the current pitch for the pitch slide on a given channel.
; If pitch slide had been inactive previously, it gets activated and the slide rate is set to zero.
; If coarse position is set to 255, the pitch of the played note is assumed, instead (such as to easily reset the pitch to the note played).
; PARAMETERS:  
;              channel number:  .X
;              position coarse: .A
;              position fine:   .Y
; AFFECTS: .A
set_pitchslide_position = voices::set_pitchslide_position

; concerto_synth::set_pitchslide_rate
; Sets the rate for the pitch slide on a given channel.
; If the pitch slide had been inactive previously, it gets activated and is started at the note's current pitch.
; mode = 0 yields a free slide, mode = 1 yields a slide that stops at the original note.
; PARAMETERS:  
;              channel number: .X
;              rate coarse:    .Y
;              rate fine:      .A
;              mode:           pitchslide_mode
; AFFECTS: .A
set_pitchslide_rate = voices::set_pitchslide_rate

; concerto_synth::set_volume
; Sets the volume of the note playing at a channel.
; The effect lasts until the next note is played, which overwrites the volume set previously.
; PARAMETERS:
;              channel number: .X
;              volume:         .A  (0 to 63)
; AFFECTS: .A, .X, .Y
set_volume = voices::set_volume

; concerto_synth::set_volume_ramp
; Ramps the volume from the current value up or down, until it reaches the given
; threshold, or until the next note trigger.
; The slope may be positive or negative.
; PARAMETERS:
;              channel number: .X
;              slope:          .A  (-127 to 128)
;              threshold:      .Y  (0 to 63)
; AFFECTS: .A
set_volume_ramp = voices::set_volume_ramp

; concerto_synth::set_vibrato_amount
; Controls how much the LFO modulates the voice's pitch. Values from 0 to 75
; are valid. The frequency and waveform of the LFO is dictated by the timbre's
; settings.
; Calling this function temporarily overwrites the "vibrato" setting of the
; timbre.
; The original setting is restored by passing 0 as the modulation amount,
; after channel inactivity or upon timbre change on the channel.
; The LFO must be activated in the timbre for vibrato!
; PARAMETERS:
;              channel number: .X
;              vibrato amount: .A (values 0 to 27)
; AFFECTS: .A
set_vibrato_amount = voices::set_vibrato_amount

; concerto_synth::set_vibrato_ramp
; The vibrato amount can be set to increase over time. This command sets the
; increase rate and the maximum vibrato level that shall be reached.
; PARAMETERS:
;              channel number:   .X
;              slope:            .A
;              threshold level:  .Y (values 1 to 27 on positive slope, 0 to 26 on negative slope)
; AFFECTS: .A
set_vibrato_ramp = voices::set_vibrato_ramp

; concerto_synth::dump_timbres
; Dumps the entirety of timbre data as a byte stream to CHROUT.
; Use this to save all timbre data to an already opened file.
; The number of bytes emitted by this function is always the same (within one version of Concerto).
; PARAMETERS: none
; AFFECTS: .A, .X, .Y
dump_timbres = timbres::dump_to_chrout

; concerto_synth::restore_timbres
; Loads the entire timbre data as a byte stream from CHRIN.
; Use this to load all timbre data from an already opened file.
; The number of bytes consumed by this function is always the same (within one version of Concerto).
; PARAMETERS: none
; AFFECTS: .A, .X, .Y
; RETURNS: 1 in .A if successfully loaded
;          0 in .A if an error occurred (e.g. wrong data header)
restore_timbres = timbres::restore_from_chrin



; default dummy playback routine being called in the isr
; can be replaced by setting the macro "concerto_playback_routine" to the starting address of a custom playback routine
default_playback:
   rts

.ifndef concerto_playback_routine
   concerto_playback_routine = default_playback
.endif

.endscope

.popseg
