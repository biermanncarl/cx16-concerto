; Copyright 2025 Carl Georg Biermann

; Stuff that goes into VRAM.
; Specifically, this file is loaded into the first bank of video RAM after the
; text screen memory at address 0 (size 15k=60*256 bytes).
; The contents of this file are all data, no executable code contained.
;
; The contents are assembled into their own VRAM1ASSETS segment, which is emitted into its own file.
; Still, the addresses / labels can be used by the including program to access the assets in video RAM.

.pushseg
.segment "VRAM1LOADADDR"
.import __VRAM1ASSETS_START__
.word __VRAM1ASSETS_START__ ; load address, first two bytes in the file

.segment "VRAM1ASSETS"

.scope vram_assets

background_color = 0

; color names of first 16 standard colors
black = 0
white = 1
red = 2
cyan = 3
magenta = 4
green = 5
blue = 6
yellow = 7
orange = 8
brown = 9
lightred = 10
darkgray = 11
midgray = 12
lightgreen = 13
lightblue = 14
lightgray = 15

; combined colors
color_alg_connection = lightgray+16*darkgray
color_alg_operator = lightgreen+16*black

.macro SPACES num, color
    .repeat num
        .byte 32
        .byte color*16
    .endrepeat
.endmacro

normal_text_color = lightgray+16*darkgray
darker_text_color = midgray+16*darkgray
orange_text_color = orange+16*darkgray
white_text_color = white+16*darkgray

.macro PADDED_TEXT length, color, str
    ; stolen from the STR_FORMAT macro
    .repeat .strlen(str), i
        .if (.strat(str, i)=32)
            .byte 32
        .else
            .if (.strat(str, i)>64) && (.strat(str, i)<91)
                .byte .strat(str, i)-64
            .else
                .byte .strat(str, i)
            .endif
        .endif
        .byte color
    .endrepeat
    SPACES (length - .strlen(str)), color>>4
.endmacro

.macro VERTICAL_LINE color
    .byte 66, color
.endmacro

.macro HORIZONTAL_LINE color
    .byte 64, color
.endmacro

.macro CURVE_UP_LEFT color
    .byte $4B, color
.endmacro

.macro CURVE_UP_RIGHT color
    .byte $4A, color
.endmacro

.macro CURVE_DOWN_LEFT color
    .byte $49, color
.endmacro

.macro CURVE_DOWN_RIGHT color
    .byte $55, color
.endmacro

.macro CORNER_DOWN_RIGHT color
    .byte $70, color
.endmacro

.macro CORNER_UP_LEFT color
    .byte $7D, color
.endmacro 

.macro CORNER_UP_RIGHT color
    .byte $6D, color
.endmacro 


; ----------  DATA  ----------

; Must be aligned with 256 bytes (if not, need to adapt multiplication code to not make that assumption)
vera_fx_scratchpad:
    .res 4
    .res 28 ; padding to give sprite data 32-byte alignment


converto_banner:
    @background = darkgray
    @foreground = white
    @banner_color = 16*@background + @foreground
    ; size: 19 by 6 characters
    ; first line
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    HORIZONTAL_LINE @banner_color
    SPACES 12, @background
    VERTICAL_LINE @banner_color
    SPACES 3, @background
    ; second line
    VERTICAL_LINE @banner_color
    SPACES 2, @background
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_DOWN_LEFT @banner_color
    CURVE_UP_RIGHT @banner_color
    CURVE_DOWN_LEFT @banner_color
    ; VERTICAL_LINE @banner_color
    ; VERTICAL_LINE @banner_color
    ; SPACES 2, @background
    CURVE_DOWN_LEFT @banner_color
    CURVE_DOWN_RIGHT @banner_color
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_DOWN_LEFT @banner_color
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    .byte $6B, @banner_color
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_DOWN_LEFT @banner_color
    ; third line
    VERTICAL_LINE @banner_color
    SPACES 2, @background
    VERTICAL_LINE @banner_color
    SPACES 1, @background
    VERTICAL_LINE @banner_color
    VERTICAL_LINE @banner_color
    VERTICAL_LINE @banner_color
    VERTICAL_LINE @banner_color
    VERTICAL_LINE @banner_color
    .byte $6B, @banner_color
    HORIZONTAL_LINE @banner_color
    CORNER_UP_LEFT @banner_color
    VERTICAL_LINE @banner_color
    SPACES 1, @background
    VERTICAL_LINE @banner_color
    VERTICAL_LINE @banner_color
    SPACES 1, @background
    VERTICAL_LINE @banner_color
    ; fourth line
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_UP_LEFT @banner_color
    VERTICAL_LINE @banner_color
    CURVE_UP_RIGHT @banner_color
    CORNER_UP_RIGHT @banner_color
    CURVE_UP_LEFT @banner_color
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    SPACES 1, @background
    .byte $41, @banner_color
    SPACES 1, @background
    CURVE_UP_RIGHT @banner_color
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_UP_LEFT @banner_color
    ; fifth line
    SPACES 6, @background
    VERTICAL_LINE @banner_color
    SPACES 12, @background
    ; sixth line
    SPACES 5, @background
    .byte $A0, @banner_color
    .byte $7E, @banner_color
    SPACES 12, @background



.endscope

.popseg
