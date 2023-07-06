; Copyright 2023 Carl Georg Biermann

; ***************************************
; Panel legend:
; 0: global synth settings
; 1: oscillator settings
; 2: envelope settings
; 3: synth navigation bar (snav)
; 4: popup panel for listboxes
; 5: LFO settings panel
; 6: help/info panel
; 7: FM general setup
; 8: FM operator setup
; 9: Global navigation bar
; 10: Clip edit
; ***************************************

.ifndef GUI_PANELS_LOOKUP_TABLES_ASM

GUI_PANELS_LOOKUP_TABLES_ASM = 1

.include "generic.asm"
.include "lookup_tables.asm"



.endif ; .ifndef GUI_PANELS_LOOKUP_TABLES_ASM
