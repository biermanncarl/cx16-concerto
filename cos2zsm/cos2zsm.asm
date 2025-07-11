; Copyright 2025 Carl Georg Biermann

.code
    jmp start

; include the X16 header
.include "../common/x16.asm"

; include VRAM assets for symbols
; .include "../assets/vram_assets.asm"

; Scratchpad needed for the location of the Sample-and-Hold table
.include "../common/scratchpad_memory.asm"

; file names etc.
; vram_assets_name:
;     .byte "vramassets.bin"
; vram_assets_name_end:

.include "../gui/gui_macros.asm"
.include "../synth_engine/snh_lut_generation.asm"

.code
start:
    INIT_VERA


    ; VRAM assets ?
    ; lda #(vram_assets_name_end - vram_assets_name)
    ; ldx #<vram_assets_name
    ; ldy #>vram_assets_name
    ; jsr SETNAM
    ; lda #1 ; logical file number
    ; ldx #8 ; device: SD card
    ; ldy #1 ; secondary command: load address defined by header
    ; jsr SETLFS
    ; lda #2 ; load into first half of VRAM
    ; jsr LOAD

    INIT_CUSTOM_CHARACTERS

    INIT_SNH_LUT goldenram_snh_lut








