; Copyright 2024 Carl Georg Biermann

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

.macro OPERATOR_1
    ; first line
    .byte 112, color_alg_connection
    .byte 110, color_alg_connection
    SPACES 3, darkgray
    ; second line
    .byte 109, color_alg_connection
    .byte 49, color_alg_operator
.endmacro

.macro OPERATOR_2
    .byte 50, color_alg_operator
.endmacro

.macro OPERATOR_3
    .byte 51, color_alg_operator
.endmacro

.macro OPERATOR_4
    .byte 52, color_alg_operator
.endmacro

.macro VERTICAL_LINE
    .byte 66, color_alg_connection
.endmacro



; ----------  DATA  ----------

; sprite data for box-selection frame
box_selection_frame_size = 32

sprite_frame_top_left:
    @frame_top_left_color = 1
    @horizontal = @frame_top_left_color << 4 + @frame_top_left_color
    @vertical = @frame_top_left_color << 4
    .repeat box_selection_frame_size / 2
        .byte @horizontal
    .endrepeat
    .repeat box_selection_frame_size - 1
        .byte @vertical
        .repeat box_selection_frame_size / 2 - 1
            .byte background_color
        .endrepeat
    .endrepeat

; text screen data
fm_algs:
@alg_0:
    OPERATOR_1
    SPACES 4, darkgray
    VERTICAL_LINE
    SPACES 4, darkgray
    OPERATOR_2
    SPACES 4, darkgray
    VERTICAL_LINE
    SPACES 4, darkgray
    OPERATOR_3
    SPACES 4, darkgray
    VERTICAL_LINE
    SPACES 4, darkgray
    OPERATOR_4
    SPACES 3, darkgray
    .res 48 ; padding


@alg_1:
    OPERATOR_1
    OPERATOR_2
    SPACES 3, darkgray
    .byte 107, color_alg_connection
    .byte 125, color_alg_connection
    SPACES 3, darkgray
    OPERATOR_3
    SPACES 4, darkgray
    VERTICAL_LINE
    SPACES 4, darkgray
    OPERATOR_4
    SPACES 13, darkgray
    .res 48 ; padding
@alg_2:
    OPERATOR_1
    OPERATOR_2
    SPACES 3, darkgray
    VERTICAL_LINE
    VERTICAL_LINE
    SPACES 3, darkgray
    .byte 107, color_alg_connection
    OPERATOR_3
    SPACES 3, darkgray
    OPERATOR_4
    SPACES 18, darkgray
    .res 48 ; padding
@alg_3:
    OPERATOR_1
    OPERATOR_3
    SPACES 3, darkgray
    VERTICAL_LINE
    VERTICAL_LINE
    SPACES 3, darkgray
    OPERATOR_2
    .byte 115, color_alg_connection
    SPACES 4, darkgray
    OPERATOR_4
    SPACES 17, darkgray
    .res 48 ; padding
@alg_4:
    OPERATOR_1
    OPERATOR_3
    SPACES 3, darkgray
    VERTICAL_LINE
    VERTICAL_LINE
    SPACES 3, darkgray
    OPERATOR_2
    OPERATOR_4
    SPACES 22, darkgray
    .res 48 ; padding
@alg_5:
    OPERATOR_1
    SPACES 4, darkgray
    .byte 107, color_alg_connection
    .byte 114, color_alg_connection
    .byte 110, color_alg_connection
    SPACES 2, darkgray
    OPERATOR_2
    OPERATOR_3
    OPERATOR_4
    SPACES 21, darkgray
    .res 48 ; padding
@alg_6:
    OPERATOR_1
    SPACES 4, darkgray
    VERTICAL_LINE
    SPACES 4, darkgray
    OPERATOR_2
    OPERATOR_3
    OPERATOR_4
    SPACES 21, darkgray
    .res 48 ; padding
@alg_7:
    OPERATOR_1
    OPERATOR_2
    OPERATOR_3
    OPERATOR_4
    SPACES 6*5, darkgray
    .res 48 ; padding

.endscope

.popseg
