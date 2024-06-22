; Copyright 2024 Carl Georg Biermann

.pushseg
.segment "VRAM1LOADADDR"
.import __VRAM1ASSETS_START__
.word __VRAM1ASSETS_START__ ; load address, first two bytes in the file

.segment "VRAM1ASSETS"

.scope vram_assets

background_color = 0


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


.endscope

.popseg
