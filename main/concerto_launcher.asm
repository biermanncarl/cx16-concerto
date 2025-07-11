; Copyright 2024-2025 Carl Georg Biermann

; This program loads assets and the main program and then proceeds to launch the main program.

.code

    jmp start

; include the X16 header
.include "../common/x16.asm"

; include VRAM assets for symbols
.include "../assets/vram_assets.asm"

; Scratchpad needed for the location of the Sample-and-Hold table
.include "../common/scratchpad_memory.asm"

.include "../gui/gui_macros.asm"
.include "../synth_engine/snh_lut_generation.asm"

; file names etc.
main_prg_name:
    .byte "concmain.bin"
main_prg_name_end:

vram_assets_name:
    .byte "vramassets.bin"
vram_assets_name_end:

message_loading_assets:
    .byte "loading assets ...", $0D, 0

message_loading_concerto:
    .byte "launching concerto ...", $0D, 0


; TRAMPOLINE
; This snippet of code will be copied into golden RAM and from there, will load and execute the main program.
; Since it will be relocated, it cannot contain any absolute jumps within itself, only relative ones.

main_trampoline:
    lda #(main_prg_name_end - main_prg_name)
    ldx #<main_prg_name
    ldy #>main_prg_name
    jsr SETNAM
    lda #1 ; logical file number
    ldx #8 ; device: SD card
    ldy #1 ; secondary command: load at the address in the file header
    jsr SETLFS
    lda #0 ; load into system memory
    jsr LOAD
    jmp $0801 ; where the main program will be loaded
main_trampoline_end:


.macro PRINT_MESSAGE message_addr
    .local print_loop
    .local print_loop_end
        ldx #0
    print_loop:
        lda message_addr, x
        beq print_loop_end
        JSR CHROUT
        inx
        bra print_loop
    print_loop_end:
.endmacro

; parameters for the SETUP_SPRITE macro
sprt_width_8px = 0 * 16
sprt_width_16px = 1 * 16
sprt_width_32px = 2 * 16
sprt_width_64px = 3 * 16
sprt_height_8px = 0 * 64
sprt_height_16px = 1 * 64
sprt_height_32px = 2 * 64
sprt_height_64px = 3 * 64
sprt_mode_4bpp = 0
sprt_mode_8bpp = 128
sprt_vflip_on = 2
sprt_vflip_off = 0
sprt_hflip_on = 1
sprt_hflip_off = 0

; writes a bunch of VRAM registers so that the sprite can be used by just setting the Z-depth and X/Y position
; currently only supports bitmap data in low VRAM bank
.macro SETUP_SPRITE sprite_index, bitmap_address, width, height, bpp_mode, palette_offset, v_flip, h_flip, pos_x, pos_y
    ; messing with a sprite
    .local sprite_offset
    .local sprite_data_address_l
    .local sprite_data_address_h
    sprite_offset = $FC00 + 8 * sprite_index
    sprite_data_address_l = <((bitmap_address >> 5) & $ff)
    sprite_data_address_h = <((bitmap_address & $ff00) >> 13)
    stz VERA_ctrl ; select data0
    lda #(1 + 16) ; high bank, increment by 1
    sta VERA_addr_high
    lda #>sprite_offset
    sta VERA_addr_mid
    lda #<sprite_offset
    sta VERA_addr_low
    ; address 12:5
    lda #sprite_data_address_l
    sta VERA_data0
    ; 4/8bpp mode & address 16:13
    lda #sprite_data_address_h + bpp_mode
    sta VERA_data0
    ; x, y (4 bytes)
    lda #<pos_x
    sta VERA_data0
    lda #>pos_x
    sta VERA_data0
    lda #<pos_y
    sta VERA_data0
    lda #>pos_y
    sta VERA_data0
    ; collision mask, z-depth, V-flip, H-flip
    lda #v_flip + h_flip ; + 3*4 ; uncomment activates for inspection
    sta VERA_data0
    ; sprite height, width, palette offset
    lda #width + height + palette_offset
    sta VERA_data0
.endmacro


start:
    INIT_VERA

    PRINT_MESSAGE message_loading_assets

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

    ; need a non-transparent black for 4bpp sprites --> set palette index 33 to black
    palette_offset = $FA00 ; in high VRAM bank
    @color_offset = palette_offset + 2 * 33
    stz VERA_ctrl ; select data0
    lda #1 + 16 ; select high bank, increment by 1
    sta VERA_addr_high
    lda #>@color_offset
    sta VERA_addr_mid
    lda #<@color_offset
    sta VERA_addr_low
    lda #$00 ; black
    sta VERA_data0
    sta VERA_data0

    ; setup sprites
    SETUP_SPRITE vram_assets::sprite_index_box_selection_frame_top_left, vram_assets::sprite_data_box_selection_frame_top_left, sprt_width_32px, sprt_height_32px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 0, 0
    SETUP_SPRITE vram_assets::sprite_index_box_selection_frame_bottom_right, vram_assets::sprite_data_box_selection_frame_top_left, sprt_width_32px, sprt_height_32px, sprt_mode_4bpp, 2, sprt_vflip_on, sprt_hflip_on, 0, 0
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_1, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 72
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_2, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 136
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_3, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 200
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_4, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 264
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_5, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 328
    SETUP_SPRITE vram_assets::sprite_index_playback_marker_6, vram_assets::sprite_data_playback_marker, sprt_width_8px, sprt_height_64px, sprt_mode_4bpp, 2, sprt_vflip_off, sprt_hflip_off, 100, 392

    INIT_CUSTOM_CHARACTERS


    INIT_SNH_LUT goldenram_snh_lut



    PRINT_MESSAGE message_loading_concerto

    ; load trampoline code into golden RAM and then ... jump!
    ldx #(main_trampoline_end - main_trampoline)
@load_trampoline_loop:
    dex
    bmi @load_trampoline_end
    lda main_trampoline, x
    sta GOLDEN_RAM_START, x
    bra @load_trampoline_loop
@load_trampoline_end:
    jmp GOLDEN_RAM_START



