; Copyright 2024 Carl Georg Biermann

; Stuff that goes into VRAM.
; Specifically, this file is loaded into the first bank of video RAM after the
; text screen memory at address 0 (size 15k=60*256 bytes).
; The contents of this file are all data, no executable code contained.
;
; The contents are assembled into their own VRAM1ASSETS segment, which is emitted into its own file.
; Still, the addresses / labels can be used by the including program to access the assets in video RAM.
; This file gets assembled twice -- once during assembly of the loader, and once more for the main program.
; But that's no problem.

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

; Must be aligned with 256 bytes (if not, need to adapt multiplication code to not make that assumption)
vera_fx_scratchpad:
    .res 4
    .res 28 ; padding to give sprite data 32-byte alignment

; sprite data for box-selection frame
box_selection_frame_size = 32

sprite_index_box_selection_frame_top_left = 1
sprite_index_box_selection_frame_bottom_right = 2
sprite_data_box_selection_frame_top_left:
    @frame_top_left_color = 1 ; using black at palette position 33 in 4bpp mode, palette offset 2
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

; sprite data for playback marker
sprite_index_playback_marker_1 = sprite_index_box_selection_frame_bottom_right + 1
sprite_index_playback_marker_2 = sprite_index_playback_marker_1 + 1
sprite_index_playback_marker_3 = sprite_index_playback_marker_2 + 1
sprite_index_playback_marker_4 = sprite_index_playback_marker_3 + 1
sprite_index_playback_marker_5 = sprite_index_playback_marker_4 + 1
sprite_index_playback_marker_6 = sprite_index_playback_marker_5 + 1
playback_marker_width = 8
playback_marker_height = 64
sprite_data_playback_marker:
    @black_color = 1 ; using black at palette position 33 in 4bpp mode, palette offset 2
    @first_pixels = @black_color << 4
    @other_pixels = background_color
    .repeat playback_marker_height
        .byte @first_pixels, @other_pixels, @other_pixels, @other_pixels
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
    CURVE_UP_RIGHT @banner_color
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
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "velocity    "
    PADDED_TEXT @text_width, darker_text_color, " drag rmb on"
    PADDED_TEXT @text_width, darker_text_color, "    selected"
    PADDED_TEXT @text_width, darker_text_color, "        note"

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
    PADDED_TEXT @text_width, darker_text_color, "envelope 1's"
    PADDED_TEXT @text_width, darker_text_color, "release time"
    PADDED_TEXT @text_width, darker_text_color, "defines note"
    PADDED_TEXT @text_width, darker_text_color, "     length."
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, "the fm voice"
    PADDED_TEXT @text_width, darker_text_color, "is only used"
    PADDED_TEXT @text_width, darker_text_color, "if min. 1 op"
    PADDED_TEXT @text_width, darker_text_color, "is active."
    PADDED_TEXT @text_width, darker_text_color, ""
    PADDED_TEXT @text_width, darker_text_color, "vibrato uses"
    PADDED_TEXT @text_width, darker_text_color, "the software"
    PADDED_TEXT @text_width, darker_text_color, "lfo."

change_tempo_hint:
    @text_width = 19
    PADDED_TEXT @text_width, orange_text_color, "      caution      "
    PADDED_TEXT @text_width, normal_text_color, ""
    PADDED_TEXT @text_width, normal_text_color, "changing song tempo"
    PADDED_TEXT @text_width, normal_text_color, "can be lossy for   "
    PADDED_TEXT @text_width, normal_text_color, "sub-1/32 precise   "
    PADDED_TEXT @text_width, normal_text_color, "timings.           "
    PADDED_TEXT @text_width, normal_text_color, "maximum song length"
    PADDED_TEXT @text_width, normal_text_color, "is 8:36 min.       "

about_text:
    @text_width = 36
    PADDED_TEXT @text_width, white_text_color , "  concerto multitrack 0.8.0 (beta)  "
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, normal_text_color, "   by carl biermann  (kliepatsch)   "
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, white_text_color , "praise the lord by blowing trumpets."
    PADDED_TEXT @text_width, white_text_color , "praise him with harps and lyres.    "
    PADDED_TEXT @text_width, white_text_color , "praise him with tambourines         "
    PADDED_TEXT @text_width, normal_text_color, "               and dancing.         "
    PADDED_TEXT @text_width, white_text_color , "praise him with stringed instruments"
    PADDED_TEXT @text_width, normal_text_color, "               and flutes.          "
    PADDED_TEXT @text_width, white_text_color , "let everything that has breath      "
    PADDED_TEXT @text_width, normal_text_color, "               praise the lord.     "
    PADDED_TEXT @text_width, normal_text_color, "                    - from psalm 150"
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, white_text_color , "god says: i made the earth and      "
    PADDED_TEXT @text_width, normal_text_color, "               created man on it;   "
    PADDED_TEXT @text_width, white_text_color , "it was my hands that stretched out  "
    PADDED_TEXT @text_width, normal_text_color, "               the heavens,         "
    PADDED_TEXT @text_width, white_text_color , "and i commanded all their host.     "
    PADDED_TEXT @text_width, normal_text_color, "                    - from isaiah 45"
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, normal_text_color, "                                    "
    PADDED_TEXT @text_width, white_text_color , "seek the lord while he may be found;"
    PADDED_TEXT @text_width, normal_text_color, "       call on him while he is near."
    PADDED_TEXT @text_width, white_text_color , "let the wicked forsake their ways   "
    PADDED_TEXT @text_width, normal_text_color, " and the unrighteous their thoughts."
    PADDED_TEXT @text_width, white_text_color , "let them turn to the lord,          "
    PADDED_TEXT @text_width, normal_text_color, "     and he will have mercy on them,"
    PADDED_TEXT @text_width, normal_text_color, "and to our god,"
    PADDED_TEXT @text_width, white_text_color , "     for he will freely pardon."
    PADDED_TEXT @text_width, normal_text_color, "                    - from isaiah 55"



; From Psalm 150, NIRV
; praise the lord by blowing trumpets.
; praise him with harps and lyres.
; praise him with tambourines and dancing.
; praise him with stringed instruments and flutes.
; let everything that has breath praise the lord.


; Isaiah 45,12 ESV
; god says: i made the earth and created man on it; it was my hands that stretched out the heavens, and i commanded all their host.


; Isaiah 55,6-7 NIV
; seek the Lord while he may be found; call on him while he is near.
; let the wicked forsake their ways and the unrighteous their thoughts. 
; let them turn to the Lord, and he will have mercy on them, and to our god, for he will freely pardon.


.endscope

.popseg
