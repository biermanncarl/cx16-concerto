; Copyright 2020, 2021 Matt Heffernan, Carl Georg Biermann


; This file contains various definitions of Commander X16 addresses and values.
; It is based on a file made by Matt Heffernan.

.ifndef COMMON_X16_ASM ; We're intentionally not using the global namespace here, since this file may be included in several namespaces for convenience.
COMMON_X16_ASM = 1

SD_DEVICE   = 1
HOST_DEVICE = 8
DISK_DEVICE = HOST_DEVICE


; RAM Addresses

; Kernal Registers
r0                = $02
r0L               = r0
r0H               = r0+1
r1                = $04
r1L               = r1
r1H               = r1+1
r2                = $06
r2L               = r2
r2H               = r2+1
r3                = $08
r3L               = r3
r3H               = r3+1
r4                = $0A
r4L               = r4
r4H               = r4+1
r5                = $0C
r5L               = r5
r5H               = r5+1
r6                = $0E
r6L               = r6
r6H               = r6+1
r7                = $10
r7L               = r7
r7H               = r7+1
r8                = $12
r8L               = r8
r8H               = r8+1
r9                = $14
r9L               = r9
r9H               = r9+1
r10               = $16
r10L              = r10
r10H              = r10+1
r11               = $18
r11L              = r11
r11H              = r11+1
r12               = $1A
r12L              = r12
r12H              = r12+1
r13               = $1C
r13L              = r13
r13H              = r13+1
r14               = $1E
r14L              = r14
r14H              = r14+1
r15               = $20
r15L              = r15
r15H              = r15+1

; I/O Registers
VERA_addr_low     = $9F20
VERA_addr_mid     = $9F21
VERA_addr_high    = $9F22
VERA_data0        = $9F23
VERA_data1        = $9F24
VERA_ctrl         = $9F25
VERA_ien          = $9F26
VERA_isr          = $9F27
VERA_irqline_l    = $9F28
VERA_dc_video     = $9F29
VERA_dc_hscale    = $9F2A
VERA_dc_vscale    = $9F2B
VERA_dc_border    = $9F2C
VERA_dc_hstart    = $9F29
VERA_dc_hstop     = $9F2A
VERA_dc_vsstart   = $9F2B
VERA_dc_vstop     = $9F2C
VERA_L0_config    = $9F2D
VERA_L0_mapbase   = $9F2E
VERA_L0_tilebase  = $9F2F
VERA_L0_hscroll_l = $9F30
VERA_L0_hscroll_h = $9F31
VERA_L0_vscroll_l = $9F32
VERA_L0_vscroll_h = $9F33
VERA_L1_config    = $9F34
VERA_L1_mapbase   = $9F35
VERA_L1_tilebase  = $9F36
VERA_L1_hscroll_l = $9F37
VERA_L1_hscroll_h = $9F38
VERA_L1_vscroll_l = $9F39
VERA_L1_vscroll_h = $9F3A
VERA_audio_ctrl   = $9F3B
VERA_audio_rate   = $9F3C
VERA_audio_data   = $9F3D
VERA_spi_data     = $9F3E
VERA_spi_ctrl     = $9F3F


ROM_BANK          = $0001
RAM_BANK          = $0000

YM_reg            = $9F40
YM_data           = $9F41

; Emulator Registers
GIF_ctrl          = $9FB5

; ROM Banks
KERNAL_ROM_BANK   = 0
BASIC_ROM_BANK    = 4

; Banked Addresses
RAM_WIN           = $A000
RAM_WIN_SIZE      = $2000
ROM_WIN           = $C000

; Kernal Subroutines
CONSOLE_set_paging_message    := $FED5
CONSOLE_put_image             := $FED8
CONSOLE_init                  := $FEDB
CONSOLE_put_char              := $FEDE
CONSOLE_get_char              := $FEE1
MEMORY_FILL                   := $FEE4
MEMORY_COPY                   := $FEE7
MEMORY_CRC                    := $FEEA
MEMORY_DECOMPRESS             := $FEED
SPRITE_set_image              := $FEF0
SPRITE_set_position           := $FEF3
FB_init                       := $FEF6
FB_get_info                   := $FEF9
FB_set_palette                := $FEFC
FB_cursor_position            := $FEFF
FB_cursor_next_line           := $FF02
FB_get_pixel                  := $FF05
FB_get_pixels                 := $FF08
FB_set_pixel                  := $FF0B
FB_set_pixels                 := $FF0E
FB_set_8_pixels               := $FF11
FB_set_8_pixels_opaque        := $FF14
FB_fill_pixels                := $FF17
FB_filter_pixels              := $FF1A
FB_move_pixels                := $FF1D
GRAPH_init                    := $FF20
GRAPH_clear                   := $FF23
GRAPH_set_window              := $FF26
GRAPH_set_colors              := $FF29
GRAPH_draw_line               := $FF2C
GRAPH_draw_rect               := $FF2F
GRAPH_move_rect               := $FF32
GRAPH_draw_oval               := $FF35
GRAPH_draw_image              := $FF38
GRAPH_set_font                := $FF3B
GRAPH_get_char_size           := $FF3E
GRAPH_put_char                := $FF41
MONITOR                       := $FF44
ENTER_BASIC                   := $FF47
CLOCK_SET_DATE_TIME           := $FF4D
CLOCK_GET_DATE_TIME           := $FF50
JOYSTICK_SCAN                 := $FF53
JOYSTICK_GET                  := $FF56
SCREEN_SET_MODE               := $FF5F
SCREEN_SET_CHARSET            := $FF62

MOUSE_CONFIG                  := $FF68
MOUSE_GET                     := $FF6B
MOUSE_SCAN                    := $FF71
KBDBUF_GET_MODIFIERS          := $FEC0
SCINIT                        := $FF81
IOINIT                        := $FF84
RAMTAS                        := $FF87
RESTOR                        := $FF8A
READST                        := $FFB7
SETLFS                        := $FFBA
SETNAM                        := $FFBD
OPEN                          := $FFC0
CLOSE                         := $FFC3
CHKIN                         := $FFC6
CHKOUT                        := $FFC9
CLRCHN                        := $FFCC
CHRIN                         := $FFCF
CHROUT                        := $FFD2
LOAD                          := $FFD5
SAVE                          := $FFD8
SETTIM                        := $FFDB
RDTIM                         := $FFDE
STOP                          := $FFE1
GETIN                         := $FFE4
CLALL                         := $FFE7
UDTIM                         := $FFEA
SCREEN                        := $FFED
PLOT                          := $FFF0
IOBASE                        := $FFF3

; BASIC Vectors
BASIC_PANIC       := $C000
BASIC_INIT        := $C003


; VRAM Addresses
VRAM_petscii   = $0F800
VRAM_psg       = $1F9C0
VRAM_palette   = $1FA00
VRAM_sprattr   = $1FC00

; IRQs
IRQVec         := $0314
BRKVec         := $0316
NMIVec         := $0318

; VIA
; $9F60 to $9F6F or $9F00 to $9F0F ?
VIA_ORB_IRB_B      := $9F00  ; input/output register byte B
VIA_ORB_IRB_A      := $9F01  ; input/output register byte A
VIA_DDR_B          := $9F02  ; data direction register B
VIA_DDR_A          := $9F03  ; data direction register A
VIA_T1C_L          := $9F04  ; T1 Low-Order Latches (write) and T1 Low-Order Counter (read)
VIA_T1C_H          := $9F05  ; T1 High-Order Counter
VIA_T1L_L          := $9F06  ; T1 Low-Order Latches (reading does not reset timer interrupt flag)
VIA_T1L_H          := $9F07  ; T1 High-Order Latches
VIA_T2C_L          := $9F08  ; T2 Low-Order Latches (write) and T2 Low-Order Counter (read)
VIA_T2C_H          := $9F09  ; T2 High-Order Counter
VIA_SR             := $9F0A  ; Shift Register
VIA_ACR            := $9F0B  ; Auxiliary Control Register
VIA_PCR            := $9F0C  ; Peripheral Control Register
VIA_IFR            := $9F0D  ; Interrupt Flag Register
VIA_IER            := $9F0E  ; Interrupt Enable Register
VIA_ORA_IRA        := $9F0F  ; Same as Reg 1 except no "Handshake"

; Keyboard modifiers
KBD_MODIFIER_SHIFT = $01
KBD_MODIFIER_ALT   = $02
KBD_MODIFIER_CTRL  = $04
KBD_MODIFIER_LOGO  = $08
KBD_MODIFIER_CAPS  = $10

GOLDEN_RAM_START = $0400
GOLDEN_RAM_END = $07FF

.endif ; .ifndef COMMON_X16_ASM
