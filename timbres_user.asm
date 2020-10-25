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