; this file contains the (user) front end for the patch programming
; It manages the synth patches in a format that is designed to be
; read end edited by the user.
; These front-end-patches will be pre-interpreted for more efficient
; use by the synth engine.

.scope timbres_usr

.scope Timbre
.endscope

.endscope


; Subroutines that will be implemented here are for e.g.
;   * loading/saving presets
;   * editing functions (if needed at all? probably rather macros than subroutines)

; EDIT: I figured that the approach of two separate sets of patch data is simply
; too memory intensive. Therefore there will be only one set of patches,
; with some redundancy (namely user side and interpreter side variables)
; There will be a rule, e.g. if the two sides do not match, the user variables
; are given priority, because then I do only have to implement 
; the conversion user --> interpreter and not the other way around.
; Only the user side variables are stored and loaded in files.