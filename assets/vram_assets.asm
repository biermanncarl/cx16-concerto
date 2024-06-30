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

normal_text_color = lightgray+16*darkgray
darker_text_color = midgray+16*darkgray

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



; ----------  DATA  ----------

; sprite data for box-selection frame
box_selection_frame_size = 32

sprite_index_box_selection_frame_top_left = 1
sprite_index_box_selection_frame_bottom_right = 2
sprite_data_box_selection_frame_top_left:
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
    VERTICAL_LINE color_alg_connection
    SPACES 4, darkgray
    OPERATOR_2
    SPACES 4, darkgray
    VERTICAL_LINE color_alg_connection
    SPACES 4, darkgray
    OPERATOR_3
    SPACES 4, darkgray
    VERTICAL_LINE color_alg_connection
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
    VERTICAL_LINE color_alg_connection
    SPACES 4, darkgray
    OPERATOR_4
    SPACES 13, darkgray
    .res 48 ; padding
@alg_2:
    OPERATOR_1
    OPERATOR_2
    SPACES 3, darkgray
    VERTICAL_LINE color_alg_connection
    VERTICAL_LINE color_alg_connection
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
    VERTICAL_LINE color_alg_connection
    VERTICAL_LINE color_alg_connection
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
    VERTICAL_LINE color_alg_connection
    VERTICAL_LINE color_alg_connection
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
    VERTICAL_LINE color_alg_connection
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


concerto_banner:
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
    CORNER_DOWN_RIGHT @banner_color
    CURVE_DOWN_LEFT @banner_color
    CURVE_DOWN_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
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
    SPACES 1, @background
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
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    SPACES 1, @background
    VERTICAL_LINE @banner_color
    SPACES 1, @background
    CURVE_UP_RIGHT @banner_color
    CURVE_UP_RIGHT @banner_color
    HORIZONTAL_LINE @banner_color
    CURVE_UP_LEFT @banner_color
    ; fifth line
    SPACES 6, @background
    VERTICAL_LINE @banner_color
    SPACES 6, @background
    .byte 22, normal_text_color
    .byte 48, normal_text_color
    .byte 46, normal_text_color
    .byte 54, normal_text_color
    .byte 46, normal_text_color
    .byte 48, normal_text_color
    ; sixth line
    SPACES 5, @background
    .byte $A0, @banner_color
    .byte $7E, @banner_color
    SPACES 12, @background






help_text_note_edit:
    @text_width = 12
    PADDED_TEXT @text_width, normal_text_color, "navigate    "
    PADDED_TEXT @text_width, darker_text_color, "    drag rmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "fast navig  "
    PADDED_TEXT @text_width, darker_text_color, "    ctrl+rmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "new note    "
    PADDED_TEXT @text_width, darker_text_color, "    ctrl+lmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "delete note "
    PADDED_TEXT @text_width, darker_text_color, "     alt+lmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "note length "
    PADDED_TEXT @text_width, darker_text_color, "  drag right"
    PADDED_TEXT @text_width, darker_text_color, " end of note"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "zoom        "
    PADDED_TEXT @text_width, darker_text_color, "    drag cmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "multiselect "
    PADDED_TEXT @text_width, darker_text_color, "   shift+lmb"
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "duplicate   "
    PADDED_TEXT @text_width, darker_text_color, "    ctrl+lmb"

help_text_synth:
    @text_width = 12
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "set values  "
    PADDED_TEXT @text_width, darker_text_color, "    drag lmb"
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "fine adjust "
    PADDED_TEXT @text_width, darker_text_color, "    drag rmb"
    PADDED_TEXT @text_width, darker_text_color, " (edits with"
    PADDED_TEXT @text_width, darker_text_color, "        dot)"
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "hints       "
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, "envelope 1  "
    PADDED_TEXT @text_width, darker_text_color, "defines note"
    PADDED_TEXT @text_width, darker_text_color, "     length."
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, "oscillators,"
    PADDED_TEXT @text_width, darker_text_color, "envs and    "
    PADDED_TEXT @text_width, darker_text_color, "lfo must be "
    PADDED_TEXT @text_width, darker_text_color, "activated   "
    PADDED_TEXT @text_width, darker_text_color, "under global"
    PADDED_TEXT @text_width, darker_text_color, "settings if "
    PADDED_TEXT @text_width, darker_text_color, "used."
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, "the fm voice"
    PADDED_TEXT @text_width, darker_text_color, "is only used"
    PADDED_TEXT @text_width, darker_text_color, "if min. 1 op"
    PADDED_TEXT @text_width, darker_text_color, "is active."




.endscope

.popseg
