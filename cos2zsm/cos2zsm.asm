; Copyright 2025 Carl Georg Biermann

::concerto_cos2zsm_converter = 1

.code
    jmp start

; include the X16 header
.include "../common/x16.asm"

; include VRAM assets for symbols
.include "../assets/vram_assets_cos2zsm.asm"

; Scratchpad needed for the location of the Sample-and-Hold table
.include "../common/scratchpad_memory.asm"

; file names etc.
vram_assets_name:
    .byte "vramassets-cos2zsm.bin"
vram_assets_name_end:

.include "../gui/gui_macros.asm"
.include "../synth_engine/snh_lut_generation.asm"

; Synth and song engine
.include "../song_engine/song_engine.asm"

; Include ZSM converter UI
.include "../gui/concerto_gui.asm"


.code
start:
    INIT_VERA
    INIT_CUSTOM_CHARACTERS
    INIT_SNH_LUT goldenram_snh_lut


    ; VRAM assets
    lda #(vram_assets_name_end - vram_assets_name)
    ldx #<vram_assets_name
    ldy #>vram_assets_name
    jsr SETNAM
    lda #1 ; logical file number
    ldx #8 ; device: SD card
    ldy #1 ; secondary command: load address defined by header
    jsr SETLFS
    lda #2 ; load into first half of VRAM
    jsr LOAD


   jsr concerto_synth::initialize
   jsr concerto_gui::initialize
;    inc concerto_gui::gui_variables::request_components_refresh_and_redraw

;    jsr concerto_synth::activate_synth ; not needed?

mainloop:
   jsr concerto_gui::gui_tick
   lda concerto_gui::gui_variables::request_program_exit
   beq mainloop

exit:
   jsr concerto_synth::deactivate_synth
   jsr concerto_gui::hide

   ; Cold-start enter BASIC: program is cleared.
   sec
   jmp ENTER_BASIC




