; Copyright 2021 Carl Georg Biermann


; This file manages the synth patches.
; The patch data will be read by the synth engine as well as the GUI.

; Disk save and load commands for individual synth patches are found in this file.

; The patch data is organized in arrays. Each successive byte belongs to a different patch.
; For example, the portamento rate is a field of N_TIMBRES bytes (32 the last time I checked).
;    rate of patch 0
;    rate of patch 1
;    rate of patch 2
;    ...
;    rate of patch 31
; Then, the next field:
;    retrigger setting patch 0
;    retrigger setting patch 1
;    ...
; This even holds true for arrays inside a patch, e.g. the attack rate for all envelopes:
;    attack rate Low byte env 1 patch 0
;    attack rate Low byte env 1 patch 1
;    attack rate Low byte env 1 patch 2
;    ...
;    attack rate Low byte env 2 patch 0
;    attack rate Low byte env 2 patch 1
;    attack rate Low byte env 2 patch 2
;    ...

; This is for more efficient accessing of the data.
; Timbre selection needs to be quick for arbitrary access.
; The individual envelopes and oscillators are only parsed from start to finish.
; To access all three envelope settings of a timbre, one starts by setting .X to the
; timbre index, giving the offset of envelope 1.
; Then, by adding N_TIMBRES to .X, we get the offset of envelope 2, and if we do it again,
; we get the offset of envelope 3 of that same patch.
; That way, we can avoid multiplications to find the correct indices.


.scope timbres

timbre_pointer = mzpwg


.scope Timbre
data_start:

   ;general
   n_oscs:  TIMBRE_BYTE_FIELD         ; how many oscillators are used
   n_envs:  TIMBRE_BYTE_FIELD         ; how many envelopes are used
   n_lfos:  TIMBRE_BYTE_FIELD
   porta:   TIMBRE_BYTE_FIELD         ; portamento on/off
   porta_r: TIMBRE_BYTE_FIELD         ; portamento rate
   retrig:  TIMBRE_BYTE_FIELD         ; when monophonic, will envelopes be retriggered? (could be combined with mono variable)
   vibrato: TIMBRE_BYTE_FIELD         ; vibrato amount (a scale5 value but only positive. negative value means inactive)

   ; envelope rates (not times!)
   .scope env
      attackL:  ENVELOPE_TIMBRE_BYTE_FIELD
      attackH:  ENVELOPE_TIMBRE_BYTE_FIELD
      decayL:   ENVELOPE_TIMBRE_BYTE_FIELD
      decayH:   ENVELOPE_TIMBRE_BYTE_FIELD
      sustain:  ENVELOPE_TIMBRE_BYTE_FIELD
      releaseL: ENVELOPE_TIMBRE_BYTE_FIELD
      releaseH: ENVELOPE_TIMBRE_BYTE_FIELD
   .endscope

   ; lfo stuff
   .scope lfo
      rateH:   LFO_TIMBRE_BYTE_FIELD
      rateL:   LFO_TIMBRE_BYTE_FIELD
      wave:    LFO_TIMBRE_BYTE_FIELD   ; waveform select: triangle, square, ramp up, ramp down, noise (S'n'H)
      retrig:  LFO_TIMBRE_BYTE_FIELD   ; retrigger
      offs:    LFO_TIMBRE_BYTE_FIELD   ; offset (high byte only, or seed for SnH)
   .endscope

   ; oscillators
   ; modulation sources are inactive if negative (bit 7 active)
   ; Except amp_sel: it is assumed to be always active.
   ; modulation depth is assumed to be negative if _depH is negative (bit 7 active)
   .scope osc
      ; pitch stuff
      pitch:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; offset (or absolute if no tracking)
      fine:             OSCILLATOR_TIMBRE_BYTE_FIELD    ; unsigned (only up)
      track:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; keyboard tracking on/off (also affects portamento on/off)
      pitch_mod_sel1:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep1:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; pitch modulation depth (Scale5)
      pitch_mod_sel2:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep2:   OSCILLATOR_TIMBRE_BYTE_FIELD    ; pitch modulation depth (Scale5)

      ; volume stuff
      lrmid:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; 0, 64, 128 or 192 for mute, L, R or center
      volume:           OSCILLATOR_TIMBRE_BYTE_FIELD    ; oscillator volume
      amp_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; amplifier select: gate, or one of the envelopes
      vol_mod_sel:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; volume modulation source
      vol_mod_dep:      OSCILLATOR_TIMBRE_BYTE_FIELD    ; volume modulation depth

      ; waveform stuff
      waveform:         OSCILLATOR_TIMBRE_BYTE_FIELD    ; including pulse width (PSG format)
      pulse:            OSCILLATOR_TIMBRE_BYTE_FIELD    ; pulse width
      pwm_sel:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; selects source to modulate pulse width
      pwm_dep:          OSCILLATOR_TIMBRE_BYTE_FIELD    ; pwm modulation depth
      ; etc.
   .endscope

   ; FM stuff
   .scope fm_general
      con:              TIMBRE_BYTE_FIELD   ; the connection algorithm of the timbre (3 bits)
      fl:               TIMBRE_BYTE_FIELD   ; feedback level (3 bits)
      op_en:            TIMBRE_BYTE_FIELD   ; operator enable (4 bits) (also acts as FM enable)
      lr:               TIMBRE_BYTE_FIELD   ; Channels L/R (2 bits) (!!! stored in bits 6 and 7)
      ; pitch related
      pitch:            TIMBRE_BYTE_FIELD    ; offset (or absolute if no tracking)
      fine:             TIMBRE_BYTE_FIELD    ; unsigned (only up)
      track:            TIMBRE_BYTE_FIELD    ; keyboard tracking on/off (also affects portamento on/off)
      pitch_mod_sel:   TIMBRE_BYTE_FIELD    ; selects source for pitch modulation (bit 7 on means none)
      pitch_mod_dep:   TIMBRE_BYTE_FIELD    ; pitch modulation depth (Scale5)
   .endscope

   .scope operators
      level:            OPERATOR_TIMBRE_BYTE_FIELD  ; volume (needs to be converted to attenuation) (7 bits)
      vol_sens:             OPERATOR_TIMBRE_BYTE_FIELD  ; volume sensitivity. (How) does the operator respond to the note's volume?
      ; pitch related
      mul:              OPERATOR_TIMBRE_BYTE_FIELD  ; multiplier for the frequency (4 bits)
      dt1:              OPERATOR_TIMBRE_BYTE_FIELD  ; fine detune (?) (didn't work in YM2151 UI program) (3 bits)
      dt2:              OPERATOR_TIMBRE_BYTE_FIELD  ; coarse detune (2 bits)
      ; envelope
      ar:               OPERATOR_TIMBRE_BYTE_FIELD  ; attack rate (5 bits)
      d1r:              OPERATOR_TIMBRE_BYTE_FIELD  ; decay rate 1 (classical decay)  (5 bits)
      d1l:              OPERATOR_TIMBRE_BYTE_FIELD  ; decay level (or sustain level)  (4 bits)
      d2r:              OPERATOR_TIMBRE_BYTE_FIELD  ; decay rate 2 (0 for sustain)    (5 bits)
      rr:               OPERATOR_TIMBRE_BYTE_FIELD  ; release rate    (4 bits)
      ks:               OPERATOR_TIMBRE_BYTE_FIELD  ; key scaling    (2 bits)
   .endscope
data_end:
timbre_data_size = data_end - data_start
.export timbre_data_size  ; 5888 bytes currently
data_count = timbre_data_size / N_TIMBRES ; 184 currently
.endscope


file_name: ; caution, this string is in screen code!
; "@0:filename01.cop,s,<r/w>" --> 21 bytes
   .byte 32
   .res MAX_FILENAME_LENGTH, 0
   ;.byte 0
   ;.byte 0
   ;.byte 0
   ;.byte 0
   ;.byte 0
   ;.byte 0
   ;.byte 0
   ;.byte 0

concerto_preset_char = 'p'
concerto_bank_char = 'b'

command_preamble: ; the command string is in petscii
   .byte 64,"0:" ; these characters never change
command_string:
   ;.byte 64,"0:preset.cop,s,w"
   .res MAX_FILENAME_LENGTH+8, 0
copying:
   .byte 128 ; which timbre to copy. negative is none
pasting:
   .byte 0   ; where to paste

.export command_preamble
.export command_string

; converts the value in .A from screen code to petscii
screen2petscii:
   cmp #$20
   bcs :+   ; set if we're above $20. then we don't need to do anything
   adc #$40 ; we're below $20. need to add $40
:  rts



; takes screen code string as file name and makes a read/write file command from it
; .X: contains 'p' for single preset, contains 'b' for entire bank
assemble_command_string:
   ldy #0
:  lda file_name, y
   beq @end_loop
   jsr screen2petscii
   sta command_string, y
   iny
   bra :-
@end_loop:
   ; now append ".cop,s," and let the calling routine handle the last "w" or "r"
   lda #'.'
   sta command_string, y
   iny
   lda #'c'
   sta command_string, y
   iny
   lda #'o'
   sta command_string, y
   iny
   txa ; 'p' or 'b' for preset or bank
   sta command_string, y
   iny
   lda #','
   sta command_string, y
   iny
   lda #'s'
   sta command_string, y
   iny
   lda #','
   sta command_string, y
   iny
   rts

; opens file for 
open_file:

   rts

; more info about the Commodore DOS
; https://en.wikipedia.org/wiki/Commodore_DOS

; https://www.pagetable.com/c64ref/kernal/

; opens the file "PRESET.COP" and saves a timbre in it (overwrites existing preset)
; WARNING: No proper error handling (yet)!
; .X:           timbre number
; file_name:    name of the file to store the timbre in (in screen code, without extension)
save_timbre:
   phx
   ldx #'p'
   jsr assemble_command_string ; assemble command
   ; put "w" as last character of the command string
   lda #'w'
   sta command_string, y
   tya
   ; compute command length
   clc
   adc #4 ; including the preamble
   ; set file name (command)
   ldx #(<command_preamble)
   ldy #(>command_preamble)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #2 ; secondary command address, I really don't understand this.
   jsr SETLFS
   bcs @close_file
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file
   ; chkout - open a logical file for output
   ldx #1 ; logical file to be used
   jsr CHKOUT
   ; write magic sequence (aka identifier), last byte is version number
   lda #'c'
   jsr CHROUT
   lda #'o'
   jsr CHROUT
   lda #'p'
   jsr CHROUT
   lda #FILE_VERSION  ; version
   jsr CHROUT
   ; write patch data
   plx
   txa
   clc
   adc #(<Timbre::data_start)
   sta timbre_pointer
   lda #(>Timbre::data_start)
   adc #0
   sta timbre_pointer+1
   ldy #Timbre::data_count
@loop:
   lda (timbre_pointer)
   jsr CHROUT
   lda timbre_pointer
   clc
   adc #N_TIMBRES
   sta timbre_pointer
   lda timbre_pointer+1
   adc #0
   sta timbre_pointer+1
   dey
   bne @loop
   phx ; this phx is just here to cancel the plx after @close_file
   ; close file
@close_file:
   plx
   lda #1
   jsr CLOSE
   jsr CLRCHN
   rts


; opens the file "PRESET.COP" and loads a timbre from it (overwrites existing preset)
; WARNING: No proper error handling (yet)!
; .X:           timbre number
; file_name:    name of the file to load the timbre from (in screen code, without extension)
load_timbre:
   phx
   ldx #'p'
   jsr assemble_command_string ; assemble command
   ; put "r" as last character of the command string
   lda #'r'
   sta command_string, y
   tya
   ; compute command length
   clc
   adc #4 ; including the preamble
   ; set file name (command)
   ldx #(<command_preamble)
   ldy #(>command_preamble)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #2 ; secondary command address, I really don't understand this.
   jsr SETLFS
   bcs @close_file
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file
   ; chkin - open a logical file for input
   ldx #1 ; logical file to be used
   jsr CHKIN
   ; read and compare magic sequence (aka identifier), last byte is version number
   jsr CHRIN
   cmp #'c'
   bne @close_file
   jsr CHRIN
   cmp #'o'
   bne @close_file
   jsr CHRIN
   cmp #'p'
   bne @close_file
   jsr CHRIN
   cmp #FILE_VERSION  ; version
   bne @close_file
   ; read patch data
   plx
   txa
   clc
   adc #(<Timbre::data_start)
   sta timbre_pointer
   lda #(>Timbre::data_start)
   adc #0
   sta timbre_pointer+1
   ldy #Timbre::data_count
@loop:
   jsr CHRIN
   sta (timbre_pointer)
   jsr advance_timbre_pointer
   dey
   bne @loop
   phx ; this phx is just here to cancel the plx after @close_file
@close_file:
   plx
   ; close file
   lda #1
   jsr CLOSE
   jsr CLRCHN
   rts


; file_name:    name of the file to load the timbre from (in screen code, without extension)
save_bank:
   ldx #'b'
   jsr assemble_command_string ; assemble command
   ; put "w" as last character of the command string
   lda #'w'
   sta command_string, y
   tya
   ; compute command length
   clc
   adc #4 ; including the preamble
   ; set file name (command)
   ldx #(<command_preamble)
   ldy #(>command_preamble)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #2 ; secondary command address, I really don't understand this.
   jsr SETLFS
   bcs @close_file
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file
   ; chkout - open a logical file for output
   ldx #1 ; logical file to be used
   jsr CHKOUT
   ; write timbre data
   jsr dump_to_chrout
   ; close file
@close_file:
   lda #1
   jsr CLOSE
   jsr CLRCHN
   rts



; file_name:    name of the file to load the timbre from (in screen code, without extension)
load_bank:
   ldx #'b'
   jsr assemble_command_string ; assemble command
   ; put "r" as last character of the command string
   lda #'r'
   sta command_string, y
   tya
   ; compute command length
   clc
   adc #4 ; including the preamble
   ; set file name (command)
   ldx #(<command_preamble)
   ldy #(>command_preamble)
   jsr SETNAM
   ; setlfs - set logical file number
   lda #1 ; logical file number
   ldx #8 ; device number. 8 is disk drive
   ldy #2 ; secondary command address, I really don't understand this.
   jsr SETLFS
   bcs @close_file
   ; open - open the logical file
   lda #1
   jsr OPEN
   bcs @close_file
   ; chkin - open a logical file for input
   ldx #1 ; logical file to be used
   jsr CHKIN
   ; read timbre data
   jsr restore_from_chrin
@close_file:
   ; close file
   jsr CLOSE
   jsr CLRCHN
   rts



; loads the default sound
; at the same time, this function IS the definition of the default patch.
; X: timbre number, is preserved.
; does not preserve A, Y
load_default_timbre:
   stx pasting
   ; do all "direct" values first
   lda #1
   sta Timbre::n_oscs, x
   sta Timbre::n_envs, x
   sta Timbre::retrig, x
   sta Timbre::n_lfos, x
   stz Timbre::porta, x
   lda #20
   sta Timbre::porta_r, x
   lda #$FF
   sta Timbre::vibrato, x
   ; LFO
   lda #10
   sta Timbre::lfo::rateH, x
   stz Timbre::lfo::rateL, x
   stz Timbre::lfo::wave, x
   stz Timbre::lfo::offs, x
   lda #1
   sta Timbre::lfo::retrig
   ; FM general
   sta Timbre::fm_general::track, x
   lda #7
   sta Timbre::fm_general::con, x
   lda #15
   sta Timbre::fm_general::op_en, x
   stz Timbre::fm_general::fl, x
   lda #%11000000
   sta Timbre::fm_general::lr, x
   ; select no modulation source
   lda #128
   sta Timbre::fm_general::pitch_mod_sel, x
   ; select minimal modulation depth
   lda #15
   sta Timbre::fm_general::pitch_mod_dep, x
   ; envelopes
   ldy #MAX_ENVS_PER_VOICE
@loop_envs:
   stz Timbre::env::attackL, x
   stz Timbre::env::decayL, x
   stz Timbre::env::releaseL, x
   lda #127
   sta Timbre::env::attackH, x
   lda #90
   sta Timbre::env::sustain, x
   lda #2
   sta Timbre::env::decayH, x
   sta Timbre::env::releaseH, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_envs
   ; oscillators
   ldx pasting
   ldy #MAX_OSCS_PER_VOICE
@loop_oscs:
   stz Timbre::osc::pitch, x
   stz Timbre::osc::fine, x
   stz Timbre::osc::amp_sel
   stz Timbre::osc::waveform
   lda #1
   sta Timbre::osc::track, x
   lda #192
   sta Timbre::osc::lrmid, x
   lda #50
   sta Timbre::osc::volume, x
   lda #40
   sta Timbre::osc::pulse, x
   ; select no modulation source
   lda #128
   sta Timbre::osc::pitch_mod_sel1, x
   sta Timbre::osc::pitch_mod_sel2, x
   sta Timbre::osc::vol_mod_sel, x
   sta Timbre::osc::pwm_sel, x
   ; select minimal modulation depths
   lda #15
   sta Timbre::osc::pitch_mod_dep1, x
   sta Timbre::osc::pitch_mod_dep2, x
   stz Timbre::osc::vol_mod_dep, x
   stz Timbre::osc::pwm_dep, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_oscs
   ; FM operators
   ldx pasting
   ldy #N_OPERATORS
@loop_operators:
   stz Timbre::operators::mul, x
   stz Timbre::operators::dt1, x
   stz Timbre::operators::dt2, x
   stz Timbre::operators::ks, x
   lda #31
   sta Timbre::operators::ar, x
   lda #12
   sta Timbre::operators::d1r, x
   lda #4
   sta Timbre::operators::d2r, x
   lda #15
   sta Timbre::operators::d1l, x
   sta Timbre::operators::rr, x
   lda #22
   sta Timbre::operators::level, x
   lda #1
   sta Timbre::operators::vol_sens, x
   txa
   clc
   adc #N_TIMBRES
   tax
   dey
   bne @loop_operators
   ldx pasting
   rts


; initializes all timbres to the default timbre
init_timbres:
   ldx #N_TIMBRES
@loop_timbres:
   dex
   jsr load_default_timbre
   cpx #0
   bne @loop_timbres
   rts

; sets the timbre pointer to the start of the timbre data
initialize_timbre_pointer:
   lda #<Timbre::data_start
   sta timbre_pointer
   lda #>Timbre::data_start
   sta timbre_pointer+1
   rts

; advances the timbre_pointer by N_TIMBRES, i.e. from one parameter to the next
advance_timbre_pointer:
   clc
   lda timbre_pointer
   adc #N_TIMBRES
   sta timbre_pointer
   bcc :+
   inc timbre_pointer+1
:  rts

; copy_paste. copies the timbre stored in variable "copying" to the one given in Y
; if the value of "copying" is negative, nothing is done.
; copy timbre "copying" to timbre "Y"
copy_paste:
   lda copying
   bpl :+
   rts    ; exit if no preset is being copied
:  stx pasting
   ldx #Timbre::data_count
   jsr initialize_timbre_pointer
@loop:
   ldy copying
   lda (timbre_pointer), y
   ldy pasting
   sta (timbre_pointer), y
   jsr advance_timbre_pointer
   dex
   bne @loop
   rts

; dumps all timbre data to CHROUT. can be used to write to an already opened file
dump_to_chrout:
   ; write magic sequence (aka identifier), last byte is version number
   lda #'c'
   jsr CHROUT
   lda #'o'
   jsr CHROUT
   lda #'b'
   jsr CHROUT
   lda #FILE_VERSION  ; version
   jsr CHROUT
   ; write timbre data
   jsr initialize_timbre_pointer
   ldx #Timbre::data_count
@loop_parameters:
   ldy #0
@loop_timbres:
   lda (timbre_pointer), y
   jsr CHROUT ; leaves X and Y untouched
   iny
   cpy #N_TIMBRES
   beq @goto_next_parameter
   bra @loop_timbres
@goto_next_parameter:
   jsr advance_timbre_pointer
   dex
   bne @loop_parameters
   rts

; restores all timbres from a data stream from CHRIN (which was previously dumped via dump_to_chrout)
; can be used to read from an already opened file
restore_from_chrin:
   ; read and compare magic sequence (aka identifier), last byte is version number
   jsr CHRIN
   cmp #'c'
   bne @abort
   jsr CHRIN
   cmp #'o'
   bne @abort
   jsr CHRIN
   cmp #'b'
   bne @abort
   jsr CHRIN
   cmp #FILE_VERSION  ; version
   bne @abort
   ; read timbre data
   jsr initialize_timbre_pointer
   ldx #Timbre::data_count
@loop_parameters:
   ldy #0
@loop_timbres:
   phy
   jsr CHRIN ; leaves X untouched, uses Y (as far as I know)
   ply
   sta (timbre_pointer), y
   iny
   cpy #N_TIMBRES
   beq @goto_next_parameter
   bra @loop_timbres
@goto_next_parameter:
   jsr advance_timbre_pointer
   dex
   bne @loop_parameters
   lda #1 ; success
   rts
@abort:
   lda #0 ; error
   rts


.endscope