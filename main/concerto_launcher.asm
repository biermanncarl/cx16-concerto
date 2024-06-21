; Copyright 2024 Carl Georg Biermann

; This program loads assets and the main program and then proceeds to launch the main program.

.code

    jmp start

; include the X16 header
.include "../common/x16.asm"

; file names etc.
main_prg_name:
    .byte "concmain.prg"
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


start:
    lda #$93
    jsr CHROUT ; clear screen

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
:   bra :-

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
